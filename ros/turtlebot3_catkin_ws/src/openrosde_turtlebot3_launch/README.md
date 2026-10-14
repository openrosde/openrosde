# openrosde_turtlebot3_launch

The `openrosde_turtlebot3_launch` package provides launch files for the Robotis TurtleBot3 platform.

- Maintainer: Lotfi El Hafi ([lotfi@coarobo.com](mailto:lotfi@coarobo.com)).
- Author: Lotfi El Hafi ([lotfi@coarobo.com](mailto:lotfi@coarobo.com)).

## Gazebo Simulation

Recommended startup order:

```shell
roslaunch openrosde_turtlebot3_launch turtlebot3_bringup_default_gazebo.launch
roslaunch openrosde_turtlebot3_launch turtlebot3_rviz_default_gazebo.launch
roslaunch openrosde_turtlebot3_launch turtlebot3_navigation_default_gazebo.launch
```

To start the same Gazebo stack in the predefined Terminator layout:

```shell
bash ./RUN-TERMINATOR-TERMINAL.bash #[docker-project] default-gazebo
```

## Real Robot

Bring up the Robotis TurtleBot3 robot from the Ubuntu development machine:

```shell
bash ./BRINGUP-ROS-ROBOT.bash <rosmaster-hostname> #[docker-project]
```

Then launch RViz and the mapping stack:

```shell
roslaunch openrosde_turtlebot3_launch turtlebot3_rviz_default_realworld.launch
roslaunch openrosde_turtlebot3_launch turtlebot3_mapping_default.launch
```

To start the same real robot stack in the predefined Terminator layout:

```shell
bash ./RUN-TERMINATOR-TERMINAL.bash #[docker-project] default-realworld
```

## Launch Files

| Launch File | Description |
| --- | --- |
| `turtlebot3_bringup_default_gazebo.launch` | Robotis TurtleBot3 Gazebo simulation |
| `turtlebot3_navigation_default_gazebo.launch` | Navigation stack (Gazebo) |
| `turtlebot3_mapping_default.launch` | SLAM mapping (gmapping) |
| `turtlebot3_rviz_default_gazebo.launch` | RViz visualization (Gazebo) |
| `turtlebot3_rviz_default_realworld.launch` | RViz visualization (real robot) |

## FlexBE Behavior

To start the FlexBE behavior engine and app:

```shell
roslaunch openrosde_launch flexbe_app_default.launch
```

Load the `TurtleBot3 Example Behavior` behavior in the FlexBE App and press **Start**.
