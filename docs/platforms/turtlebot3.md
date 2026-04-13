# TurtleBot3 (Waffle Pi)

Platform-specific documentation for the Robotis [TurtleBot3 (Waffle Pi)](https://emanual.robotis.com/docs/en/platform/turtlebot3/overview/) within the SDE.

## External Resources

- Official manual: [https://emanual.robotis.com/docs/en/platform/turtlebot3/overview/](https://emanual.robotis.com/docs/en/platform/turtlebot3/overview/)
- GitHub repository: [https://github.com/ROBOTIS-GIT/turtlebot3](https://github.com/ROBOTIS-GIT/turtlebot3)
- ROS wiki: [http://wiki.ros.org/turtlebot3](http://wiki.ros.org/turtlebot3)

## Platform Configuration

To use the TurtleBot3 platform, set the following in `.env`:

```shell
SDE_PLATFORM=turtlebot3
```

The default `.env` configuration is pre-configured for the TurtleBot3 platform with:

```shell
SDE_ROS_MASTER_HOSTNAME=localhost
SDE_ROBOT_HOSTNAME=turtlebot3.local
```

## Robot Configuration

This project is configured to use up to 3 TurtleBot3 (Waffle Pi) robots simultaneously.
The default configuration of the TurtleBot3 (Waffle Pi) on-board computers is as follows, where `x` is the number corresponding to a specific robot:

- User name: `pi`
- Host name: `turtlebot3.local`
- Password: `turtlebot`

To connect to the Raspberry Pi on-board computer of the TurtleBot3 (Waffle Pi), run the following in a new terminal on the development machine:

```shell
ping turtlebot3.local
ssh pi@turtlebot3.local
```

You can also bring up the TurtleBot3 (Waffle Pi) robots by executing the following script on the development machine:

```shell
cd ~/SDE/ && bash ./BRINGUP-ROS-ROBOT.bash <rosmaster-hostname> #[docker-project]
```

> **Note:**
  Do not, under any circumstance, directly modify the system of the on-board computer of the TurtleBot3 (Waffle Pi) robot.
  Always use the environment of the development machine to interact with the robot using ROS over the local network.

## Robot Installation

Follow this step-by-step guide to set up or reinitialize a TurtleBot3 (Waffle Pi) robot.

> **Note:**
  The instructions below contains only minor modifications from the TurtleBot3 (Waffle Pi) official manual.

> **Note:**
  The TurtleBot3 (Waffle Pi) robot is set up using the older ROS Kinetic distribution because the ROS package that interfaces the Camera Module v2 is not compatible with the newer ROS distributions.
  Therefore, the ROS distribution in running in the robots does not match the ROS distribution of the development machine.
  This is not an optimal solution, but so far, it did not cause important issues.

1. Read the following page of the TurtleBot3 (Waffle Pi) official manual: [https://emanual.robotis.com/docs/en/platform/turtlebot3/sbc_setup/#sbc-setup](https://emanual.robotis.com/docs/en/platform/turtlebot3/sbc_setup/#sbc-setup).
1. Download the following TurtleBot3 (Waffle Pi) SBC Image: Raspberry Pi 3B+ ROS Kinetic on Raspberry Pi OS (Raspbian OS).  
Link: [http://www.robotis.com/service/download.php?no=1738](http://www.robotis.com/service/download.php?no=1738).  
File: `tb3_rpi3b+_kinetic_20220513.zip`  
SHA256: `eb8173f3727db08087990b2c4e2bb211e70bd54644644834771fc8b971856b97`.
1. Flash the image on the microSD card of the TurtleBot3 (Waffle Pi).
1. Insert the microSD card into the Raspberry Pi.
1. Connect a monitor to the HDMI port of Raspberry Pi.
1. Connect input devices (keyboard, mouse) to the USB ports of Raspberry Pi
1. Connect the power (either with USB or OpenCR) to turn on the Raspberry Pi.
1. After booting up the Raspberry Pi, use the GUI and input devices to connect to the Wi-Fi.
    The Raspberry Pi will automatically connect to known Wi-Fi networks after reboot.
1. Open the "Raspberry Pi Configuration" menu and verify that the host name is `turtlebot3`.
1. In the same "Raspberry Pi Configuration" menu, verify that the overscan is disabled, and that both SSH and the camera are enabled.
1. Reboot the Raspberry Pi and disconnect the monitor and input devices as the next steps can be performed from a remote development machine via SSH.
1. Connect to the Raspberry Pi via SSH (password: `turtlebot`):

    ```shell
    ping turtlebot3.local
    ssh pi@turtlebot3.local
    ```

1. Inside the Raspberry Pi, synchronize the time:

    ```shell
    sudo apt-get install ntpdate
    sudo ntpdate ntp.ubuntu.com
    ```

1. Inside the Raspberry Pi, fix the ROS GPG key issue (see: [https://discourse.ros.org/t/ros-gpg-key-expiration-incident/20669](https://discourse.ros.org/t/ros-gpg-key-expiration-incident/20669)):

    ```shell
    curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | sudo apt-key add -
    ```

1. Inside the Raspberry Pi, expand the filesystem:

    ```shell
    sudo raspi-config
    ```

    Select "7 Advanced Options" > "A1 Expand Filesystem" then exit and reboot.
1. Connect once more to the Raspberry Pi via SSH (password: `turtlebot`):

    ```shell
    ping turtlebot3.local
    ssh pi@turtlebot3.local
    ```

1. Inside the Raspberry Pi, add the ROS network information to the Bash shell by running `nano ~/.bashrc` and adding the following lines at the bottom of the file:

    ```shell
    export ROS_MASTER_URI=http://<rosmaster-hostname>.local:11311
    export ROS_HOSTNAME=turtlebot3.local
    export TURTLEBOT3_MODEL=waffle_pi
    ```

    Note that `<rosmaster-hostname>` should be the host name of the development machine for better performance.
    Note also that `TURTLEBOT3_MODEL=waffle_pi`.
    Save the file and load the new settings into the current Bash shell with `source ~/.bashrc`.
1. Do not install the "NEW LDS-02 Configuration" unless you use TurtleBot3 (Waffle Pi) robots from 2022 or later.
1. Read the following page of the TurtleBot3 (Waffle Pi) official manual: [https://emanual.robotis.com/docs/en/platform/turtlebot3/opencr_setup/](https://emanual.robotis.com/docs/en/platform/turtlebot3/opencr_setup/).
1. Inside the Raspberry Pi, update the OpenCR firmware with:

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
1. Read the following page of the TurtleBot3 (Waffle Pi) official manual: [https://emanual.robotis.com/docs/en/platform/turtlebot3/appendix_raspi_cam/](https://emanual.robotis.com/docs/en/platform/turtlebot3/appendix_raspi_cam/).
1. Inside the Raspberry Pi, test the Camera Module v2 and install its related ROS packages with:

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
