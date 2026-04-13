# Universal Robot UR5e

Platform-specific documentation for the [Universal Robot UR5e](https://www.universal-robots.com/products/ur5e/) within the SDE.

## External Resources

- Official website: [https://www.universal-robots.com/products/ur5e/](https://www.universal-robots.com/products/ur5e/)
- Official manual: [https://www.universal-robots.com/download/manuals-e-series/user/ur5e/510/user-manual-ur5e-e-series-sw-510-english-international-en/](https://www.universal-robots.com/download/manuals-e-series/user/ur5e/510/user-manual-ur5e-e-series-sw-510-english-international-en/)
- Universal Robot ROS Driver: [https://github.com/UniversalRobots/Universal_Robots_ROS_Driver](https://github.com/UniversalRobots/Universal_Robots_ROS_Driver)

## Platform Configuration

To use the UR5e platform, set the following in `.env`:

```shell
SDE_PLATFORM=ur5e
```

Then configure the ROS network settings in `.env.custom`:

```shell
SDE_ROS_MASTER_HOSTNAME=localhost
SDE_ROBOT_HOSTNAME=
```

> **Note:**
  Currently, the UR5e cannot be operated using host names.
  You may need to configure static IP addresses instead (see [Network Configuration](#network-configuration)).

## Network Configuration

The following fixed IP addresses are being used to control the robot within the laboratory network.

| Device | IP Address |
| --- | --- |
| Robot | `10.40.20.60` or `10.40.20.62` |
| Development machine | `10.40.20.61` or `10.40.20.63` |

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
- Ensure that the UR5e PolyScope version is greater than 5.4 (the current installed version is 5.11).
To update the firmware, download the files from [Universal Robot](https://www.universal-robots.com/download).
To check the robot firmware version, press the 3-line icon in the corner of the screen and then press "About".
- Install the URCap of the Universal Robot ROS Driver.
Enter the robot settings by pressing the 3-line icon and selecting settings.
Then go to "URCap", press the "+" button, and select the URCap file you want to install.
For more details, refer to the [Universal Robot ROS Driver](https://github.com/UniversalRobots/Universal_Robots_ROS_Driver/blob/master/ur_robot_driver/doc/install_urcap_e_series.md) documentation.
- Set up the robot IP in the settings option to `10.40.20.60` or `10.40.20.62`.
- Set up the IP of the PC that will control the robot.
In the "Installation" tab of the teach pendant, go to "URCaps" then set the "Host IP" and "Host name" to `10.40.20.61` or `10.40.20.63`, and the "Custom port" to `50002`. Save the installation file.
- Create a new program called `external_control`.
This program will only have the URCap installed previously.
Select the "External Control URCap" and save the program.
For more detailed information, read the official [Universal Robot](https://www.universal-robots.com/download/manuals-e-series/user/ur5e/510/user-manual-ur5e-e-series-sw-510-english-international-en/) manual or the [Universal Robot ROS Driver](https://github.com/UniversalRobots/Universal_Robots_ROS_Driver/blob/master/ur_robot_driver/doc/install_urcap_e_series.md) documentation.

## Robot Shutdown

- Stop any running code on the teach pendant by pressing the "Stop" button.
- If necessary, move the robot to a safe position using the teach pendant move option or the free drive button (the side button at the top of the teach pendant).
- To turn off the robot, press the power button on the teach pendant and then press "Power off", or press the 3-line icon at the top right corner of the teach pendant and select "Power off".

## ROS Communication

- Load the program `external_control` on the teach pendant (just load the code, do not run it yet).
By default, this code is already loaded when you turn on the robot.
- On the development machine, run `ur5e_bringup_default_realworld.launch` using `roslaunch`.
- Press the "Play" button on the teach pendant.
If a message appears asking from where to run the code, select "Play from beginning".
If everything is OK, the teach pendant program should change its status from "Loading" to "Running".
Also, the ROS terminal should display "Robot ready to receive control commands".
- Execute `ur5e_moveit_default_realworld.launch` and `ur5e_rviz_default_realworld.launch` using `roslaunch`.
You should be able to move the robot from ROS.

> **Important:**
  Always have the emergency stop button in your hand while using the robot.
  In the case of any collision or emergency, press it immediately!

## Emergency Button

If you have pressed the emergency button, you have to initialize the robot again.

- First, release the emergency button and press the "Go to initialization screen" button on the teach pendant, or press the yellow-red LED in the bottom left corner of the teach pendant.
- Second, if the robot is still colliding or too close to itself for safe initialization, press the free drive button and move the robot to a safe position by hand. The teach pendant should display "Backdrive" while pressing the button.
- Third, after making sure that the robot will not collide with anything during its initialization, press the "Start" button and then exit.
