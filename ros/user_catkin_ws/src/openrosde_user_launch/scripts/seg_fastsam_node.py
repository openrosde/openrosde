#!/usr/bin/env python3

import sys
import threading

import cv2
import numpy as np
import rospy
from cv_bridge import CvBridge
from sensor_msgs.msg import CompressedImage, Image


def load_fastsam_model(weights_path, device):
    """Load an Ultralytics FastSAM model (single-shot, class-agnostic 'segment everything').

    Kept free of ROS so it can be exercised standalone (e.g. from a Python REPL) without a roscore.
    Returns the model and the device it was actually loaded on (may differ from 'device' if CUDA
    was requested but is unavailable).
    """
    import torch
    from ultralytics import FastSAM

    if device == "cuda" and not torch.cuda.is_available():
        rospy.logerr(
            "~device is 'cuda' but no CUDA device is available in this container. "
            "Falling back to CPU -- inference will be much slower."
        )
        device = "cpu"

    model = FastSAM(weights_path)
    model.to(device)
    return model, device


def generate_fastsam_masks(model, image_bgr, device, imgsz, conf, iou):
    """Run FastSAM in 'segment everything' mode. Expects BGR input (OpenCV convention).

    'retina_masks=True' upsamples masks back to the original image resolution -- without it,
    masks stay at the model's internal (smaller) resolution and cannot be indexed directly
    against 'image_bgr'.
    """
    results = model(image_bgr, device=device, imgsz=imgsz, conf=conf, iou=iou, retina_masks=True, verbose=False)
    if results[0].masks is None:
        return []
    return [mask.astype(bool) for mask in results[0].masks.data.cpu().numpy()]


class MaskTracker:
    """Assigns a stable color per physical object across independent per-frame detections.

    FastSAM re-detects everything from scratch every frame, so a naive per-index random color
    flickers even when the same object is visible in consecutive frames. This matches each new
    mask to the most overlapping (by IoU) mask from the previous frames and reuses its color,
    so an object keeps its color as long as it keeps getting detected in roughly the same place.
    """

    # Masks are downsampled to this size before IoU matching. Matching only needs to tell "roughly
    # the same object" apart, not pixel-exact overlap, and comparing at full camera resolution
    # (e.g. 480x640) turned out to cost more CPU per frame than FastSAM's own inference -- with
    # ~30 detections a frame that's up to ~30x30 full-resolution comparisons, undoing the whole
    # point of using FastSAM. 80x60 keeps object shapes recognizable at a fraction of the cost.
    _MATCH_SIZE = (80, 60)

    def __init__(self, iou_threshold=0.3, max_missed_frames=5):
        self._iou_threshold = iou_threshold
        self._max_missed_frames = max_missed_frames
        self._tracks = {}  # track_id -> {"mask": downsampled bool array, "color": (b,g,r), "missed": int}
        self._next_id = 0
        self._rng = np.random.default_rng(0)

    def update(self, masks):
        """Return one BGR color tuple per mask in 'masks', stable across calls for matching masks."""
        colors = [None] * len(masks)
        matched_track_ids = set()
        small_masks = [self._downsample(mask) for mask in masks]

        # Greedy best-IoU matching against existing tracks (mask counts are small, so O(n*m) is fine
        # once each comparison is cheap).
        order = sorted(range(len(masks)), key=lambda i: masks[i].sum(), reverse=True)
        for i in order:
            best_id, best_iou = None, self._iou_threshold
            for track_id, track in self._tracks.items():
                if track_id in matched_track_ids:
                    continue
                iou = self._iou(small_masks[i], track["mask"])
                if iou > best_iou:
                    best_id, best_iou = track_id, iou

            if best_id is None:
                best_id = self._next_id
                self._next_id += 1
                self._tracks[best_id] = {"color": self._random_color()}

            self._tracks[best_id]["mask"] = small_masks[i]
            self._tracks[best_id]["missed"] = 0
            colors[i] = self._tracks[best_id]["color"]
            matched_track_ids.add(best_id)

        # Age out tracks that were not matched this frame; drop them once missed too many in a row.
        for track_id in list(self._tracks):
            if track_id in matched_track_ids:
                continue
            self._tracks[track_id]["missed"] = self._tracks[track_id].get("missed", 0) + 1
            if self._tracks[track_id]["missed"] > self._max_missed_frames:
                del self._tracks[track_id]

        return colors

    def _random_color(self):
        return tuple(int(c) for c in self._rng.integers(0, 255, size=3))

    @classmethod
    def _downsample(cls, mask):
        return cv2.resize(mask.astype(np.uint8), cls._MATCH_SIZE, interpolation=cv2.INTER_NEAREST).astype(bool)

    @staticmethod
    def _iou(mask_a, mask_b):
        intersection = np.logical_and(mask_a, mask_b).sum()
        if intersection == 0:
            return 0.0
        union = np.logical_or(mask_a, mask_b).sum()
        return intersection / union


def overlay_masks(image_bgr, masks, colors):
    """Blend each boolean mask (list of 2D arrays) onto 'image_bgr' with its assigned color."""
    if not masks:
        return image_bgr

    color_layer = image_bgr.copy()
    for mask, color in sorted(zip(masks, colors), key=lambda pair: pair[0].sum(), reverse=True):
        color_layer[mask] = color
    return cv2.addWeighted(color_layer, 0.5, image_bgr, 0.5, 0)


class SegFastSamNode:

    def __init__(self):
        self._passthrough = rospy.get_param("~passthrough", False)
        self._bridge = CvBridge()
        self._lock = threading.Lock()
        self._latest_msg = None
        self._model = None
        self._device = None
        self._imgsz = None
        self._conf = None
        self._iou = None
        self._tracker = None

        if not self._passthrough:
            weights = rospy.get_param("~weights", "")
            device = rospy.get_param("~device", "cuda")
            self._imgsz = rospy.get_param("~imgsz", 640)
            self._conf = rospy.get_param("~conf", 0.4)
            self._iou = rospy.get_param("~iou", 0.9)
            track_iou_threshold = rospy.get_param("~track_iou_threshold", 0.3)
            track_max_missed_frames = rospy.get_param("~track_max_missed_frames", 5)
            self._tracker = MaskTracker(track_iou_threshold, track_max_missed_frames)

            if not weights:
                rospy.logfatal("~weights is required when ~passthrough is false (no FastSAM weights path given).")
                sys.exit(1)

            rospy.loginfo("Loading FastSAM from '%s' on device '%s'...", weights, device)
            self._model, self._device = load_fastsam_model(weights, device)
            rospy.loginfo("FastSAM loaded on device '%s'.", self._device)

            rospy.loginfo("Warming up with a dummy 640x480 image...")
            dummy_image = np.random.default_rng(0).integers(0, 255, size=(480, 640, 3), dtype=np.uint8)
            generate_fastsam_masks(self._model, dummy_image, self._device, self._imgsz, self._conf, self._iou)
            rospy.loginfo("Warm-up complete.")

        input_topic = rospy.get_param("~input_topic", "/camera/color/image_raw")
        output_topic = rospy.get_param("~output_topic", "/segmentation/mask")
        rate_hz = rospy.get_param("~rate_hz", 5.0)
        # A JPEG copy on '<output_topic>/compressed' keeps the overlay light enough for Coarobo Viewport over rosbridge.
        self._publish_compressed = rospy.get_param("~publish_compressed", False)
        self._jpeg_quality = int(rospy.get_param("~jpeg_quality", 80))

        self._pub = rospy.Publisher(output_topic, Image, queue_size=1)
        self._compressed_pub = None
        if self._publish_compressed:
            self._compressed_pub = rospy.Publisher(output_topic + "/compressed", CompressedImage, queue_size=1)
        self._sub = rospy.Subscriber(input_topic, Image, self._image_callback, queue_size=1)
        self._timer = rospy.Timer(rospy.Duration(1.0 / rate_hz), self._timer_callback)

        rospy.loginfo(
            "seg_fastsam_node ready: '%s' -> '%s' at %.1f Hz (passthrough=%s).",
            input_topic, output_topic, rate_hz, self._passthrough,
        )

    def _image_callback(self, msg):
        # Keep only the latest frame; inference happens on the timer, not here.
        with self._lock:
            self._latest_msg = msg

    def _timer_callback(self, _event):
        with self._lock:
            msg = self._latest_msg
            self._latest_msg = None

        if msg is None:
            return

        # Skip inference while nobody watches the overlay, so idle cameras leave the GPU to the others.
        has_raw_subscribers = self._pub.get_num_connections() > 0
        has_compressed_subscribers = self._compressed_pub is not None and self._compressed_pub.get_num_connections() > 0
        if not has_raw_subscribers and not has_compressed_subscribers:
            return

        try:
            image_bgr = self._bridge.imgmsg_to_cv2(msg, desired_encoding="bgr8")

            if self._passthrough:
                out_bgr = image_bgr
            else:
                masks = generate_fastsam_masks(self._model, image_bgr, self._device, self._imgsz, self._conf, self._iou)
                colors = self._tracker.update(masks)
                out_bgr = overlay_masks(image_bgr, masks, colors)

            if has_raw_subscribers:
                out_msg = self._bridge.cv2_to_imgmsg(out_bgr, encoding="bgr8")
                out_msg.header = msg.header
                self._pub.publish(out_msg)

            if has_compressed_subscribers:
                ok, jpeg = cv2.imencode(".jpg", out_bgr, [int(cv2.IMWRITE_JPEG_QUALITY), self._jpeg_quality])
                if ok:
                    compressed_msg = CompressedImage()
                    compressed_msg.header = msg.header
                    compressed_msg.format = "bgr8; jpeg compressed bgr8"
                    compressed_msg.data = jpeg.tobytes()
                    self._compressed_pub.publish(compressed_msg)
        except Exception:
            # A single bad frame or transient inference error must not permanently kill this rospy.Timer thread.
            rospy.logerr("seg_fastsam_node: failed to process a frame.", exc_info=True)


def main():
    rospy.init_node("seg_fastsam_node")
    SegFastSamNode()
    rospy.spin()


if __name__ == "__main__":
    main()
