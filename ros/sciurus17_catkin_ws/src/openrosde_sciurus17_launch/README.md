# openrosde_sciurus17_launch

The `openrosde_sciurus17_launch` package provides launch files for the RT Sciurus17 platform.

- Maintainer: Lotfi El Hafi ([lotfi@coarobo.com](mailto:lotfi@coarobo.com)).
- Author: Lotfi El Hafi ([lotfi@coarobo.com](mailto:lotfi@coarobo.com)).

## Gazebo Simulation

The Gazebo simulation wrappers in this package are:

- `sciurus17_bringup_default_gazebo.launch`
- `sciurus17_moveit_default_gazebo.launch`
- `sciurus17_rviz_default.launch`

Recommended startup order:

```shell
roslaunch openrosde_sciurus17_launch sciurus17_bringup_default_gazebo.launch
roslaunch openrosde_sciurus17_launch sciurus17_moveit_default_gazebo.launch
roslaunch openrosde_sciurus17_launch sciurus17_rviz_default.launch
```

To start the same Gazebo stack in the predefined Terminator layout:

```shell
bash ./RUN-TERMINATOR-TERMINAL.bash #[docker-project] default-gazebo
```

## Real Robot

The real robot wrappers in this package are:

- `sciurus17_moveit_default_realworld.launch`
- `sciurus17_rviz_default.launch`

Recommended startup order:

```shell
roslaunch openrosde_sciurus17_launch sciurus17_moveit_default_realworld.launch
roslaunch openrosde_sciurus17_launch sciurus17_rviz_default.launch
```

To start the same real robot stack in the predefined Terminator layout:

```shell
bash ./RUN-TERMINATOR-TERMINAL.bash #[docker-project] default-realworld
```

## Launch Files

| Launch File | Description |
| --- | --- |
| `sciurus17_bringup_default_gazebo.launch` | RT Sciurus17 Gazebo simulation (without MoveIt and RViz) |
| `sciurus17_moveit_default_gazebo.launch` | MoveIt motion planning (Gazebo) |
| `sciurus17_moveit_default_realworld.launch` | MoveIt motion planning (real robot) |
| `sciurus17_rviz_default.launch` | RViz visualization (both Gazebo and real robot) |

## FlexBE Behavior

To start the FlexBE behavior engine and app:

```shell
roslaunch openrosde_launch flexbe_app_default.launch
```

Load the `Sciurus17 Example Behavior` behavior in the FlexBE App and press **Start**.
