#!/bin/bash

# This script brings up the TurtleBot3 robot by SSH, as 'BRINGUP-ROS-ROBOT.bash' calls it when 'turtlebot3' is the active platform.
# It runs with every 'OPENROSDE_*' variable exported by 'scripts/load-openrosde-env.bash'.
#
# Usage: bash ./scripts/turtlebot3/bringup-ros-robot.bash <rosmaster-hostname>
#
# <rosmaster-hostname>: Host name or IP address of the ROS master via 'ROS_MASTER_URI=http://<rosmaster-hostname>:11311'.

################################################################################

# Kill the ROS processes inside the robot, then start its bringup, its camera, and the decompression of its images.
ssh -f -t -l pi turtlebot3.local 'bash -c "
source /opt/ros/kinetic/setup.bash;
source ~/catkin_ws/devel/setup.bash;
export ROS_MASTER_URI=http://'$1':11311;
export ROS_HOSTNAME=turtlebot3.local;
export TURTLEBOT3_MODEL=waffle_pi;
killall -9 roscore;
killall -9 rosmaster;
sudo /usr/sbin/ntpdate ntp.ubuntu.com;
roslaunch turtlebot3_bringup turtlebot3_robot.launch &
sleep 5;
roslaunch turtlebot3_bringup turtlebot3_rpicamera.launch &
sleep 5;
rosrun image_transport republish compressed in:=/raspicam_node/image image_transport:=compressed raw out:=/raspicam_node/image &
sleep 5;
echo "Done"
"'
