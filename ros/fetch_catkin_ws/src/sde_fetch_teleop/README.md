# sde_fetch_teleop

The `sde_fetch_teleop` package provides the launch files and node for end effector teleoperation of a Fetch robot.

- Maintainer: Lotfi El Hafi ([lotfi@coarobo.com](mailto:lotfi@coarobo.com)).
- Author: Lotfi El Hafi ([lotfi@coarobo.com](mailto:lotfi@coarobo.com)).
- License: [MIT](LICENSE).

## Overview

The Fetch has a native Cartesian twist controller (`robot_controllers/CartesianTwistController`). This package provides a thin relay node that:

1. Subscribes to an end effector velocity command `geometry_msgs/TwistStamped` on `fetch_ee_cmd_vel`, for example published by the Coarobo Sightline OpenXR application.
2. Clamps the command to safe linear and angular velocity limits.
3. Republishes it at a fixed rate (at least 20 Hz) to `arm_controller/cartesian_twist/command`, sending zeros when the input goes stale so the arm holds its pose instead of drifting.

The relay starts in velocity control by default, so teleoperation is live as soon as the launch file runs and the user does not need to switch controllers.

`fetch_teleop.launch` is the main entry point. It includes `fetch_teleop_sightline.launch`, which starts the relay node `fetch_cartesian_twist_control.py` and any other ROS nodes the Coarobo Sightline application needs on the Fetch platform.

The origin of this node is the Fetch-era `fetch_servoing` package (author: Gustavo Garcia), ported into the SDE.

## Full Teleop Stack

```shell
roslaunch sde_fetch_teleop fetch_teleop.launch
```

This is the main entry point for teleoperation. It starts the relay already in velocity control. Publish `geometry_msgs/TwistStamped` end effector velocity commands on `fetch_ee_cmd_vel` and the Fetch arm end effector moves accordingly.

Parameters:

- `input_twist_topic`: Input end effector twist command. Defaults to `fetch_ee_cmd_vel`.
- `command_out_topic`: Output topic consumed by the Fetch Cartesian twist controller. Defaults to `/arm_controller/cartesian_twist/command`.
- `start_in_velocity_control`: If `true`, teleoperation is live on launch with no manual switch. Defaults to `true`.
- `send_period`: Steady send period in seconds. Fetch needs a continuous stream or the arm can fall. Defaults to `0.050`.
- `max_linear_velocity`: Maximum linear velocity in m/s. Keep it small for safety. Defaults to `0.05`.
- `max_angular_velocity`: Maximum angular velocity in rad/s. Keep it small for safety. Defaults to `0.10`.

## Coarobo Sightline Nodes

Run the Coarobo Sightline teleop nodes on their own:

```shell
roslaunch sde_fetch_teleop fetch_teleop_sightline.launch
```

This starts `fetch_cartesian_twist_control.py`, which relays the clamped end effector twist stream to the Fetch Cartesian twist controller. It accepts the same parameters as the full stack.

## Controller Switching

The service `fetch_switch_controllers` toggles the internal forwarding state. It is not required for normal teleoperation because the node starts in velocity control.

Disable forwarding and hold the current arm position:

```shell
rosservice call /fetch_switch_controllers "fetch_controller_name: 'position_control'"
```

Re-enable forwarding of end effector velocity commands:

```shell
rosservice call /fetch_switch_controllers "fetch_controller_name: 'velocity_control'"
```

## Runtime Prerequisites

This package does not launch the robot driver, controllers, or MoveIt. Before launching the teleoperation node, make sure the rest of the Fetch stack is available in your ROS graph:

- A running Fetch (real robot or Gazebo simulation) publishing `/joint_states` and accepting the `arm_controller/cartesian_twist/command` topic.
- The `robot_controllers/CartesianTwistController` available under `arm_controller/cartesian_twist`. On the real robot this is part of the onboard controller configuration. In the SDE Gazebo simulation it is added by the patch `patches/ros/fetch_catkin_ws/src/fetch_gazebo/0001-add-cartesian-twist-controller.patch`.

## Simulation Note

The Cartesian twist controller is not part of the default Fetch Gazebo controller set. The SDE patch defines it under `arm_controller` and adds it to the Gazebo controller load list so the controller manager instantiates it. The controller stays stopped until `arm_controller/cartesian_twist/command` receives its first message, then it starts and preempts the arm trajectory controller for the duration of teleoperation.
