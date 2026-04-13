# sde_ur5e_launch

The `sde_ur5e_launch` package provides launch files for the Universal Robots UR5e platform.

- Maintainer: Lotfi El Hafi ([lotfi@coarobo.com](mailto:lotfi@coarobo.com)).
- Author: Lotfi El Hafi ([lotfi@coarobo.com](mailto:lotfi@coarobo.com)).

## Gazebo Teleoperation

The Gazebo teleoperation wrappers in this package are:

- `ur5e_bringup_default_gazebo.launch`
- `ur5e_moveit_default_gazebo.launch`
- `onrobot_rg_control_default_gazebo.launch`
- `coarobo_ur5e_teleop_default_gazebo.launch`

Recommended startup order:

```shell
roslaunch sde_ur5e_launch ur5e_bringup_default_gazebo.launch
roslaunch sde_ur5e_launch ur5e_moveit_default_gazebo.launch
roslaunch sde_ur5e_launch onrobot_rg_control_default_gazebo.launch
roslaunch sde_ur5e_launch coarobo_ur5e_teleop_default_gazebo.launch
```

Notes:

- `coarobo_ur5e_teleop_default_gazebo.launch` wraps the package-local teleop stack from `coarobo_teleop`.
- `ur5e_bringup_default_gazebo.launch` spawns a Universal Robots UR5e model with the OnRobot RG2 gripper attached in Gazebo.
- `ur5e_bringup_default_gazebo.launch` starts the robot in the MoveIt `home` joint configuration by default.
- The Gazebo teleop wrapper uses `flange` for the end-effector and operator command frame so the 3Dconnexion SpaceMouse feel stays aligned with the real-world teleop setup.
- The Gazebo teleop wrapper keeps the same user-facing parameters as the package-local `coarobo_teleop` teleop launch and only overrides the internal controller topics and controller-management settings needed for simulation.
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
roslaunch sde_ur5e_launch ur5e_rviz_default_realworld.launch
roslaunch sde_ur5e_launch ur5e_realsense_default_realworld.launch
roslaunch sde_ur5e_launch onrobot_rg_control_default_realworld.launch
roslaunch sde_ur5e_launch coarobo_ur5e_teleop_default_realworld.launch
```

Notes:

- `ur5e_bringup_default_realworld.launch` starts the Universal Robots UR5e driver in headless mode by default.
  Pass `headless_mode:=false` for teach pendant mode (see the platform documentation for details).
- Both the real-world and Gazebo teleop wrappers expose `reverse_for_front_view:=true` to flip the planar and tilt controls when operating from in front of the robot.

To start the same real robot stack in the predefined Terminator layout:

```shell
bash ./RUN-TERMINATOR-TERMINAL.bash #[docker-project] default-realworld
```

## Launch Files

| Launch File | Description |
| --- | --- |
| `ur5e_bringup_default_gazebo.launch` | Universal Robots UR5e Gazebo simulation |
| `ur5e_bringup_default_realworld.launch` | Universal Robots UR5e real robot bringup |
| `ur5e_moveit_default_gazebo.launch` | MoveIt motion planning (Gazebo) |
| `ur5e_moveit_default_realworld.launch` | MoveIt motion planning (real robot) |
| `ur5e_rviz_default_gazebo.launch` | RViz visualization (Gazebo) |
| `ur5e_rviz_default_realworld.launch` | RViz visualization (real robot) |
| `ur5e_realsense_default_realworld.launch` | Intel RealSense D435i camera (real robot) |
| `onrobot_rg_control_default_gazebo.launch` | OnRobot RG2 gripper control (Gazebo) |
| `onrobot_rg_control_default_realworld.launch` | OnRobot RG2 gripper control (real robot) |
| `coarobo_ur5e_teleop_default_gazebo.launch` | 3Dconnexion SpaceMouse teleoperation (Gazebo) |
| `coarobo_ur5e_teleop_default_realworld.launch` | 3Dconnexion SpaceMouse teleoperation (real robot) |
