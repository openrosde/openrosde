# Fetch

Platform-specific documentation for the [Fetch Robotics Fetch](https://fetchrobotics.github.io/docs/) within the SDE.

## 🔗 External Resources

- Official documentation: [https://fetchrobotics.github.io/docs/](https://fetchrobotics.github.io/docs/)
- ROS wiki: [http://wiki.ros.org/Robots/Fetch](http://wiki.ros.org/Robots/Fetch)
- GitHub repository: [https://github.com/fetchrobotics/fetch_ros](https://github.com/fetchrobotics/fetch_ros)

## 🔩 Hardware Overview

The Fetch Robotics Fetch platform consists of the following components:

- **Robot:** [Fetch Robotics Fetch](https://fetchrobotics.github.io/docs/) mobile manipulator.
- **On-board computer:** Intel-based computer running Ubuntu with ROS.
- **Arm:** 7-DOF manipulator with parallel-jaw gripper.
- **LiDAR:** SICK TiM571 laser scanner.
- **Camera:** Primesense Carmine 1.09 short-range depth sensor (head-mounted).

## ⚙️ Platform Configuration

Switch to the Fetch Robotics Fetch platform:

```shell
bash ./SWITCH-ROBOT-PLATFORM.bash fetch
```

> [!NOTE]
> The default `.env` configuration is pre-configured for the Robotis TurtleBot3 platform.
> Run `SWITCH-ROBOT-PLATFORM.bash fetch` to create the `.env.custom` file with the Fetch Robotics Fetch configuration.

## 🌐 Network Configuration

The Fetch Robotics Fetch robot uses mDNS host names for network discovery.

| Device | Host Name | Notes |
| --- | --- | --- |
| Fetch Robotics Fetch | `fetch.local` | Default mDNS hostname |

To connect to the real robot, update the ROS master hostname in `.env.custom`:

```shell
SDE_ROS_MASTER_HOSTNAME=fetch.local
```

## 🚀 Gazebo Simulation

Start the Fetch Robotics Fetch Gazebo simulation using the predefined Terminator layout:

```shell
bash ./RUN-TERMINATOR-TERMINAL.bash #[docker-project] default-gazebo
```

Or start the launch files manually in the Docker container:

```shell
roslaunch sde_fetch_launch fetch_bringup_default_gazebo.launch
roslaunch sde_fetch_launch fetch_navigation_default_gazebo.launch
roslaunch sde_fetch_launch fetch_moveit_default.launch
roslaunch sde_fetch_launch fetch_rviz_default_gazebo.launch
```

## 🤖 Real Robot Operation

Start the Fetch Robotics Fetch real robot stack using the predefined Terminator layout:

```shell
bash ./RUN-TERMINATOR-TERMINAL.bash #[docker-project] default-realworld
```

Or start the launch files manually in the Docker container:

```shell
roslaunch sde_fetch_launch fetch_bringup_default_realworld.launch
roslaunch sde_fetch_launch fetch_navigation_default_realworld.launch
roslaunch sde_fetch_launch fetch_moveit_default.launch
roslaunch sde_fetch_launch fetch_rviz_default_realworld.launch
```
