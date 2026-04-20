# sde_sciurus17_launch

The `sde_sciurus17_launch` package provides launch files for the RT Sciurus17 platform.

- Maintainer: Lotfi El Hafi ([lotfi@coarobo.com](mailto:lotfi@coarobo.com)).
- Author: Lotfi El Hafi ([lotfi@coarobo.com](mailto:lotfi@coarobo.com)).

## Gazebo Simulation

The Gazebo simulation wrappers in this package are:

- `sciurus17_bringup_default_gazebo.launch`
- `sciurus17_moveit_default.launch`
- `sciurus17_rviz_default.launch`

Recommended startup order:

```shell
roslaunch sde_sciurus17_launch sciurus17_bringup_default_gazebo.launch
roslaunch sde_sciurus17_launch sciurus17_moveit_default.launch
roslaunch sde_sciurus17_launch sciurus17_rviz_default.launch
```

To start the same Gazebo stack in the predefined Terminator layout:

```shell
bash ./RUN-TERMINATOR-TERMINAL.bash #[docker-project] default-gazebo
```

## Real Robot

Recommended startup order:

```shell
roslaunch sde_sciurus17_launch sciurus17_moveit_default.launch
roslaunch sde_sciurus17_launch sciurus17_rviz_default.launch
```

To start the same real robot stack in the predefined Terminator layout:

```shell
bash ./RUN-TERMINATOR-TERMINAL.bash #[docker-project] default-realworld
```

## Launch Files

| Launch File | Description |
| --- | --- |
| `sciurus17_bringup_default_gazebo.launch` | RT Sciurus17 Gazebo simulation |
| `sciurus17_moveit_default.launch` | MoveIt motion planning |
| `sciurus17_rviz_default.launch` | RViz visualization (both Gazebo and real robot) |
