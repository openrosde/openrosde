#!/bin/bash

# This script builds and sources the shared, platform-specific, and user Catkin workspaces on top of the system ROS environment.
#
# Usage: bash build-catkin-workspaces.bash

################################################################################

# Derive the shared, platform-specific, and user catkin workspace paths.
SDE_SHARED_CATKIN_WS="${SDE_CONTAINER_ROOT_DIR}/ros/sde_catkin_ws"
SDE_ROBOT_PLATFORM_CATKIN_WS="${SDE_CONTAINER_ROOT_DIR}/ros/${SDE_ROBOT_PLATFORM}_catkin_ws"
SDE_USER_CATKIN_WS="${SDE_CONTAINER_ROOT_DIR}/ros/user_catkin_ws"

# Source the ROS distribution environment.
source /opt/ros/noetic/setup.bash

# Build the shared Catkin workspace.
cd ${SDE_SHARED_CATKIN_WS} && catkin build

# Source the shared Catkin workspace.
source ${SDE_SHARED_CATKIN_WS}/devel/setup.bash

# Build the platform-specific Catkin workspace.
cd ${SDE_ROBOT_PLATFORM_CATKIN_WS} && catkin build

# Source the platform-specific Catkin workspace.
source ${SDE_ROBOT_PLATFORM_CATKIN_WS}/devel/setup.bash

# Build the user Catkin workspace (overlay) if it exists.
if [ -d ${SDE_USER_CATKIN_WS}/src ]; then
  cd ${SDE_USER_CATKIN_WS} && catkin build
fi

# Source all Catkin workspaces.
source ${SDE_CONTAINER_ROOT_DIR}/docker/sde-base/scripts/source-catkin-workspaces.bash
