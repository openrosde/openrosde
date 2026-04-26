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
