#!/bin/bash

################################################################################

# Derive the platform-specific catkin workspace path.
SDE_CATKIN_WS="/root/SDE/ros/${SDE_PLATFORM:-turtlebot3}_catkin_ws"

################################################################################

# Download package lists from Ubuntu repositories.
apt-get update

# Install system dependencies required by specific ROS packages.
# http://wiki.ros.org/rosdep
rosdep update --include-eol-distros

################################################################################

# Remove the Catkin workspace.

# Delete unexpected 'catkin_make' artefacts.
cd ${SDE_CATKIN_WS} && rm -r .catkin_workspace build/ devel/ install/
cd ${SDE_CATKIN_WS}/src/ && rm CMakeLists.txt

# Delete expected 'catkin build' artefacts.
cd ${SDE_CATKIN_WS} && catkin clean -y
cd ${SDE_CATKIN_WS} && rm -r CMakeLists.txt .catkin_tools/

################################################################################

# Initialize the Catkin workspace.
cd ${SDE_CATKIN_WS} && catkin_init_workspace

# Build the Catkin workspace.
source /root/SDE/docker/sde-devel/scripts/build-catkin-workspace.bash
