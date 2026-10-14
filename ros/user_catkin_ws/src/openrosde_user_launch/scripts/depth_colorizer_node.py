#!/usr/bin/env python3

"""Publish a colorized JPEG of a depth image for Coarobo Viewport.

A raw 16-bit depth image costs about 24 MB/s per camera at 30 Hz over rosbridge,
and Coarobo Viewport cannot decode 'compressedDepth'. This node colorizes the
depth between '~min_depth' and '~max_depth' meters (near in red, far in blue,
no reading in black) and publishes it as a JPEG 'sensor_msgs/CompressedImage'.
It subscribes to the depth image only while its output has a subscriber.
"""

import threading

import cv2
import numpy as np
import rospy
from cv_bridge import CvBridge
from sensor_msgs.msg import CompressedImage, Image


class DepthColorizerNode:
    def __init__(self):
        self._input_topic = rospy.get_param("~input_topic", "/camera/depth/image_rect_raw")
        output_topic = rospy.get_param("~output_topic", "/camera/viewport/depth_colorized/compressed")
        self._min_depth = rospy.get_param("~min_depth", 0.2)
        self._max_depth = rospy.get_param("~max_depth", 2.0)
        # Meters per unit of a '16UC1' depth image, which Intel RealSense publishes in millimeters.
        self._depth_scale = rospy.get_param("~depth_scale", 0.001)
        self._jpeg_quality = int(rospy.get_param("~jpeg_quality", 80))
        rate_hz = rospy.get_param("~rate_hz", 10.0)

        self._bridge = CvBridge()
        self._lock = threading.Lock()
        self._latest_msg = None
        self._sub = None
        self._pub = rospy.Publisher(output_topic, CompressedImage, queue_size=1)
        self._timer = rospy.Timer(rospy.Duration(1.0 / rate_hz), self._timer_callback)

        rospy.loginfo("depth_colorizer_node ready: '%s' -> '%s' at %.1f Hz.", self._input_topic, output_topic, rate_hz)

    def _image_callback(self, msg):
        with self._lock:
            self._latest_msg = msg

    def _update_subscription(self):
        # Receive the heavy depth stream only while somebody watches the colorized one.
        wanted = self._pub.get_num_connections() > 0
        if wanted and self._sub is None:
            self._sub = rospy.Subscriber(self._input_topic, Image, self._image_callback, queue_size=1, buff_size=2**24)
        elif not wanted and self._sub is not None:
            self._sub.unregister()
            self._sub = None
            with self._lock:
                self._latest_msg = None
        return wanted

    def _colorize(self, msg):
        depth = self._bridge.imgmsg_to_cv2(msg, desired_encoding="passthrough")
        if msg.encoding == "32FC1":
            meters = np.nan_to_num(depth.astype(np.float32))
        else:
            meters = depth.astype(np.float32) * self._depth_scale
        valid = meters > 0.0
        scaled = np.clip((meters - self._min_depth) / (self._max_depth - self._min_depth), 0.0, 1.0)
        # Near is red and far is blue on the turbo colormap.
        colored = cv2.applyColorMap(((1.0 - scaled) * 255.0).astype(np.uint8), cv2.COLORMAP_TURBO)
        colored[~valid] = 0
        return colored

    def _timer_callback(self, _event):
        if not self._update_subscription():
            return

        with self._lock:
            msg = self._latest_msg
            self._latest_msg = None
        if msg is None:
            return

        try:
            ok, jpeg = cv2.imencode(".jpg", self._colorize(msg), [int(cv2.IMWRITE_JPEG_QUALITY), self._jpeg_quality])
            if not ok:
                return
            out_msg = CompressedImage()
            out_msg.header = msg.header
            out_msg.format = "bgr8; jpeg compressed bgr8"
            out_msg.data = jpeg.tobytes()
            self._pub.publish(out_msg)
        except Exception:
            # A single bad frame must not kill the timer thread.
            rospy.logerr("depth_colorizer_node: failed to process a frame.", exc_info=True)


def main():
    rospy.init_node("depth_colorizer_node")
    DepthColorizerNode()
    rospy.spin()


if __name__ == "__main__":
    main()
