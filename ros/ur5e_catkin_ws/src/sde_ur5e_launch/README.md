# sde_ur5e_launch

The `sde_ur5e_launch` package coordinates the robot tasks and behaviors across all packages using shared launch files.

* Maintainer: Lotfi El Hafi ([lotfi.elhafi@em.ci.ritsumei.ac.jp](mailto:lotfi.elhafi@em.ci.ritsumei.ac.jp)).
* Author: Lotfi El Hafi ([lotfi.elhafi@em.ci.ritsumei.ac.jp](mailto:lotfi.elhafi@em.ci.ritsumei.ac.jp)).

## Gazebo Teleoperation

The Gazebo teleoperation wrappers in this package are:

* `ur5e_bringup_default_gazebo.launch`
* `ur5e_moveit_default_gazebo.launch`
* `onrobot_rg_control_default_gazebo.launch`
* `coarobo_ur5e_teleop_default_gazebo.launch`

Recommended startup order:

```bash
roslaunch sde_ur5e_launch ur5e_bringup_default_gazebo.launch
roslaunch sde_ur5e_launch ur5e_moveit_default_gazebo.launch
roslaunch sde_ur5e_launch onrobot_rg_control_default_gazebo.launch
roslaunch sde_ur5e_launch coarobo_ur5e_teleop_default_gazebo.launch
```

Notes:

* `coarobo_ur5e_teleop_default_gazebo.launch` wraps the package-local teleop stack from `coarobo_teleop`.
* `ur5e_bringup_default_gazebo.launch` now spawns a UR5e model with the RG2 gripper attached in Gazebo.
* `ur5e_bringup_default_gazebo.launch` starts the robot in the MoveIt `home` joint configuration by default.
* The Gazebo teleop wrapper uses `flange` for the end-effector and operator command frame so the SpaceMouse feel stays aligned with the real-world teleop setup.
* The Gazebo teleop wrapper keeps the same user-facing parameters as the package-local `coarobo_teleop` teleop launch and only overrides the internal controller topics and controller-management settings needed for simulation.
* Both the real-world and Gazebo teleop wrappers expose `reverse_for_front_view:=true` to flip the planar and tilt controls when operating from in front of the robot.
* Gazebo teleoperation is still experimental.
* The Gazebo trajectory path targets `eff_joint_traj_controller`, which is the controller spawned by the installed `ur_gazebo` UR5e bringup.
* Velocity mode is still experimental.
* `onrobot_rg_control_default_gazebo.launch` starts the RG2 simulated joint controller and exposes `/onrobot_rg/set_command` for the SpaceMouse gripper button.

To start the same Gazebo stack in the predefined Terminator layout:

```bash
cd ~/UR5e/ && bash ./RUN-TERMINATOR-TERMINAL.bash [docker-project] default-gazebo
```
