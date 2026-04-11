#!/bin/bash

################################################################################

# Derive the platform-specific catkin workspace path.
SDE_CATKIN_WS="/root/SDE/ros/${SDE_PLATFORM:-turtlebot3}_catkin_ws"

# Find files and directories owned by 'root' in path and change ownership to current user and group IDs.
find ${SDE_CATKIN_WS}/src/ -user root -print -exec chown ${USER_ID}:${GROUP_ID} {} \;
