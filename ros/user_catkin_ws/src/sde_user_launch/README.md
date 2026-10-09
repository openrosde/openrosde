# sde_user_launch

The `sde_user_launch` package is the user-overlay entry point for custom ROS launch files.
It is platform-agnostic: it builds and runs on top of any `SDE_ROBOT_PLATFORM`.

## Usage

Start the demo launch file:

```shell
roslaunch sde_user_launch user_example_default.launch
```

## Adding Your Own Launch Files

1. Drop your `.launch` files into `launch/`.
2. List any new ROS package dependencies in `package.xml` as `<exec_depend>`.
3. Rebuild the workspace from inside the container:

    ```shell
    sde-build-catkin-workspaces
    ```

## Adding Configuration Files

The `config/` directory mirrors the convention used by the platform launch packages:

- `config/rviz/`: drop your custom `.rviz` layouts here and reference them from your launch file as `$(find sde_user_launch)/config/rviz/<file>.rviz`.
- `config/maps/`: drop your custom maps (`.yaml` + `.pgm`) here and reference them as `$(find sde_user_launch)/config/maps/<file>.yaml`.

You can add other subdirectories under `config/` (e.g. `urdf/`, `worlds/`, `params/`) following the same pattern.

## FastSAM Segmentation (Coarobo Demo)

`seg_fastsam.launch` runs `scripts/seg_fastsam_node.py`, which overlays the class-agnostic masks of [Ultralytics FastSAM](https://docs.ultralytics.com/models/fast-sam/) on a color image topic, with a stable color per object across frames.
It was written by Hajime Teruoka on the `add_segmentation` branch, and it lives in the user overlay for the ATR Open House 2026 demo until it moves to a package of its own.
`docker/user-devel/Dockerfile` installs PyTorch for CUDA 12.1 and `ultralytics` for it, and removes the `opencv-python` that `ultralytics` pulls in, since it breaks `cv_bridge`.

The weights are not part of the image or the repository.
Copy `FastSAM-x.pt` into the git-ignored `models/fastsam/` folder of this package, which the launch files use by default.

To run FastSAM on both Intel RealSense cameras of the UR5e, with a JPEG copy of each overlay for Coarobo Viewport:

```shell
roslaunch sde_user_launch seg_fastsam_ur5e_cameras.launch
```

The overlays come out on `/wrist_camera/fastsam/image_raw` and `/external_camera/fastsam/image_raw`, each with its JPEG copy on `<topic>/compressed`.
A camera whose overlay has no subscriber skips inference, so the GPU only serves the overlays in use.

## Light Streams for Coarobo Viewport (Coarobo Demo)

The raw depth images and point clouds of the cameras are far too heavy for Coarobo Viewport over rosbridge, so `viewport_streams_ur5e.launch` prepares light copies of them for both UR5e cameras:

- `/<camera>/viewport/depth_colorized/compressed`: a colorized JPEG of the depth from `scripts/depth_colorizer_node.py`, red when near and blue when far, at 10 Hz, received only while something subscribes.
- `/<camera>/viewport/points`: the colored point cloud throttled to 5 Hz and downsampled on a 2 cm voxel grid.
- `/<camera>/viewport/fastsam_points`: the FastSAM overlay projected on the depth aligned to color with `depth_image_proc`, downsampled on the same grid, which needs the cameras started with `align_depth:=true`.

The color images need nothing more, since `/<camera>/color/image_raw/compressed` is already a JPEG.
`viewport_demo_ur5e.launch` starts these streams together with FastSAM on both cameras:

```shell
roslaunch sde_user_launch viewport_demo_ur5e.launch
```

