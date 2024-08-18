#!/bin/bash

################################################################################

# Source the ROS distribution environment.
source /opt/ros/noetic/setup.bash

# Build the Catkin workspace.
cd /root/SDE/ros/catkin_ws/ && catkin build

# Source the Catkin workspace.
source /root/SDE/ros/catkin_ws/devel/setup.bash
