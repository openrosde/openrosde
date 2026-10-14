#!/bin/bash

# This script brings up the Sciurus17 robot by SSH, as 'BRINGUP-ROS-ROBOT.bash' calls it when 'sciurus17' is the active platform.
# It runs with every 'OPENROSDE_*' variable exported by 'scripts/load-openrosde-env.bash'.
#
# Usage: bash ./scripts/sciurus17/bringup-ros-robot.bash <rosmaster-hostname>
#
# <rosmaster-hostname>: Host name or IP address of the ROS master via 'ROS_MASTER_URI=http://<rosmaster-hostname>:11311'.

################################################################################

# Kill the ROS processes inside the robot, then start its bringup without RViz.
ssh -f -t -l sciurus ${OPENROSDE_ROBOT_HOSTNAME} 'bash -c "
source /opt/ros/noetic/setup.bash;
export ROS_MASTER_URI=http://'$1':11311;
export ROS_HOSTNAME='${OPENROSDE_ROBOT_HOSTNAME}';
killall -9 roscore;
killall -9 rosmaster;
roslaunch sciurus17_bringup sciurus17_bringup.launch use_rviz:=false &
sleep 5;
echo Done
"'
