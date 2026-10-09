# sde_ur5e_launch

The `sde_ur5e_launch` package provides launch files for the Universal Robots UR5e platform.

- Maintainer: Lotfi El Hafi ([lotfi@coarobo.com](mailto:lotfi@coarobo.com)).
- Author: Lotfi El Hafi ([lotfi@coarobo.com](mailto:lotfi@coarobo.com)).

## Gazebo Teleoperation

The Gazebo teleoperation wrappers in this package are:

- `ur5e_bringup_default_gazebo.launch`
- `ur5e_moveit_default_gazebo.launch`
- `ur5e_rviz_default.launch`
- `onrobot_rg_control_default_gazebo.launch`
- `ur5e_teleop_default_gazebo.launch`

Recommended startup order:

```shell
roslaunch sde_ur5e_launch ur5e_bringup_default_gazebo.launch
roslaunch sde_ur5e_launch ur5e_moveit_default_gazebo.launch
roslaunch sde_ur5e_launch ur5e_rviz_default.launch
roslaunch sde_ur5e_launch onrobot_rg_control_default_gazebo.launch
roslaunch sde_ur5e_launch ur5e_teleop_default_gazebo.launch
```

Notes:

- `ur5e_teleop_default_gazebo.launch` wraps the `sde_ur5e_teleop` teleop stack.
- `ur5e_bringup_default_gazebo.launch` spawns a Universal Robots UR5e model with the OnRobot RG2 gripper, the Intel RealSense D435i camera adapter, and the OnRobot Quick Changer in Gazebo.
- `ur5e_bringup_default_gazebo.launch` also loads the MoveIt SRDF and kinematics config so RViz works independently of `move_group`.
- The Gazebo teleop wrapper uses `flange` for the end-effector and operator command frame so the 3Dconnexion SpaceMouse feel stays aligned with the real-world teleop setup.
- The Gazebo teleop wrapper keeps the same user-facing parameters as the `sde_ur5e_teleop` teleop launch and only overrides the internal controller topics and controller-management settings needed for simulation.
- Both the real-world and Gazebo teleop wrappers expose `reverse_for_front_view:=true` to flip the planar and tilt controls when operating from in front of the robot.
- Gazebo teleoperation is still experimental.
- The Gazebo trajectory path targets `eff_joint_traj_controller`, which is the controller spawned by the installed `ur_gazebo` Universal Robots UR5e bringup.
- Velocity mode is still experimental.
- `onrobot_rg_control_default_gazebo.launch` starts the OnRobot RG2 simulated joint controller and exposes `/onrobot_rg/set_command` for the 3Dconnexion SpaceMouse gripper button.

To start the same Gazebo stack in the predefined Terminator layout:

```shell
bash ./RUN-TERMINATOR-TERMINAL.bash #[docker-project] default-gazebo
```

## Real Robot Teleoperation

Recommended startup order:

```shell
roslaunch sde_ur5e_launch ur5e_bringup_default_realworld.launch
roslaunch sde_ur5e_launch ur5e_moveit_default_realworld.launch
roslaunch sde_ur5e_launch ur5e_rviz_default.launch
roslaunch sde_ur5e_launch realsense_camera_default_realworld.launch
roslaunch sde_ur5e_launch onrobot_rg_control_default_realworld.launch
roslaunch sde_ur5e_launch ur5e_teleop_default_realworld.launch
```

Notes:

- `ur5e_bringup_default_realworld.launch` starts the Universal Robots UR5e driver in headless mode by default.
  Pass `headless_mode:=false` for teach pendant mode (see the platform documentation for details).
- `ur5e_bringup_default_realworld.launch` loads the SDE SRDF and kinematics config so RViz (with the MoveIt plugin) works independently of `move_group`.
- `ur5e_bringup_default_realworld.launch` starts `publish-gripper-joint-states.py`, which reads live gripper width from `/OnRobotRGInput` and publishes all OnRobot RG2 joint states to `/joint_states` so `robot_state_publisher` can compute TF for all gripper links and animate the gripper in RViz.
- Both the real-world and Gazebo teleop wrappers expose `reverse_for_front_view:=true` to flip the planar and tilt controls when operating from in front of the robot.
- `ur5e_teleop_default_realworld.launch` defaults to the SpaceMouse input; pass `input_source:=viewport` (and start a rosbridge server) to drive from the Coarobo Viewport panel instead. See [Teleop Input Source](#teleop-input-source).

To start the same real robot stack in the predefined Terminator layout:

```shell
bash ./RUN-TERMINATOR-TERMINAL.bash #[docker-project] default-realworld
```

## Teleop Input Source

The teleop wrappers select their input with the `input_source` argument, accepting `spacemouse` (3Dconnexion SpaceMouse) or `viewport` (Coarobo Viewport panel).
Both wrappers default to `spacemouse`.
Only one input bridge is started, so the two never contend for the shared MoveIt Servo command topic.
With `input_source:=viewport` the moveit_servo stack still starts, but the SpaceMouse bridge and the `spacenav_node` driver do not, and vice versa.

To drive the robot from the Coarobo Viewport panel instead, pass `input_source:=viewport`:

```shell
roslaunch sde_ur5e_launch ur5e_teleop_default_realworld.launch input_source:=viewport
roslaunch sde_ur5e_launch ur5e_teleop_default_gazebo.launch input_source:=viewport
```

The Coarobo Viewport panel connects to ROS over `rosbridge`, so pair the viewport input with `sde_launch:rosbridge_server_default.launch` (already part of the `default-realworld` Terminator layout).

## Launch Files

| Launch File | Description |
| --- | --- |
| `ur5e_bringup_default_gazebo.launch` | Universal Robots UR5e Gazebo simulation |
| `ur5e_bringup_default_realworld.launch` | Universal Robots UR5e real robot bringup |
| `ur5e_moveit_default_gazebo.launch` | MoveIt motion planning (Gazebo) |
| `ur5e_moveit_default_realworld.launch` | MoveIt motion planning (real robot) |
| `ur5e_rviz_default.launch` | RViz visualization (Gazebo and real robot) |
| `realsense_camera_default_realworld.launch` | Intel RealSense D435 wrist and D435i external cameras (real robot) |
| `ur5e_description_default_realworld.launch` | Robot description adapter for the UR5e driver (real robot) |
| `onrobot_rg_control_default_gazebo.launch` | OnRobot RG2 gripper control (Gazebo) |
| `onrobot_rg_control_default_realworld.launch` | OnRobot RG2 gripper control (real robot) |
| `ur5e_teleop_default_gazebo.launch` | SpaceMouse or Viewport teleoperation (Gazebo) |
| `ur5e_teleop_default_realworld.launch` | SpaceMouse or Viewport teleoperation (real robot) |

## FlexBE Behavior

To start the FlexBE behavior engine and app:

```shell
roslaunch sde_launch flexbe_app_default.launch
```

Load the `UR5e Example Behavior` behavior in the FlexBE App and press **Start**.

## Generate a URDF File from a Xacro File

The robot description xacro files in `urdf/` can be expanded into a flat URDF for inspection or for tools (such as the URDF viewport) that do not run xacro themselves:

```shell
rosrun xacro xacro $(rospack find sde_ur5e_launch)/urdf/ur5e_gazebo.xacro > /tmp/ur5e_gazebo.urdf
```

Replace `ur5e_gazebo.xacro` with `ur5e_realworld.xacro` to generate the real-robot variant.
