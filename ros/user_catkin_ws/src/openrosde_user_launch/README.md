# openrosde_user_launch

The `openrosde_user_launch` package is the user-overlay entry point for custom ROS launch files.
It is platform-agnostic: it builds and runs on top of any `OPENROSDE_ROBOT_PLATFORM`.

## Usage

Start the demo launch file:

```shell
roslaunch openrosde_user_launch user_example_default.launch
```

## Adding Your Own Launch Files

1. Drop your `.launch` files into `launch/`.
2. List any new ROS package dependencies in `package.xml` as `<exec_depend>`.
3. Rebuild the workspace from inside the container:

    ```shell
    openrosde-build-catkin-workspaces
    ```

## Adding Configuration Files

The `config/` directory mirrors the convention used by the platform launch packages:

- `config/rviz/`: drop your custom `.rviz` layouts here and reference them from your launch file as `$(find openrosde_user_launch)/config/rviz/<file>.rviz`.
- `config/maps/`: drop your custom maps (`.yaml` + `.pgm`) here and reference them as `$(find openrosde_user_launch)/config/maps/<file>.yaml`.

You can add other subdirectories under `config/` (e.g. `urdf/`, `worlds/`, `params/`) following the same pattern.
