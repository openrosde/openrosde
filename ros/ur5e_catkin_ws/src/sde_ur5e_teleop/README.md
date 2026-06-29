# sde_ur5e_teleop

The `sde_ur5e_teleop` package provides the launch files and nodes for teleoperating a Universal Robots UR5e through MoveIt Servo, with two interchangeable input sources: a 3Dconnexion SpaceMouse (via the `spacenav_node` driver) and the Coarobo Viewport panel.
Both inputs drive the same MoveIt Servo command topic, and an OnRobot RG2 gripper can be toggled from the SpaceMouse.

- Maintainer: Lotfi El Hafi ([lotfi@coarobo.com](mailto:lotfi@coarobo.com)).
- Author: Lotfi El Hafi ([lotfi@coarobo.com](mailto:lotfi@coarobo.com)).
- License: [MIT](LICENSE).

## Overview

`ur5e_teleop.launch` is the main entry point.
It starts MoveIt Servo, performs the controller switch based on `controller_mode`, and starts exactly one input bridge selected by the `input_source` argument.
The two input sources are mirrored: each has its own launch file and `moveit_servo` bridge node that converts its input into a `geometry_msgs/TwistStamped` on the shared Servo command topic `/servo_server/delta_twist_cmds`.
Because only one input bridge runs at a time, the SpaceMouse and Viewport inputs never contend for that topic.

| Property | SpaceMouse (`spacenav_node`) | Coarobo Viewport |
| --- | --- | --- |
| Selector | `input_source:=spacemouse` | `input_source:=viewport` |
| Input launch | `ur5e_teleop_spacenav_node.launch` | `ur5e_teleop_viewport.launch` |
| Bridge node | `ur5e_moveit_servo_spacenav_node.py` | `ur5e_moveit_servo_viewport.py` |
| Input topic | `/spacenav/twist` (and `/spacenav/joy`) | `/cmd_vel` |
| Smoothing | deadband, low-pass filter, slew-rate limit | exponential moving average |
| Extras | OnRobot RG2 gripper button, `spacenavd` daemon, `spacenav_node` driver | connects over `rosbridge` |

## Full Teleop Stack

```shell
roslaunch sde_ur5e_teleop ur5e_teleop.launch
```

This is the main entry point for teleoperation.
It starts MoveIt Servo, starts the input bridge selected by `input_source`, and performs the controller switch automatically based on `controller_mode`.
By default it starts in trajectory mode.
Velocity mode is still experimental.

Parameters:

- `input_source`: Selects the teleop input. Use `spacemouse` (3Dconnexion SpaceMouse) or `viewport` (Coarobo Viewport panel). Defaults to `spacemouse`. Exactly one input bridge is started, so the two never contend for the shared Servo command topic. The `spacenavd` daemon and `spacenav_node` driver are only started for `spacemouse`.
- `start_spacenavd`: If `true`, starts the `spacenavd` daemon before launching the SpaceMouse stack. Only applies when `input_source:=spacemouse`. Defaults to `true`.
- `controller_mode`: Selects the UR controller path. Use `velocity` or `trajectory`. Defaults to `trajectory`.
- `reverse_for_front_view`: If `true`, flips `linear_x`, `linear_y`, `angular_x`, and `angular_y` so front-of-robot operation feels natural. Defaults to `false`.

## SpaceMouse Input (`spacenav_node`)

Run the SpaceMouse input stack on its own:

```shell
roslaunch sde_ur5e_teleop ur5e_teleop_spacenav_node.launch
```

This launch file starts:

- The 3Dconnexion SpaceMouse-to-Servo bridge node `ur5e_moveit_servo_spacenav_node.py`.
- The OnRobot RG2 button bridge node `ur5e_onrobot_rg_control_spacenav_node.py` when `enable_gripper_button:=true`.
- The upstream `spacenav_node` driver when `launch_spacenav_node:=true`, started with `respawn` so it reconnects once `spacenavd` is ready.

The bridge subscribes to a `geometry_msgs/Twist` on `/spacenav/twist` and the button `sensor_msgs/Joy` on `/spacenav/joy`, applies a deadband, low-pass smoothing, and slew-rate limiting, and republishes a `geometry_msgs/TwistStamped` on `/servo_server/delta_twist_cmds`.

If `spacenav_node` is already running elsewhere, disable the local driver:

```shell
roslaunch sde_ur5e_teleop ur5e_teleop_spacenav_node.launch launch_spacenav_node:=false
```

Usage notes:

- `spacenavd` is started automatically by `ur5e_spacenavd_daemon.bash` (the launch starts it before MoveIt Servo so it is ready by the time the `spacenav_node` driver connects).
- Hold Button 0 as the deadman and move the SpaceMouse to send twist commands.
- Press Button 1 to toggle the OnRobot RG2 gripper when gripper control is enabled.
- Set `reverse_for_front_view:=true` (through `ur5e_teleop.launch`) when operating from in front of the robot; this flips the planar translational and tilt axes so the hand-to-robot mapping feels like the default behind-the-robot setup.

Parameters:

- `launch_spacenav_node`: If `true`, includes the upstream `spacenav_node` driver. Set to `false` if `spacenav_node` is already running elsewhere.
- `input_twist_topic`: Input topic from the 3Dconnexion SpaceMouse driver. Defaults to `/spacenav/twist`.
- `output_twist_topic`: Output topic for MoveIt Servo. Defaults to `/servo_server/delta_twist_cmds`.
- `joy_topic`: Joystick button topic from the 3Dconnexion SpaceMouse driver. Defaults to `/spacenav/joy`.
- `frame_id`: Frame attached to the outgoing `TwistStamped`. Defaults to `base_link`.
- `require_enable_button`: If `true`, only forwards commands while the configured button is pressed. Defaults to `true`.
- `enable_button_index`: Button index used as deadman switch. Defaults to `0`.
- `publish_zero_when_disabled`: If `true`, publishes a zero twist when the deadman button is released. Defaults to `true`.
- `enable_gripper_button`: If `true`, starts the OnRobot RG2 button bridge node. Defaults to `true`.
- `gripper_button_index`: Button index used for the gripper toggle. Defaults to `1`.
- `gripper_service_name`: OnRobot RG2 command service. Defaults to `/onrobot_rg/set_command`.
- `gripper_open_command`: Service command for opening the gripper. Defaults to `o`.
- `gripper_close_command`: Service command for closing the gripper. Defaults to `c`.
- `gripper_initial_state`: Assumed initial gripper state for toggling logic. Defaults to `open`.
- `linear_x_scale`: Linear X scale factor. Defaults to `1.0`.
- `linear_y_scale`: Linear Y scale factor. Defaults to `1.0`.
- `linear_z_scale`: Linear Z scale factor. Defaults to `1.0`.
- `angular_x_scale`: Angular X scale factor. Defaults to `1.0`.
- `angular_y_scale`: Angular Y scale factor. Defaults to `1.0`.
- `angular_z_scale`: Angular Z scale factor. Defaults to `1.0`.
- `publish_rate`: Fixed publish rate of the filtered twist stream in Hz. Defaults to `100.0`.
- `input_timeout`: Time in seconds before stale 3Dconnexion SpaceMouse input is treated as zero. Defaults to `0.1`.
- `linear_deadband`: Center deadband applied to translational axes before scaling. Defaults to `0.10`.
- `angular_deadband`: Center deadband applied to rotational axes before scaling. Defaults to `0.10`.
- `linear_smoothing_time_constant`: First-order filter time constant for translational axes. Defaults to `0.08`.
- `angular_smoothing_time_constant`: First-order filter time constant for rotational axes. Defaults to `0.08`.
- `max_linear_acceleration`: Per-axis translational slew-rate limit. Defaults to `4.0`.
- `max_angular_acceleration`: Per-axis rotational slew-rate limit. Defaults to `6.0`.

The 3Dconnexion SpaceMouse bridge applies a deadband, low-pass smoothing, and slew-rate limiting before commands reach MoveIt Servo.
In velocity mode, those parameters are the primary jitter controls.
The Gazebo wrapper in `sde_ur5e_launch` keeps these same user-facing defaults so simulated teleop continues to feel like the real-world setup.

## Coarobo Viewport Input

Run the Viewport input bridge on its own:

```shell
roslaunch sde_ur5e_teleop ur5e_teleop_viewport.launch
```

This starts the bridge node `ur5e_moveit_servo_viewport.py`, which bridges the Coarobo Viewport panel to MoveIt Servo.
It subscribes to an unstamped `geometry_msgs/Twist` on `/cmd_vel`, applies per-axis exponential moving average smoothing, and republishes a `geometry_msgs/TwistStamped` on `/servo_server/delta_twist_cmds`.
When no input arrives within `input_timeout` seconds the target is treated as zero so the robot decelerates to a stop.

The Coarobo Viewport panel connects to ROS over `rosbridge`, so start a rosbridge server alongside the teleop stack.
`sde_launch:rosbridge_server_default.launch` is already part of the `default-realworld` Terminator layout.

Parameters:

- `input_twist_topic`: Input `geometry_msgs/Twist` topic from the Coarobo Viewport panel. Defaults to `/cmd_vel`.
- `output_twist_topic`: Output `geometry_msgs/TwistStamped` topic for MoveIt Servo. Defaults to `/servo_server/delta_twist_cmds`.
- `frame_id`: Frame attached to the outgoing `TwistStamped`. Defaults to `base_link`.
- `publish_rate`: Fixed publish rate of the smoothed twist stream in Hz. Defaults to `100.0`.
- `input_timeout`: Time in seconds before stale viewport input is treated as zero. Defaults to `0.2`.
- `smoothing_alpha`: Exponential moving average smoothing factor in the range `(0, 1]`. Lower values produce smoother motion and higher values respond faster. Defaults to `0.1`.

## MoveIt Servo

Both input bridges publish to MoveIt Servo, which `ur5e_teleop.launch` starts automatically.
It can also be launched on its own in either output mode.

### Velocity

```shell
roslaunch sde_ur5e_teleop ur5e_moveit_servo_velocity.launch
```

This starts `moveit_servo/servo_server` and loads the Servo parameters from `config/ur5e_moveit_servo_velocity.yaml`.
This launch publishes joint velocity commands as `std_msgs/Float64MultiArray` to `/joint_group_vel_controller/command`.
Velocity mode is still experimental.

Parameters:

- `planning_frame`: Defaults to `base_link`.
- `ee_frame_name`: Defaults to `flange`.
- `robot_link_command_frame`: Defaults to `flange`.
- `command_out_topic`: Defaults to `/joint_group_vel_controller/command`.
- `command_out_type`: Defaults to `std_msgs/Float64MultiArray`.
- `publish_joint_positions`: Defaults to `false`.
- `publish_joint_velocities`: Defaults to `true`.

### Trajectory

```shell
roslaunch sde_ur5e_teleop ur5e_moveit_servo_trajectory.launch
```

This keeps the older `trajectory_msgs/JointTrajectory` output path and publishes to `/scaled_pos_joint_traj_controller/command`.

### Servo Configuration

The Servo node is launched from `moveit_servo/servo_server` using separate mode-specific configs:

- `config/ur5e_moveit_servo_velocity.yaml` for true velocity control.
- `config/ur5e_moveit_servo_trajectory.yaml` for trajectory output.

Important defaults:

- `move_group_name`: `manipulator`.
- `planning_frame`: `base_link`.
- `ee_frame_name`: `flange`.
- `robot_link_command_frame`: `flange`.
- `cartesian_command_in_topic`: `/servo_server/delta_twist_cmds`.
- `command_out_type`: `std_msgs/Float64MultiArray`.
- `command_out_topic`: `/joint_group_vel_controller/command`.

Trajectory mode is the recommended default.
The velocity configuration remains experimental.

## Runtime Prerequisites

Before launching the teleoperation stack, make sure the rest of the robot stack is already available in your ROS graph:

- A running Universal Robots UR5e driver publishing robot state and accepting the controller type used by the selected teleop mode.
- A valid MoveIt configuration and planning scene for the robot.
- The OnRobot RG2 command service at `/onrobot_rg/set_command` if gripper toggling is enabled (SpaceMouse input).
- `spacenavd` running on the machine connected to the 3Dconnexion SpaceMouse (started automatically by `ur5e_spacenavd_daemon.bash`, SpaceMouse input).
- A `rosbridge` server reachable by the Coarobo Viewport panel (Viewport input).

This package does not launch the robot driver, controllers, MoveIt configuration, the OnRobot RG2 backend service, or the rosbridge server.

## Recommended Launch Sequence

1. Bring up the robot driver and controllers outside this package.
2. Ensure the MoveIt model for the robot is available.
3. Launch `ur5e_teleop.launch` from this package, choosing the input with `input_source:=spacemouse` (default) or `input_source:=viewport`.
4. For the SpaceMouse, the `spacenavd` daemon is started automatically; hold Button 0 as the deadman, move the SpaceMouse to send twist commands, and press Button 1 to toggle the OnRobot RG2 gripper.
5. For the Coarobo Viewport, start a rosbridge server and connect the panel.

The default `controller_mode` is `trajectory`.
Use `controller_mode:=velocity` only when you explicitly want the experimental velocity path.

If you want to launch components separately, start `ur5e_moveit_servo_velocity.launch` before `ur5e_teleop_spacenav_node.launch` for velocity mode.
For the older trajectory path, use `ur5e_moveit_servo_trajectory.launch` instead.

## Controller Switching

For true velocity control with the Universal Robots UR driver, MoveIt Servo must publish to `/joint_group_vel_controller/command` while the scaled position trajectory controller is stopped.
`ur5e_teleop.launch` performs that switch automatically based on `controller_mode`, but that velocity path is still experimental.

Start the velocity controller and stop the scaled position trajectory controller:

```shell
rosservice call /controller_manager/switch_controller "start_controllers: ['joint_group_vel_controller']
stop_controllers: ['scaled_pos_joint_traj_controller']
strictness: 2
start_asap: false
timeout: 5.0"
```

Switch back to the original trajectory-based teleop path:

```shell
rosservice call /controller_manager/switch_controller "start_controllers: ['scaled_pos_joint_traj_controller']
stop_controllers: ['joint_group_vel_controller']
strictness: 2
start_asap: false
timeout: 5.0"
```

If the Universal Robots UR driver was launched with its default controller list, `joint_group_vel_controller` is normally loaded in the stopped state and can be activated with the command above.
