# sde_fetch_launch

The `sde_fetch_launch` package provides launch files for the Fetch Robotics Fetch platform.

- Maintainer: Lotfi El Hafi ([lotfi@coarobo.com](mailto:lotfi@coarobo.com)).
- Author: Lotfi El Hafi ([lotfi@coarobo.com](mailto:lotfi@coarobo.com)).

## Gazebo Simulation

The Gazebo simulation wrappers in this package are:

- `fetch_bringup_default_gazebo.launch`
- `fetch_navigation_default_gazebo.launch`
- `fetch_moveit_default.launch`
- `fetch_rviz_default_gazebo.launch`

Recommended startup order:

```shell
roslaunch sde_fetch_launch fetch_bringup_default_gazebo.launch
roslaunch sde_fetch_launch fetch_navigation_default_gazebo.launch
roslaunch sde_fetch_launch fetch_moveit_default.launch
roslaunch sde_fetch_launch fetch_rviz_default_gazebo.launch
```

To start the same Gazebo stack in the predefined Terminator layout:

```shell
bash ./RUN-TERMINATOR-TERMINAL.bash #[docker-project] default-gazebo
```

## Real Robot

Recommended startup order:

```shell
roslaunch sde_fetch_launch fetch_bringup_default_realworld.launch
roslaunch sde_fetch_launch fetch_mapping_default.launch
roslaunch sde_fetch_launch fetch_moveit_default.launch
```

To start the same real robot stack in the predefined Terminator layout:

```shell
bash ./RUN-TERMINATOR-TERMINAL.bash #[docker-project] default-realworld
```

## Launch Files

| Launch File | Description |
| --- | --- |
| `fetch_bringup_default_gazebo.launch` | Fetch Robotics Fetch Gazebo simulation |
| `fetch_bringup_default_realworld.launch` | Fetch Robotics Fetch real robot bringup |
| `fetch_navigation_default_gazebo.launch` | Navigation stack (Gazebo) |
| `fetch_mapping_default.launch` | SLAM mapping (build_map) |
| `fetch_moveit_default.launch` | MoveIt motion planning |
| `fetch_rviz_default_gazebo.launch` | RViz visualization (Gazebo) |
| `fetch_rviz_default_realworld.launch` | RViz visualization (real robot) |
