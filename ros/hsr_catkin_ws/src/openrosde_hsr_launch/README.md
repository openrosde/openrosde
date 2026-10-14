# openrosde_hsr_launch

The `openrosde_hsr_launch` package provides launch files for the Toyota HSR (Human Support Robot) platform.

- Maintainer: Lotfi El Hafi ([lotfi@coarobo.com](mailto:lotfi@coarobo.com)).
- Author: Lotfi El Hafi ([lotfi@coarobo.com](mailto:lotfi@coarobo.com)).

## Distribution Model

The HSR platform image in OpenRoSDE is built as a multi-stage Docker image whose first stage is the publicly distributed Toyota binary image `ghcr.io/hsr-project/tmc_wrs_binary:noetic-latest` (BSD 3-Clause Clear).
The full HSR ROS Noetic stack (URDF, SRDF, MoveIt, navigation, controllers, all `hsrb_*` and `tmc_*` packages, and the WRS apartment world) is installed under `/opt/ros/noetic` inside the binary image and COPY-merged into the OpenRoSDE base.
Sourcing `/opt/ros/noetic/setup.bash` is sufficient to expose all HSR packages; no separate workspace overlay is required.
The launch files in this package are thin wrappers around the upstream Toyota launch files, integrated with the OpenRoSDE conventions (window maximization, Terminator layouts, FlexBE).

## Gazebo Simulation

The Gazebo simulation wrappers in this package are:

- `hsr_bringup_default_gazebo.launch`
- `hsr_navigation_default_gazebo.launch`
- `hsr_moveit_default.launch`
- `hsr_rviz_default.launch`

Recommended startup order:

```shell
roslaunch openrosde_hsr_launch hsr_bringup_default_gazebo.launch
roslaunch openrosde_hsr_launch hsr_navigation_default_gazebo.launch
roslaunch openrosde_hsr_launch hsr_moveit_default.launch
roslaunch openrosde_hsr_launch hsr_rviz_default.launch
```

To start the same Gazebo stack in the predefined Terminator layout:

```shell
bash ./RUN-TERMINATOR-TERMINAL.bash #[docker-project] default-gazebo
```

## Real Robot

Real robot bringup is not configured: Toyota's `tmc_wrs_binary` image only ships the simulation stack.
The real HSR driver is hosted on the private `git.hsr.io` GitLab and requires a Toyota HSR Community account.

## Launch Files

| Launch File | Description |
| --- | --- |
| `hsr_bringup_default_gazebo.launch` | Spawns the HSR in the WRS 2020 Gazebo world with open-source controllers (`use_oss_stacks=true`) and relays wheel odometry to `/hsrb/odom`. |
| `hsr_navigation_default_gazebo.launch` | Wraps `hsrb_rosnav_config/hsrb_nav.launch` (AMCL + `move_base`) with the WRS 2020 pre-built map. |
| `hsr_moveit_default.launch` | Wraps `hsrb_moveit_config/hsrb_demo_with_controller.launch` for arm motion planning. |
| `hsr_rviz_default.launch` | RViz with the OpenRoSDE-owned `config/rviz/hsr_rviz_default.rviz` layout. |

## FlexBE Behavior

To start the FlexBE behavior engine and app:

```shell
roslaunch openrosde_launch flexbe_app_default.launch
```

Load the `HSR Example Behavior` behavior in the FlexBE App and press **Start**.
