# Universal Robots UR5e

Platform-specific documentation for the [Universal Robots UR5e](https://www.universal-robots.com/products/ur5e/) within the SDE.

## 🔗 External Resources

- Official website: [https://www.universal-robots.com/products/ur5e/](https://www.universal-robots.com/products/ur5e/)
- Official manual: [https://www.universal-robots.com/download/manuals-e-series/user/ur5e/510/user-manual-ur5e-e-series-sw-510-english-international-en/](https://www.universal-robots.com/download/manuals-e-series/user/ur5e/510/user-manual-ur5e-e-series-sw-510-english-international-en/)
- Universal Robots ROS Driver: [https://github.com/UniversalRobots/Universal_Robots_ROS_Driver](https://github.com/UniversalRobots/Universal_Robots_ROS_Driver)
- ROS Industrial Universal Robot: [https://github.com/ros-industrial/universal_robot](https://github.com/ros-industrial/universal_robot)
- Osaka University Harada Laboratory OnRobot ROS: [https://github.com/UOsaka-Harada-Laboratory/onrobot](https://github.com/UOsaka-Harada-Laboratory/onrobot)
- Intel RealSense ROS: [https://github.com/realsenseai/realsense-ros](https://github.com/realsenseai/realsense-ros)
- ROS spacenav_node: [https://wiki.ros.org/spacenav_node](https://wiki.ros.org/spacenav_node)
- PickNik Robotics UR5 RealSense Camera Adapter: [https://github.com/PickNikRobotics/picknik_accessories/blob/main/descriptions/brackets/ur_realsense_camera_adapter/picknik_ur5_realsense_camera_adapter_rev2.STL](https://github.com/PickNikRobotics/picknik_accessories/blob/main/descriptions/brackets/ur_realsense_camera_adapter/picknik_ur5_realsense_camera_adapter_rev2.STL)

## 🔩 Hardware Overview

The Universal Robots UR5e platform consists of the following components:

- **Robot arm:** [Universal Robots UR5e](https://www.universal-robots.com/products/ur5e/) collaborative robot (serial number: `XXXXXXXXXXX`).
- **Gripper:** [OnRobot RG2](https://onrobot.com/products/rg2) electric parallel gripper, mounted on an [OnRobot Quick Changer](https://onrobot.com/products/quick-changer) (Robot Side 109498 QC-R v3), itself attached to the Universal Robots UR5e tool flange.
- **Wrist camera:** Intel RealSense D435 depth camera, mounted between the Universal Robots UR5e tool flange and the OnRobot Quick Changer using a [camera adapter from PickNik Robotics](https://github.com/PickNikRobotics/picknik_accessories/blob/main/descriptions/brackets/ur_realsense_camera_adapter/picknik_ur5_realsense_camera_adapter_rev2.STL).
- **External camera:** [Intel RealSense D435i](https://www.intelrealsense.com/depth-camera-d435i/) depth camera, mounted on a fixed stand to provide an environment view of the workspace.
- **Gripper controller:** OnRobot Compute Box from the OnRobot Robot Kit, connected to the gripper via the OnRobot Quick Changer and to the network via Ethernet.
  It communicates with the Ubuntu development machine over Modbus TCP (port `502`).
- **Teleop input:** 3Dconnexion SpaceMouse, connected wirelessly to the Ubuntu development machine through a 3Dconnexion Universal Receiver (USB ID `256f:c652`).

> [!WARNING]
> Plug the 3Dconnexion Universal Receiver into a USB 2 port of the Ubuntu development machine, never into a USB 3 port (usually blue).
> On a USB 3 port, the receiver still shows up in `lsusb` and `spacenavd` still opens it, but no motion or button event ever reaches it, so the 3Dconnexion SpaceMouse silently does nothing.

## ⚙️ Platform Configuration

Switch to the Universal Robots UR5e platform:

```shell
bash ./SWITCH-ROBOT-PLATFORM.bash ur5e
```

Camera serial numbers are setup-dependent and must be configured in `.env.custom`:

```shell
SDE_UR5E_WRIST_CAMERA_SERIAL_NO=<your-wrist-camera-serial>
SDE_UR5E_EXTERNAL_CAMERA_SERIAL_NO=<your-external-camera-serial>
```

Run `rs-enumerate-devices` inside the container to find the serial numbers of connected cameras.

If the external camera is not available in your setup, disable it in `.env.custom`:

```shell
SDE_UR5E_ENABLE_EXTERNAL_CAMERA=false
```

The external camera pose (position in meters and orientation in radians, expressed in the `world` frame which is co-located with the robot `base_link`) is also setup-dependent and can be overridden in `.env.custom`.
The defaults below match the Coarobo setup measured on 2026-10-07: the camera stands 0.35 m along `+y` and 0.10 m along `-x` from the robot base, 0.10 m up, level with the ground, and turned 45 degrees from the `-x` axis toward `-y` (yaw of -135 degrees):

```shell
SDE_UR5E_EXTERNAL_CAMERA_X=-0.10
SDE_UR5E_EXTERNAL_CAMERA_Y=0.35
SDE_UR5E_EXTERNAL_CAMERA_Z=0.10
SDE_UR5E_EXTERNAL_CAMERA_ROLL=0
SDE_UR5E_EXTERNAL_CAMERA_PITCH=0
SDE_UR5E_EXTERNAL_CAMERA_YAW=-2.35619
```

These values are baked into the URDF at bringup time, so any change requires restarting the bringup launch file.
Individual values can also be overridden at launch time, for example:

```shell
roslaunch sde_ur5e_launch ur5e_bringup_default_realworld.launch external_camera_y:=-0.30
```

> [!NOTE]
> The Universal Robots UR5e does not broadcast a host name on the network, so it cannot be operated using mDNS host names.
> Static IP addresses must be used instead (see [Network Configuration](#network-configuration)).
> For this reason, `SDE_ROBOT_HOSTNAME` should be left empty.

## 🌐 Network Configuration

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

## 🔌 Robot Bootup

- Turn on the robot by pressing the power button on the teach pendant.
- Initialize the robot by pressing the red LED icon in the bottom left corner.
  Then, press the "On" button, followed by the "Start" button, and exit.
  The robot will make some sound while releasing the motor brakes.
- Operate the robot by clicking on the move icon at the top of the teach pendant or by pressing the free drive button (the side button at the top of the teach pendant) if you want to move the robot by guiding it with your hand.

## 🛠️ Robot Setup

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

## ⏹️ Robot Shutdown

- Stop any running code on the teach pendant by pressing the "Stop" button.
- If necessary, move the robot to a safe position using the teach pendant move option or the free drive button (the side button at the top of the teach pendant).
- To turn off the robot, press the power button on the teach pendant and then press "Power off", or press the 3-line icon at the top right corner of the teach pendant and select "Power off".

## 📡 ROS Communication

The Universal Robots UR5e driver supports two modes of operation: **teach pendant mode** and **headless mode**.

### 🏛️ Teach Pendant Mode

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

### 🤖 Headless Mode

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

### 📊 MoveIt and Visualization

After bringing up the driver (in either mode), launch MoveIt and RViz:

```shell
roslaunch sde_ur5e_launch ur5e_moveit_default_realworld.launch
roslaunch sde_ur5e_launch ur5e_rviz_default.launch
```

You should be able to plan and execute motions from RViz.

### 🌳 TF Frames

When inspecting the TF tree (e.g. with `rqt_tf_tree`), you will notice two frames attached near `base_link` that are **not** broadcast by `robot_state_publisher`: `base` and `tool0_controller`.
This is expected, not a misconfiguration. Both are published by the upstream Universal Robots driver (broadcaster `/ur_hardware_interface`) and appear on every real UR robot:

- **`base`**: the robot controller's own base frame. It is rotated 180 degrees about Z relative to the ROS-standard `base_link` (the UR controller convention has X pointing backward, whereas REP-103 and `base_link` have X forward, Z up). The driver publishes the static `base_link` to `base` transform so ROS poses can be related to what the teach pendant and controller report.
- **`tool0_controller`**: the TCP/flange pose as measured and reported live by the UR controller, as opposed to `tool0`, which `robot_state_publisher` computes via forward kinematics from `/joint_states`. The two should be nearly identical. `tool0_controller` is useful for validating the driver's kinematics against the controller's own reading.

> [!TIP]
> For motion planning and downstream math, always use the URDF/FK frames `base_link` and `tool0`, not `base` or `tool0_controller`, to avoid the 180 degree rotation surprise.
> See the [Universal Robots ROS Driver](https://github.com/UniversalRobots/Universal_Robots_ROS_Driver) documentation for more details.

### 📷 Intel RealSense Cameras

The platform uses two Intel RealSense cameras: a wrist-mounted Intel RealSense D435 and an external Intel RealSense D435i for the environment view.
The serial numbers are setup-dependent and must be set in `.env.custom` (see [Platform Configuration](#platform-configuration)).

> [!WARNING]
> Connect the two cameras to two different USB host controllers of the Ubuntu development machine, never to two ports of the same controller.
> With both cameras streaming through one controller, the controller stopped responding and disconnected every USB device on it, including the 3Dconnexion Universal Receiver, until the Ubuntu development machine was rebooted.
> This command prints the PCI address of the controller behind each camera, and the two addresses must differ:
>
> ```shell
> for d in /sys/bus/usb/devices/*; do if [ "$(cat ${d}/idVendor 2>/dev/null)" = 8086 ]; then echo "$(cat ${d}/product): $(basename $(dirname $(readlink -f /sys/bus/usb/devices/usb$(cat ${d}/busnum))))"; fi; done
> ```

To start both cameras with point cloud generation:

```shell
roslaunch sde_ur5e_launch realsense_camera_default_realworld.launch
```

If the external camera is not connected, disable it by setting the corresponding environment variable in `.env.custom`:

```shell
SDE_UR5E_ENABLE_EXTERNAL_CAMERA=false
```

Alternatively, override the value at launch time:

```shell
roslaunch sde_ur5e_launch realsense_camera_default_realworld.launch enable_external_camera:=false
```

The external camera displays in RViz are disabled by default and can be re-enabled manually once the camera is running.

### 🦾 OnRobot RG2 Gripper

To start the OnRobot RG2 gripper controller via Modbus TCP:

```shell
roslaunch sde_ur5e_launch onrobot_rg_control_default_realworld.launch
```

The gripper can be controlled via the ROS service `/onrobot_rg/set_command`.

> [!IMPORTANT]
> Always have the emergency stop button in your hand while using the robot.
> In the case of any collision or emergency, press it immediately!

### 🥽 Coarobo Sightline Teleoperation

The UR5e can be teleoperated from a Meta Quest 3 headset running the [Coarobo Sightline](https://gitlab.com/coarobo/coarobo-sightline) mixed reality application.

- Start the teleop stack with `input_source:=sightline`, which starts MoveIt Servo with the end effector frame set to `onrobot_rg2_base_link` and relays the wrist camera streams for the headset.
- Start it with `input_source:=spacemouse_viewport_sightline` to run Sightline next to the 3Dconnexion SpaceMouse and Coarobo Viewport, each input driving MoveIt Servo only while it is in use.
- The UR5e Terminator layouts preload the teleop terminal with `input_source:=spacemouse_viewport_sightline` in the `default-realworld` layout and `input_source:=spacemouse` in the `default-gazebo` layout.
- To teleoperate with Sightline alone, press `c` in the teleop terminal and run `roslaunch sde_ur5e_launch ur5e_teleop_default_realworld.launch input_source:=sightline`.
- The headset connects through the ROS TCP Endpoint terminal (`sde_launch:ros_tcp_endpoint_default.launch`) on port `10000`.
- The relayed camera topics are the point cloud on `/wrist_camera/depth/color/points_downsampled` (5 Hz, 2 cm voxel grid) and the compressed image on `/wrist_camera/color/image_raw/compressed_throttled` (10 Hz).

## 🚨 Emergency Button

If you have pressed the emergency button, you have to initialize the robot again.

- First, release the emergency button and press the "Go to initialization screen" button on the teach pendant, or press the yellow-red LED in the bottom left corner of the teach pendant.
- Second, if the robot is still colliding or too close to itself for safe initialization, press the free drive button and move the robot to a safe position by hand.
  The teach pendant should display "Backdrive" while pressing the button.
- Third, after making sure that the robot will not collide with anything during its initialization, press the "Start" button and then exit.

> [!NOTE]
> If the teach pendant is in **Remote** mode and you need to reinitialize after an emergency stop, you may need to switch back to **Local** mode first.

## 📋 Launch Files Reference

The following launch files are available for the Universal Robots UR5e platform (package: `sde_ur5e_launch`):

| Launch File | Description |
| --- | --- |
| `ur5e_bringup_default_realworld.launch` | Universal Robots UR5e driver (headless mode by default) |
| `ur5e_bringup_default_gazebo.launch` | Universal Robots UR5e Gazebo simulation with RG2 gripper |
| `ur5e_moveit_default_realworld.launch` | MoveIt motion planning (real robot) |
| `ur5e_moveit_default_gazebo.launch` | MoveIt motion planning (Gazebo) |
| `ur5e_rviz_default.launch` | RViz visualization (Gazebo and real robot) |
| `realsense_camera_default_realworld.launch` | Intel RealSense D435 wrist and D435i external cameras (external optional) |
| `onrobot_rg_control_default_realworld.launch` | OnRobot RG2 gripper via Modbus TCP |
| `onrobot_rg_control_default_gazebo.launch` | OnRobot RG2 gripper (Gazebo) |
| `ur5e_teleop_default_realworld.launch` | SpaceMouse, Viewport, Sightline, or a combination of them (real robot, `input_source:=`) |
| `ur5e_teleop_default_gazebo.launch` | SpaceMouse, Viewport, Sightline, or a combination of them (Gazebo, `input_source:=`) |

## 🧪 FlexBE Behavior

The `sde_ur5e_flexbe_behaviors` package provides an example behavior that loops the arm between the `home` and `up` SRDF named states using `SrdfStateToMoveit` and `WaitState`.

To start the FlexBE behavior engine and app:

```shell
roslaunch sde_launch flexbe_app_default.launch
```

Load the `UR5e Example Behavior` behavior in the FlexBE App and press **Start**.

> [!CAUTION]
> The FlexBE example behavior is **experimental** and currently has known issues in the Gazebo simulation.
