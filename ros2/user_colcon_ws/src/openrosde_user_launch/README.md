# openrosde_user_launch

The `openrosde_user_launch` package is the user-overlay entry point for custom ROS 2 launch files, beside the package of the same name in `ros/user_catkin_ws/` for the platforms on ROS 1.
It is platform-agnostic: it builds and runs on top of any `OPENROSDE_ROBOT_PLATFORM` on ROS 2.

## Usage

Start the demo launch file:

```shell
ros2 launch openrosde_user_launch user_example_default.launch.xml
```

## Adding Your Own Launch Files

1. Drop your `.launch.xml` or `.launch.py` files into `launch/`.
2. List any new ROS package dependencies in `package.xml` as `<exec_depend>`.
3. Rebuild the workspace from inside the container, since a colcon workspace runs its launch files from its install space:

    ```shell
    openrosde-build-catkin-workspaces
    ```

## Adding Configuration Files

The `config/` directory mirrors the convention used by the platform launch packages:

- `config/rviz/`: drop your custom `.rviz` layouts here and reference them from your launch file as `$(find-pkg-share openrosde_user_launch)/config/rviz/<file>.rviz`.
- `config/maps/`: drop your custom maps (`.yaml` + `.pgm`) here and reference them as `$(find-pkg-share openrosde_user_launch)/config/maps/<file>.yaml`.

You can add other subdirectories under `config/` (e.g. `urdf/`, `worlds/`, `params/`) and list them in `install(DIRECTORY ...)` of `CMakeLists.txt`.
