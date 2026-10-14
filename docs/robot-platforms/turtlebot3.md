# TurtleBot3 (Waffle Pi)

Platform-specific documentation for the Robotis [TurtleBot3 (Waffle Pi)](https://emanual.robotis.com/docs/en/platform/turtlebot3/overview/) within OpenRoSDE.

## 🔗 External Resources

- Official manual: [https://emanual.robotis.com/docs/en/platform/turtlebot3/overview/](https://emanual.robotis.com/docs/en/platform/turtlebot3/overview/)
- GitHub repository: [https://github.com/ROBOTIS-GIT/turtlebot3](https://github.com/ROBOTIS-GIT/turtlebot3)
- ROS wiki: [http://wiki.ros.org/turtlebot3](http://wiki.ros.org/turtlebot3)

## 🔩 Hardware Overview

The Robotis TurtleBot3 (Waffle Pi) platform consists of the following components:

- **Robot:** Robotis [TurtleBot3 (Waffle Pi)](https://emanual.robotis.com/docs/en/platform/turtlebot3/overview/) mobile robot.
- **On-board computer:** Raspberry Pi 3B+ running Raspberry Pi OS with ROS Kinetic.
- **Microcontroller:** [Robotis OpenCR](https://emanual.robotis.com/docs/en/parts/controller/opencr10/) board for motor control and sensor interfacing.
- **LiDAR:** LDS-01 360-degree laser distance sensor.
- **Camera:** [Raspberry Pi Camera Module v2](https://www.raspberrypi.com/products/camera-module-v2/).

## ⚙️ Platform Configuration

Switch to the Robotis TurtleBot3 platform:

```shell
bash ./SWITCH-ROBOT-PLATFORM.bash turtlebot3
```

> [!NOTE]
> The default `.env` configuration is already pre-configured for the Robotis TurtleBot3 platform.
> Creating `.env.custom` is only necessary to override specific settings.

## 🌐 Network Configuration

This project is configured to use up to 3 Robotis TurtleBot3 (Waffle Pi) robots simultaneously.
The robots use mDNS host names for network discovery.

| Device | Host Name | Default Credentials |
| --- | --- | --- |
| TurtleBot3 (Waffle Pi) | `turtlebot3.local` | User: `pi`, Password: `turtlebot` |

To connect to the Raspberry Pi on-board computer of the Robotis TurtleBot3 (Waffle Pi), run the following in a new terminal on the Ubuntu development machine:

```shell
ping turtlebot3.local
ssh pi@turtlebot3.local
```

> [!NOTE]
> Do not, under any circumstance, directly modify the system of the on-board computer of the Robotis TurtleBot3 (Waffle Pi) robot.
> Always use the environment of the Ubuntu development machine to interact with the robot using ROS over the local network.

## 🔌 Robot Bootup

- Connect the battery to the Robotis TurtleBot3 (Waffle Pi).
- Turn on the Robotis OpenCR board by pressing the power switch.
  The Raspberry Pi will boot automatically.
- Wait for the Raspberry Pi to fully boot (approximately 30 seconds).
  It will automatically connect to known Wi-Fi networks and start the ROS nodes.

## 🛠️ Robot Setup

Follow this step-by-step guide to set up or reinitialize a Robotis TurtleBot3 (Waffle Pi) robot.
These configurations are only necessary for a new robot or after a factory reset.

> [!NOTE]
> The instructions below contain only minor modifications from the Robotis TurtleBot3 (Waffle Pi) official manual.

> [!NOTE]
> The Robotis TurtleBot3 (Waffle Pi) robot is set up using the older ROS Kinetic distribution because the ROS package that interfaces the Raspberry Pi Camera Module v2 is not compatible with the newer ROS distributions.
> Therefore, the ROS distribution running in the robots does not match the ROS distribution of the Ubuntu development machine.
> This is not an optimal solution, but so far, it did not cause important issues.

1. Read the following page of the Robotis TurtleBot3 (Waffle Pi) official manual: [https://emanual.robotis.com/docs/en/platform/turtlebot3/sbc_setup/#sbc-setup](https://emanual.robotis.com/docs/en/platform/turtlebot3/sbc_setup/#sbc-setup).
2. Download the following Robotis TurtleBot3 (Waffle Pi) SBC Image: Raspberry Pi 3B+ ROS Kinetic on Raspberry Pi OS (Raspbian OS).
    Link: [http://www.robotis.com/service/download.php?no=1738](http://www.robotis.com/service/download.php?no=1738).
    File: `tb3_rpi3b+_kinetic_20220513.zip`
    SHA256: `eb8173f3727db08087990b2c4e2bb211e70bd54644644834771fc8b971856b97`.
3. Flash the image on the microSD card of the Robotis TurtleBot3 (Waffle Pi).
4. Insert the microSD card into the Raspberry Pi.
5. Connect a monitor to the HDMI port of Raspberry Pi.
6. Connect input devices (keyboard, mouse) to the USB ports of Raspberry Pi.
7. Connect the power (either with USB or Robotis OpenCR) to turn on the Raspberry Pi.
8. After booting up the Raspberry Pi, use the GUI and input devices to connect to the Wi-Fi.
    The Raspberry Pi will automatically connect to known Wi-Fi networks after reboot.
9. Open the "Raspberry Pi Configuration" menu and verify that the host name is `turtlebot3`.
10. In the same "Raspberry Pi Configuration" menu, verify that the overscan is disabled, and that both SSH and the camera are enabled.
11. Reboot the Raspberry Pi and disconnect the monitor and input devices as the next steps can be performed from a remote Ubuntu development machine via SSH.
12. Connect to the Raspberry Pi via SSH (password: `turtlebot`):

    ```shell
    ping turtlebot3.local
    ssh pi@turtlebot3.local
    ```

13. Inside the Raspberry Pi, synchronize the time:

    ```shell
    sudo apt-get install ntpdate
    sudo ntpdate ntp.ubuntu.com
    ```

14. Inside the Raspberry Pi, fix the ROS GPG key issue (see: [https://discourse.ros.org/t/ros-gpg-key-expiration-incident/20669](https://discourse.ros.org/t/ros-gpg-key-expiration-incident/20669)):

    ```shell
    curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | sudo apt-key add -
    ```

15. Inside the Raspberry Pi, expand the filesystem:

    ```shell
    sudo raspi-config
    ```

    Select "7 Advanced Options" > "A1 Expand Filesystem" then exit and reboot.
16. Connect once more to the Raspberry Pi via SSH (password: `turtlebot`):

    ```shell
    ping turtlebot3.local
    ssh pi@turtlebot3.local
    ```

17. Inside the Raspberry Pi, add the ROS network information to the Bash shell by running `nano ~/.bashrc` and adding the following lines at the bottom of the file:

    ```shell
    export ROS_MASTER_URI=http://<rosmaster-hostname>.local:11311
    export ROS_HOSTNAME=turtlebot3.local
    export TURTLEBOT3_MODEL=waffle_pi
    ```

    Note that `<rosmaster-hostname>` should be the host name of the Ubuntu development machine for better performance.
    Note also that `TURTLEBOT3_MODEL=waffle_pi`.
    Save the file and load the new settings into the current Bash shell with `source ~/.bashrc`.
18. Do not install the "NEW LDS-02 Configuration" unless you use Robotis TurtleBot3 (Waffle Pi) robots from 2022 or later.
19. Read the following page of the Robotis TurtleBot3 (Waffle Pi) official manual: [https://emanual.robotis.com/docs/en/platform/turtlebot3/opencr_setup/](https://emanual.robotis.com/docs/en/platform/turtlebot3/opencr_setup/).
20. Inside the Raspberry Pi, update the Robotis OpenCR firmware with:

    ```shell
    sudo dpkg --add-architecture armhf
    sudo apt-get update
    sudo apt-get install libc6:armhf
    export OPENCR_PORT=/dev/ttyACM0
    export OPENCR_MODEL=waffle
    rm -rf ./opencr_update.tar.bz2
    wget https://github.com/ROBOTIS-GIT/OpenCR-Binaries/raw/master/turtlebot3/ROS1/latest/opencr_update.tar.bz2
    tar -xvf opencr_update.tar.bz2
    cd ./opencr_update
    ./update.sh $OPENCR_PORT $OPENCR_MODEL.opencr
    cd ~/
    ```

    Note that `OPENCR_MODEL=waffle`.
21. Read the following page of the Robotis TurtleBot3 (Waffle Pi) official manual: [https://emanual.robotis.com/docs/en/platform/turtlebot3/appendix_raspi_cam/](https://emanual.robotis.com/docs/en/platform/turtlebot3/appendix_raspi_cam/).
22. Inside the Raspberry Pi, test the Raspberry Pi Camera Module v2 and install its related ROS packages with:

    ```shell
    cd ~/
    raspistill -v -o test.jpg
    ls
    rm test.jpg
    cd ~/catkin_ws/src
    git clone https://github.com/UbiquityRobotics/raspicam_node.git
    sudo apt-get install ros-kinetic-compressed-image-transport ros-kinetic-camera-info-manager
    cd ~/catkin_ws && catkin_make
    cd ~/
    source ~/.bashrc
    ```

## ⏹️ Robot Shutdown

- Stop any running ROS nodes on the Ubuntu development machine.
- Turn off the Robotis OpenCR board by pressing the power switch.
  The Raspberry Pi will shut down automatically.

## 📡 ROS Communication

You can bring up the Robotis TurtleBot3 (Waffle Pi) robots by executing the following script on the Ubuntu development machine:

```shell
bash ./BRINGUP-ROS-ROBOT.bash <rosmaster-hostname> #[docker-project]
```

Alternatively, you can use the Gazebo simulator to test without a physical robot:

```shell
roslaunch openrosde_turtlebot3_launch turtlebot3_bringup_default_gazebo.launch
```

### 🧭 Navigation

To start the navigation stack:

```shell
roslaunch openrosde_turtlebot3_launch turtlebot3_navigation_default_gazebo.launch
```

### 🗺️ Mapping

To start SLAM mapping:

```shell
roslaunch openrosde_turtlebot3_launch turtlebot3_mapping_default.launch
```

### 📊 RViz Visualization

To start RViz with the TurtleBot3 configuration:

```shell
roslaunch openrosde_turtlebot3_launch turtlebot3_rviz_default_gazebo.launch
```

## 📋 Launch Files Reference

The following launch files are available for the Robotis TurtleBot3 platform (package: `openrosde_turtlebot3_launch`):

| Launch File | Description |
| --- | --- |
| `turtlebot3_bringup_default_gazebo.launch` | TurtleBot3 Gazebo simulation |
| `turtlebot3_navigation_default_gazebo.launch` | Navigation stack (Gazebo) |
| `turtlebot3_mapping_default.launch` | SLAM mapping (gmapping) |
| `turtlebot3_rviz_default_gazebo.launch` | RViz visualization (Gazebo) |
| `turtlebot3_rviz_default_realworld.launch` | RViz visualization (real robot) |

The following shared launch files are available across all platforms (package: `openrosde_launch`):

| Launch File | Description |
| --- | --- |
| `flexbe_app_default.launch` | FlexBE behavior engine and app |

## 🧪 FlexBE Behavior

The `openrosde_turtlebot3_flexbe_behaviors` package provides an example behavior that loops navigation between two waypoints using `MoveBaseState` and `WaitState`.

To start the FlexBE behavior engine and app:

```shell
roslaunch openrosde_launch flexbe_app_default.launch
```

Load the `TurtleBot3 Example Behavior` behavior in the FlexBE App and press **Start**.
