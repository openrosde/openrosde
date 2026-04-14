# Universal Robots UR5e

Platform-specific documentation for the [Universal Robots UR5e](https://www.universal-robots.com/products/ur5e/) within the SDE.

## External Resources

- Official website: [https://www.universal-robots.com/products/ur5e/](https://www.universal-robots.com/products/ur5e/)
- Official manual: [https://www.universal-robots.com/download/manuals-e-series/user/ur5e/510/user-manual-ur5e-e-series-sw-510-english-international-en/](https://www.universal-robots.com/download/manuals-e-series/user/ur5e/510/user-manual-ur5e-e-series-sw-510-english-international-en/)
- Universal Robots ROS Driver: [https://github.com/UniversalRobots/Universal_Robots_ROS_Driver](https://github.com/UniversalRobots/Universal_Robots_ROS_Driver)
- ROS Industrial Universal Robot: [https://github.com/ros-industrial/universal_robot](https://github.com/ros-industrial/universal_robot)
- Osaka University Harada Laboratory OnRobot ROS: [https://github.com/UOsaka-Harada-Laboratory/onrobot](https://github.com/UOsaka-Harada-Laboratory/onrobot)
- Intel RealSense ROS: [https://github.com/IntelRealSense/realsense-ros](https://github.com/IntelRealSense/realsense-ros)
- ROS SpaceNavigator: [https://wiki.ros.org/spacenav_node](https://wiki.ros.org/spacenav_node)
- PickNik Robotics UR5 RealSense Camera Adapter: [https://grabcad.com/library/moveit-studio-ur5-realsense-camera-adapter-from-picknik-robotics-1](https://grabcad.com/library/moveit-studio-ur5-realsense-camera-adapter-from-picknik-robotics-1)

## Hardware Overview

The Universal Robots UR5e platform consists of the following components:

- **Robot arm:** [Universal Robots UR5e](https://www.universal-robots.com/products/ur5e/) collaborative robot (serial number: `XXXXXXXXXXX`).
- **Gripper:** [OnRobot RG2](https://onrobot.com/products/rg2) electric parallel gripper, mounted on an [OnRobot Quick Changer](https://onrobot.com/products/quick-changer) (Robot Side 109498 QC-R v3), itself attached to the Universal Robots UR5e tool flange.
- **Camera:** [Intel RealSense D435i](https://www.intelrealsense.com/depth-camera-d435i/) depth camera, mounted between the Universal Robots UR5e tool flange and the OnRobot Quick Changer using a [camera adapter from PickNik Robotics](https://grabcad.com/library/moveit-studio-ur5-realsense-camera-adapter-from-picknik-robotics-1).
- **Gripper controller:** OnRobot Compute Box from the OnRobot Robot Kit, connected to the gripper via the OnRobot Quick Changer and to the network via Ethernet.
  It communicates with the Ubuntu development machine over Modbus TCP (port `502`).

## Platform Configuration

Switch to the Universal Robots UR5e platform:

```shell
bash ./SWITCH-ROBOT-PLATFORM.bash ur5e
```

> [!NOTE]
> The Universal Robots UR5e does not broadcast a host name on the network, so it cannot be operated using mDNS host names.
> Static IP addresses must be used instead (see [Network Configuration](#network-configuration)).
> For this reason, `SDE_ROBOT_HOSTNAME` should be left empty.

## Network Configuration

All devices are connected to the same local network using fixed IP addresses.
Although host names would be preferred for convenience, the Universal Robots UR5e and the OnRobot Compute Box do not broadcast any host name, so defaulting to fixed IPs is necessary.

| Device | SDE Default IP | Factory Default IP |
| --- | --- | --- |
| Universal Robots UR5e | `192.168.1.200` | `192.168.1.10` |
| OnRobot Compute Box | `192.168.1.201` | `192.168.1.1` |
| Ubuntu development machine | `192.168.1.202` | n/a |

> [!NOTE]
> The SDE Default IPs are the addresses pre-configured in the `.env` and launch files.
> They can be changed by the user in `.env.custom` or in the launch file arguments.

> [!NOTE]
> The OnRobot Compute Box factory default IP (`192.168.1.1`) may need to be changed to `192.168.1.201` after a factory reset.
> Connect to it directly via Ethernet and access its web interface at `http://192.168.1.1` to change the IP.
> The default username is `admin` and the default password is `OnRobot`.

## Robot Bootup

- Turn on the robot by pressing the power button on the teach pendant.
- Initialize the robot by pressing the red LED icon in the bottom left corner.
  Then, press the "On" button, followed by the "Start" button, and exit.
  The robot will make some sound while releasing the motor brakes.
- Operate the robot by clicking on the move icon at the top of the teach pendant or by pressing the free drive button (the side button at the top of the teach pendant) if you want to move the robot by guiding it with your hand.

## Robot Setup

These configurations are only necessary for a new robot or after a factory reset.

- Turn on the robot by pressing the on/off button on the teach pendant.
- Initialize the robot by clicking in the bottom left corner of the teach pendant.
- Ensure that the Universal Robots PolyScope version is greater than 5.4 (the tested version is 5.11).
  To update the firmware, download the files from [Universal Robots](https://www.universal-robots.com/download).
  To check the robot firmware version, press the 3-line icon in the corner of the screen and then press "About".
- Install the URCap of the Universal Robots ROS Driver.
  Enter the robot settings by pressing the 3-line icon and selecting settings.
  Then go to "URCap", press the "+" button, and select the URCap file you want to install.
  For more details, refer to the [Universal Robots ROS Driver](https://github.com/UniversalRobots/Universal_Robots_ROS_Driver/blob/master/ur_robot_driver/doc/install_urcap_e_series.md) documentation.
- Set the robot IP address to `192.168.1.10` in the network settings.
- Set up the IP of the Ubuntu development machine that will control the robot.
  In the "Installation" tab of the teach pendant, go to "URCaps" then set the "Host IP" to `192.168.1.202` and the "Custom port" to `50002`.
  Save the installation file.
- Create a new program called `external_control`.
  This program will only have the URCap installed previously.
  Select the "External Control URCap" and save the program.
  For more detailed information, read the official [Universal Robots](https://www.universal-robots.com/download/manuals-e-series/user/ur5e/510/user-manual-ur5e-e-series-sw-510-english-international-en/) manual or the [Universal Robots ROS Driver](https://github.com/UniversalRobots/Universal_Robots_ROS_Driver/blob/master/ur_robot_driver/doc/install_urcap_e_series.md) documentation.

## Robot Shutdown

- Stop any running code on the teach pendant by pressing the "Stop" button.
- If necessary, move the robot to a safe position using the teach pendant move option or the free drive button (the side button at the top of the teach pendant).
- To turn off the robot, press the power button on the teach pendant and then press "Power off", or press the 3-line icon at the top right corner of the teach pendant and select "Power off".

## ROS Communication

The Universal Robots UR5e driver supports two modes of operation: **teach pendant mode** and **headless mode**.

### Teach Pendant Mode

In this mode, the teach pendant must be set to **Local** mode and the `external_control` program must be started manually from the teach pendant.

- Load the program `external_control` on the teach pendant (just load the code, do not run it yet).
  By default, this code is already loaded when you turn on the robot.
- On the Ubuntu development machine, run `ur5e_bringup_default_realworld.launch` with headless mode disabled:

    ```shell
    roslaunch sde_ur5e_launch ur5e_bringup_default_realworld.launch headless_mode:=false
    ```

- Press the "Play" button on the teach pendant.
  If a message appears asking from where to run the code, select "Play from beginning".
  If everything is OK, the teach pendant program should change its status from "Loading" to "Running".
  Also, the ROS terminal should display "Robot ready to receive control commands".

### Headless Mode

In this mode, the teach pendant must be set to **Remote** mode, allowing the driver to start the `external_control` program automatically without manual interaction on the teach pendant.
This is the default mode used by the launch files.

- Set the teach pendant to **Remote** mode by pressing the button in the top right corner of the Universal Robots PolyScope interface (where it shows "Local") and selecting "Remote".
- On the Ubuntu development machine, run the bringup launch file:

    ```shell
    roslaunch sde_ur5e_launch ur5e_bringup_default_realworld.launch
    ```

  The driver will automatically load and start the `external_control` program on the robot.
  The ROS terminal should display "Robot ready to receive control commands".

> [!NOTE]
> In headless mode, you can still use the teach pendant to monitor the robot, but you cannot start or stop programs from it.
> Switch back to **Local** mode if you need manual control from the teach pendant.

### MoveIt and Visualization

After bringing up the driver (in either mode), launch MoveIt and RViz:

```shell
roslaunch sde_ur5e_launch ur5e_moveit_default_realworld.launch
roslaunch sde_ur5e_launch ur5e_rviz_default_realworld.launch
```

You should be able to plan and execute motions from RViz.

### Intel RealSense Camera

To start the Intel RealSense D435i camera stream with point cloud generation:

```shell
roslaunch sde_ur5e_launch ur5e_realsense_default_realworld.launch
```

### OnRobot RG2 Gripper

To start the OnRobot RG2 gripper controller via Modbus TCP:

```shell
roslaunch sde_ur5e_launch onrobot_rg_control_default_realworld.launch
```

The gripper can be controlled via the ROS service `/onrobot_rg/set_command`.

> [!IMPORTANT]
> Always have the emergency stop button in your hand while using the robot.
> In the case of any collision or emergency, press it immediately!

## Emergency Button

If you have pressed the emergency button, you have to initialize the robot again.

- First, release the emergency button and press the "Go to initialization screen" button on the teach pendant, or press the yellow-red LED in the bottom left corner of the teach pendant.
- Second, if the robot is still colliding or too close to itself for safe initialization, press the free drive button and move the robot to a safe position by hand.
  The teach pendant should display "Backdrive" while pressing the button.
- Third, after making sure that the robot will not collide with anything during its initialization, press the "Start" button and then exit.

> [!NOTE]
> If the teach pendant is in **Remote** mode and you need to reinitialize after an emergency stop, you may need to switch back to **Local** mode first.

## Launch Files Reference

The following launch files are available for the Universal Robots UR5e platform (package: `sde_ur5e_launch`):

| Launch File | Description |
| --- | --- |
| `ur5e_bringup_default_realworld.launch` | Universal Robots UR5e driver (headless mode by default) |
| `ur5e_bringup_default_gazebo.launch` | Universal Robots UR5e Gazebo simulation with RG2 gripper |
| `ur5e_moveit_default_realworld.launch` | MoveIt motion planning (real robot) |
| `ur5e_moveit_default_gazebo.launch` | MoveIt motion planning (Gazebo) |
| `ur5e_rviz_default_realworld.launch` | RViz visualization (real robot) |
| `ur5e_rviz_default_gazebo.launch` | RViz visualization (Gazebo) |
| `ur5e_realsense_default_realworld.launch` | Intel RealSense D435i camera |
| `onrobot_rg_control_default_realworld.launch` | OnRobot RG2 gripper via Modbus TCP |
| `onrobot_rg_control_default_gazebo.launch` | OnRobot RG2 gripper (Gazebo) |
| `coarobo_ur5e_teleop_default_realworld.launch` | 3Dconnexion SpaceNavigator teleoperation (real robot) |
| `coarobo_ur5e_teleop_default_gazebo.launch` | 3Dconnexion SpaceNavigator teleoperation (Gazebo) |
