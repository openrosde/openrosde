#!/bin/bash

# This script builds and sources the shared and platform-specific Catkin workspaces on top of the system ROS environment.
#
# Usage: bash build-catkin-workspaces.bash

################################################################################

# Derive the shared and platform-specific catkin workspace paths.
SDE_SHARED_CATKIN_WS="${SDE_CONTAINER_ROOT_DIR}/ros/sde_catkin_ws"
SDE_ROBOT_PLATFORM_CATKIN_WS="${SDE_CONTAINER_ROOT_DIR}/ros/${SDE_ROBOT_PLATFORM}_catkin_ws"

# Source the ROS distribution environment.
source /opt/ros/noetic/setup.bash

# Build the shared Catkin workspace.
cd ${SDE_SHARED_CATKIN_WS} && catkin build

# Source the shared Catkin workspace.
source ${SDE_SHARED_CATKIN_WS}/devel/setup.bash

# Build the platform-specific Catkin workspace.
cd ${SDE_ROBOT_PLATFORM_CATKIN_WS} && catkin build

# Source both Catkin workspaces.
source ${SDE_CONTAINER_ROOT_DIR}/docker/sde-base/scripts/source-catkin-workspaces.bash
