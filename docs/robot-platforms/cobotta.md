# COBOTTA

Platform-specific documentation for the [Denso COBOTTA](https://www.denso-wave.com/en/robot/product/collaborative/cobotta.html) within the SDE.

## 🔗 External Resources

- Product page: [https://www.denso-wave.com/en/robot/product/collaborative/cobotta.html](https://www.denso-wave.com/en/robot/product/collaborative/cobotta.html)
- GitHub repository (denso_cobotta_ros): [https://github.com/DENSORobot/denso_cobotta_ros](https://github.com/DENSORobot/denso_cobotta_ros)
- Official documentation: [https://densorobot.github.io/docs/denso_cobotta_ros/](https://densorobot.github.io/docs/denso_cobotta_ros/)

## 🔩 Hardware Overview

The Denso COBOTTA platform consists of the following components:

- **Robot:** Denso COBOTTA collaborative robot arm (6-DOF).
- **On-board computer:** External Ubuntu development machine running ROS.
- **Gripper:** Parallel gripper (default), vacuum gripper, or none.
- **Connection:** USB (via `denso_cobotta` kernel module driver).

## ⚙️ Platform Configuration

Switch to the Denso COBOTTA platform:

```shell
bash ./SWITCH-ROBOT-PLATFORM.bash cobotta
```

> [!NOTE]
> The default `.env` configuration is pre-configured for the Robotis TurtleBot3 platform.
> Run `SWITCH-ROBOT-PLATFORM.bash cobotta` to create the `.env.custom` file with the Denso COBOTTA configuration.

## 🌐 Network Configuration

The Denso COBOTTA connects to the Ubuntu development machine over USB via the `denso_cobotta` kernel module.
No network configuration is required — `SDE_ROBOT_HOSTNAME` is not applicable for this platform.

## 🚀 Gazebo Simulation

Start the Denso COBOTTA Gazebo simulation using the predefined Terminator layout:

```shell
bash ./RUN-TERMINATOR-TERMINAL.bash #[docker-project] default-gazebo
```

Or start the launch files manually in the Docker container:

```shell
roslaunch sde_cobotta_launch cobotta_bringup_default_gazebo.launch
roslaunch sde_cobotta_launch cobotta_moveit_default_gazebo.launch
roslaunch sde_cobotta_launch cobotta_rviz_default.launch
```

> [!NOTE]
> The Gazebo simulation uses `gripper_type:=none` by default.
> The COBOTTA robot has an Atom CPU and is not capable of running Gazebo locally — the simulation runs on the Ubuntu development machine.

## 🤖 Real Robot Operation

> [!IMPORTANT]
> The `denso_cobotta` kernel module must be loaded on the host machine before starting the driver.
> Perform the CALSET (calibration set) procedure as described in the official documentation before running the robot for the first time.

Start the Denso COBOTTA real robot using the predefined Terminator layout:

```shell
bash ./RUN-TERMINATOR-TERMINAL.bash #[docker-project] default-realworld
```

Or start the launch files manually in the Docker container:

```shell
roslaunch sde_cobotta_launch cobotta_bringup_default_realworld.launch
roslaunch sde_cobotta_launch cobotta_moveit_default_realworld.launch
roslaunch sde_cobotta_launch cobotta_rviz_default.launch
```

## 📋 Launch Files Reference

The following launch files are available for the Denso COBOTTA platform (package: `sde_cobotta_launch`):

| Launch File | Description |
| --- | --- |
| `cobotta_bringup_default_gazebo.launch` | Denso COBOTTA Gazebo simulation (without MoveIt and RViz) |
| `cobotta_bringup_default_realworld.launch` | Denso COBOTTA real robot driver and controllers (without MoveIt and RViz) |
| `cobotta_moveit_default_gazebo.launch` | MoveIt motion planning (Gazebo) |
| `cobotta_moveit_default_realworld.launch` | MoveIt motion planning (real robot) |
| `cobotta_rviz_default.launch` | RViz visualization (both Gazebo and real robot) |
