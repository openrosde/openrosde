# Sciurus17

Platform-specific documentation for the [RT Sciurus17](https://rt-net.jp/products/sciurus17/) within OpenRoSDE.

## 🔗 External Resources

- Product page: [https://rt-net.jp/products/sciurus17/](https://rt-net.jp/products/sciurus17/)
- ROS wiki: [http://wiki.ros.org/sciurus17](http://wiki.ros.org/sciurus17)
- GitHub repository (sciurus17_ros): [https://github.com/rt-net/sciurus17_ros](https://github.com/rt-net/sciurus17_ros)
- GitHub repository (sciurus17_description): [https://github.com/rt-net/sciurus17_description](https://github.com/rt-net/sciurus17_description)

## 🔩 Hardware Overview

The RT Sciurus17 platform consists of the following components:

- **Robot:** RT Sciurus17 upper-body humanoid robot (17-DOF arm + 2-DOF hand).
- **On-board computer:** External Ubuntu development machine running ROS.
- **Arms:** Dual 7-DOF manipulators with parallel-jaw grippers.
- **Head camera:** Intel RealSense D435 depth sensor.

## ⚙️ Platform Configuration

Switch to the RT Sciurus17 platform:

```shell
bash ./SWITCH-ROBOT-PLATFORM.bash sciurus17
```

> [!NOTE]
> The default `.env` configuration is pre-configured for the Robotis TurtleBot3 platform.
> Run `SWITCH-ROBOT-PLATFORM.bash sciurus17` to create the `.env.custom` file with the RT Sciurus17 configuration.

## 🌐 Network Configuration

The RT Sciurus17 robot uses mDNS host names for network discovery.

| Device | Host Name | Notes |
| --- | --- | --- |
| RT Sciurus17 | `sciurus-host.local` | Default mDNS hostname |

To connect to the real robot, update the ROS master hostname in `.env.custom`:

```shell
OPENROSDE_ROS_MASTER_HOSTNAME=sciurus-host.local
```

## 🚀 Gazebo Simulation

Start the RT Sciurus17 Gazebo simulation using the predefined Terminator layout:

```shell
bash ./RUN-TERMINATOR-TERMINAL.bash #[docker-project] default-gazebo
```

Or start the launch files manually in the Docker container:

```shell
roslaunch openrosde_sciurus17_launch sciurus17_bringup_default_gazebo.launch
roslaunch openrosde_sciurus17_launch sciurus17_moveit_default_gazebo.launch
roslaunch openrosde_sciurus17_launch sciurus17_rviz_default.launch
```

## 🕐 Clock Synchronization

The RT Sciurus17 robot requires clock synchronization between the host machine and the robot via Chrony.
Run the following script to restart the Chrony service on both the host and the robot:

```shell
bash ./RESTART-CHRONY-SERVICE.bash
```

> [!NOTE]
> The script connects to the robot via SSH using the default credentials (`sciurus` / `sciurus`).
> The robot hostname is resolved from `OPENROSDE_ROBOT_HOSTNAME` in `env/sciurus17.env` (default: `sciurus-host.local`).

## 🤖 Real Robot Operation

> [!IMPORTANT]
> Before operating the real robot, run `RESTART-CHRONY-SERVICE.bash` to synchronize the host and robot clocks.
> Set up the USB serial device by running `rosrun sciurus17_tools create_udev_rules` once and rebooting.

Start the RT Sciurus17 real robot stack using the predefined Terminator layout:

```shell
bash ./RUN-TERMINATOR-TERMINAL.bash #[docker-project] default-realworld
```

Or start the launch files manually in the Docker container:

```shell
roslaunch openrosde_sciurus17_launch sciurus17_moveit_default_realworld.launch
roslaunch openrosde_sciurus17_launch sciurus17_rviz_default.launch
```

## 📋 Launch Files Reference

The following launch files are available for the RT Sciurus17 platform (package: `openrosde_sciurus17_launch`):

| Launch File | Description |
| --- | --- |
| `sciurus17_bringup_default_gazebo.launch` | RT Sciurus17 Gazebo simulation (without MoveIt and RViz) |
| `sciurus17_moveit_default_gazebo.launch` | MoveIt motion planning (Gazebo) |
| `sciurus17_moveit_default_realworld.launch` | MoveIt motion planning (real robot) |
| `sciurus17_rviz_default.launch` | RViz visualization (both Gazebo and real robot) |

## 🧪 FlexBE Behavior

The `openrosde_sciurus17_flexbe_behaviors` package provides an example behavior that alternates the right and left arms between their `r_arm_init_pose` and `l_arm_init_pose` SRDF named states using `SrdfStateToMoveit` and `WaitState`.

To start the FlexBE behavior engine and app:

```shell
roslaunch openrosde_launch flexbe_app_default.launch
```

Load the `Sciurus17 Example Behavior` behavior in the FlexBE App and press **Start**.

> [!CAUTION]
> The FlexBE example behavior is **experimental** and currently has known issues in the Gazebo simulation.
