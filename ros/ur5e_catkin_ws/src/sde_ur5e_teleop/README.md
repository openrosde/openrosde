# sde_ur5e_teleop

The `sde_ur5e_teleop` package provides launch files and nodes for teleoperating a Universal Robots UR5e with a 3Dconnexion SpaceMouse and an OnRobot RG2 gripper.

- Maintainer: Lotfi El Hafi ([lotfi@coarobo.com](mailto:lotfi@coarobo.com)).
- Author: Lotfi El Hafi ([lotfi@coarobo.com](mailto:lotfi@coarobo.com)).
- License: [MIT](LICENSE).

## Launch Files

### Start Full Teleop Stack

```shell
roslaunch sde_ur5e_teleop ur5e_teleop.launch
```

This is the main entry point for teleoperation.
It starts the `spacenavd` daemon if not already running, starts MoveIt Servo, starts the 3Dconnexion SpaceMouse bridge, and performs the controller switch automatically based on `controller_mode`.
By default it starts in trajectory mode.
Velocity mode is still experimental.

### Start MoveIt Servo (Velocity)

```shell
roslaunch sde_ur5e_teleop ur5e_moveit_servo_velocity.launch
```

This starts `moveit_servo/servo_server` and loads the Servo parameters from `config/ur5e_moveit_servo_velocity.yaml`.
This launch publishes joint velocity commands as `std_msgs/Float64MultiArray` to `/joint_group_vel_controller/command`.
Velocity mode is still experimental.

### Start MoveIt Servo (Trajectory)

```shell
roslaunch sde_ur5e_teleop ur5e_moveit_servo_trajectory.launch
```

This keeps the older `trajectory_msgs/JointTrajectory` output path and publishes to `/scaled_pos_joint_traj_controller/command`.

### Start the SpaceMouse Bridge

```shell
roslaunch sde_ur5e_teleop ur5e_spacenav_node.launch
```

This launch file starts:

- The 3Dconnexion SpaceMouse-to-Servo bridge node `ur5e_spacenav_node_moveit_servo.py`.
- The OnRobot RG2 button bridge node `ur5e_spacenav_node_onrobot_rg_control.py` when `enable_gripper_button:=true`.
- `spacenav_node/classic.launch` when `launch_spacenav_node:=true`.

If `spacenav_node` is already running elsewhere, disable the local include:

```shell
roslaunch sde_ur5e_teleop ur5e_spacenav_node.launch launch_spacenav_node:=false
```

### Start the Viewport Teleop Bridge

```shell
roslaunch sde_ur5e_teleop ur5e_viewport_teleop.launch
```

This starts `ur5e_viewport_teleop_node.py`, which bridges the viewport teleop panel to MoveIt Servo.
It subscribes to an unstamped `geometry_msgs/Twist` on `/cmd_vel`, applies per-axis exponential moving average smoothing, and republishes a `geometry_msgs/TwistStamped` on `/servo_server/delta_twist_cmds`.
When no input arrives within `input_timeout` seconds the target is treated as zero so the robot decelerates to a stop.
This bridge is an alternative input to the SpaceMouse and publishes to the same Servo topic.
Do not run both inputs at the same time.

## Runtime Prerequisites

Before launching the teleoperation bridge, make sure the rest of the robot stack is already available in your ROS graph:

- A running Universal Robots UR5e driver publishing robot state and accepting the controller type used by the selected teleop mode.
- A valid MoveIt configuration and planning scene for the robot.
- The OnRobot RG2 command service at `/onrobot_rg/set_command` if gripper toggling is enabled.
- `spacenavd` running on the machine connected to the 3Dconnexion SpaceMouse (started automatically by `start-spacenavd-daemon.bash`).

This package does not launch the robot driver, controllers, MoveIt configuration, or the OnRobot RG2 backend service.

## Recommended Launch Sequence

1. Bring up the robot driver and controllers outside this package.
2. Ensure the MoveIt model for the robot is available.
3. The `spacenavd` daemon is started automatically by the launch file.
4. Launch `ur5e_teleop.launch` from this package.
5. Hold Button 0 as the deadman and move the 3Dconnexion SpaceMouse to send twist commands.
6. Press Button 1 to toggle the OnRobot RG2 gripper when gripper control is enabled.

The default `controller_mode` is `trajectory`.
Use `controller_mode:=velocity` only when you explicitly want the experimental velocity path.
Set `reverse_for_front_view:=true` when operating from in front of the robot.
This flips the planar translational and tilt axes so the hand-to-robot mapping feels like the default behind-the-robot setup.

If you want to launch components separately, start `ur5e_moveit_servo_velocity.launch` before `ur5e_spacenav_node.launch` for velocity mode.
For the older trajectory path, use `ur5e_moveit_servo_trajectory.launch` instead.

## Servo Configuration

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

## Launch Parameters

### `ur5e_moveit_servo_velocity.launch`

Experimental velocity-control launch.

- `planning_frame`: Defaults to `base_link`.
- `ee_frame_name`: Defaults to `flange`.
- `robot_link_command_frame`: Defaults to `flange`.
- `command_out_topic`: Defaults to `/joint_group_vel_controller/command`.
- `command_out_type`: Defaults to `std_msgs/Float64MultiArray`.
- `publish_joint_positions`: Defaults to `false`.
- `publish_joint_velocities`: Defaults to `true`.

### `ur5e_spacenav_node.launch`

- `launch_spacenav_node`: If `true`, includes `spacenav_node/classic.launch`.
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

### `ur5e_teleop.launch`

- `start_spacenavd`: If `true`, starts the `spacenavd` daemon before launching the teleop stack. Defaults to `true`.
- `controller_mode`: Selects the UR controller path. Use `velocity` or `trajectory`. Defaults to `trajectory`.
- `reverse_for_front_view`: If `true`, flips `linear_x`, `linear_y`, `angular_x`, and `angular_y` so front-of-robot operation feels natural. Defaults to `false`.
- `launch_viewport_teleop`: If `true`, also starts the viewport teleop bridge. Defaults to `false`. This bridge publishes to the same Servo topic as the SpaceMouse, so do not enable it together with the SpaceMouse input.

### `ur5e_viewport_teleop.launch`

- `input_twist_topic`: Input `geometry_msgs/Twist` topic from the viewport teleop panel. Defaults to `/cmd_vel`.
- `output_twist_topic`: Output `geometry_msgs/TwistStamped` topic for MoveIt Servo. Defaults to `/servo_server/delta_twist_cmds`.
- `frame_id`: Frame attached to the outgoing `TwistStamped`. Defaults to `base_link`.
- `publish_rate`: Fixed publish rate of the smoothed twist stream in Hz. Defaults to `100.0`.
- `input_timeout`: Time in seconds before stale viewport input is treated as zero. Defaults to `0.2`.
- `smoothing_alpha`: Exponential moving average smoothing factor in the range `(0, 1]`. Lower values produce smoother motion and higher values respond faster. Defaults to `0.1`.

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
