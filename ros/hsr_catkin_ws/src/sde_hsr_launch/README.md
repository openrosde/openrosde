# sde_hsr_launch

The `sde_hsr_launch` package provides launch files for the Toyota HSR (Human Support Robot) platform.

- Maintainer: Lotfi El Hafi ([lotfi@coarobo.com](mailto:lotfi@coarobo.com)).
- Author: Lotfi El Hafi ([lotfi@coarobo.com](mailto:lotfi@coarobo.com)).

## Distribution Model

The HSR platform image in the SDE is built as a multi-stage Docker image whose first stage is the publicly distributed Toyota binary image `ghcr.io/hsr-project/tmc_wrs_binary:noetic-latest` (BSD 3-Clause Clear).
The full HSR ROS Noetic stack (URDF, SRDF, MoveIt, navigation, controllers, all `hsrb_*` and `tmc_*` packages, and the WRS apartment world) is COPY-merged into the SDE base and sourced at container start via `/opt/wrs/setup.sh`.
The launch files in this package are thin wrappers around the upstream Toyota launch files, integrated with the SDE conventions (window maximization, Terminator layouts, FlexBE).

## Gazebo Simulation

The Gazebo simulation wrappers in this package are:

- `hsr_bringup_default_gazebo.launch`
- `hsr_rviz_default.launch`

Recommended startup order:

```shell
roslaunch sde_hsr_launch hsr_bringup_default_gazebo.launch
roslaunch sde_hsr_launch hsr_rviz_default.launch
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
| `hsr_bringup_default_gazebo.launch` | Wraps `tmc_wrs_gazebo_launch/wrs_practice0.launch` (URDF + controllers + MoveIt + navigation in WRS 2020 apartment world). |
| `hsr_bringup_default_realworld.launch` | Placeholder (no public Noetic real robot driver). |
| `hsr_rviz_default.launch` | RViz with the upstream `hsrb_rosnav_config/launch/hsrb.rviz` layout. |
| `hsr_moveit_default.launch` | Empty (MoveIt is started by the bringup). |
| `hsr_navigation_default_gazebo.launch` | Empty (navigation is started by the bringup). |
| `hsr_mapping_default.launch` | Placeholder (the WRS apartment world ships with a pre-built map). |

## FlexBE Behavior

To start the FlexBE behavior engine and app:

```shell
roslaunch sde_launch flexbe_app_default.launch
```

Load the `Hsr Example Behavior` behavior in the FlexBE App and press **Start**.
