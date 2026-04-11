#!/bin/bash

################################################################################

# Derive the platform-specific catkin workspace path.
SDE_CATKIN_WS="/root/SDE/ros/${SDE_PLATFORM:-turtlebot3}_catkin_ws"

# Source the ROS distribution environment.
source /opt/ros/noetic/setup.bash

# Build the Catkin workspace.
cd ${SDE_CATKIN_WS} && catkin build

# Source the Catkin workspace.
source ${SDE_CATKIN_WS}/devel/setup.bash
