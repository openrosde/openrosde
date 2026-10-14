# openrosde_cobotta_launch

The `openrosde_cobotta_launch` package provides launch files for the Denso COBOTTA platform.

- Maintainer: Lotfi El Hafi ([lotfi@coarobo.com](mailto:lotfi@coarobo.com)).
- Author: Lotfi El Hafi ([lotfi@coarobo.com](mailto:lotfi@coarobo.com)).

## Gazebo Simulation

The Gazebo simulation wrappers in this package are:

- `cobotta_bringup_default_gazebo.launch`
- `cobotta_moveit_default_gazebo.launch`
- `cobotta_rviz_default.launch`

The parallel gripper (`gripper_type:=parallel`) is displayed in Gazebo and RViz by default.
The gripper is visual-only in simulation, as the `cobotta/gripper_action` server is only available on the real robot.

Recommended startup order:

```shell
roslaunch openrosde_cobotta_launch cobotta_bringup_default_gazebo.launch
roslaunch openrosde_cobotta_launch cobotta_moveit_default_gazebo.launch
roslaunch openrosde_cobotta_launch cobotta_rviz_default.launch
```

To start the same Gazebo stack in the predefined Terminator layout:

```shell
bash ./RUN-TERMINATOR-TERMINAL.bash #[docker-project] default-gazebo
```

## Real Robot

The real robot wrappers in this package are:

- `cobotta_bringup_default_realworld.launch`
- `cobotta_moveit_default_realworld.launch`
- `cobotta_rviz_default.launch`

The parallel gripper (`gripper_type:=parallel`) is used by default.
The gripper driver is started automatically by the bringup.

Recommended startup order:

```shell
roslaunch openrosde_cobotta_launch cobotta_bringup_default_realworld.launch
roslaunch openrosde_cobotta_launch cobotta_moveit_default_realworld.launch
roslaunch openrosde_cobotta_launch cobotta_rviz_default.launch
```

To start the same real robot stack in the predefined Terminator layout:

```shell
bash ./RUN-TERMINATOR-TERMINAL.bash #[docker-project] default-realworld
```

## Launch Files

| Launch File | Description |
| --- | --- |
| `cobotta_bringup_default_gazebo.launch` | Denso COBOTTA Gazebo simulation (without MoveIt and RViz) |
| `cobotta_bringup_default_realworld.launch` | Denso COBOTTA real robot driver and controllers (without MoveIt and RViz) |
| `cobotta_moveit_default_gazebo.launch` | MoveIt motion planning (Gazebo) |
| `cobotta_moveit_default_realworld.launch` | MoveIt motion planning (real robot) |
| `cobotta_rviz_default.launch` | RViz visualization (both Gazebo and real robot) |

## FlexBE Behavior

To start the FlexBE behavior engine and app:

```shell
roslaunch openrosde_launch flexbe_app_default.launch
```

Load the `COBOTTA Example Behavior` behavior in the FlexBE App and press **Start**.
