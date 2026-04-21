#!/bin/bash

# This script sources the shared and platform-specific Catkin workspaces.
#
# Usage: source source-catkin-workspaces.bash

################################################################################

# Derive the shared and platform-specific catkin workspace paths.
SDE_SHARED_CATKIN_WS="${SDE_CONTAINER_ROOT_DIR}/ros/sde_catkin_ws"
SDE_ROBOT_PLATFORM_CATKIN_WS="${SDE_CONTAINER_ROOT_DIR}/ros/${SDE_ROBOT_PLATFORM}_catkin_ws"

# Source the shared Catkin workspace.
echo "Sourcing the shared Catkin workspace from '${SDE_SHARED_CATKIN_WS}/devel/setup.bash'."
if [ -f ${SDE_SHARED_CATKIN_WS}/devel/setup.bash ]; then
  source ${SDE_SHARED_CATKIN_WS}/devel/setup.bash
fi

# Source the platform-specific Catkin workspace.
echo "Sourcing the platform Catkin workspace from '${SDE_ROBOT_PLATFORM_CATKIN_WS}/devel/setup.bash'."
if [ -f ${SDE_ROBOT_PLATFORM_CATKIN_WS}/devel/setup.bash ]; then
  source ${SDE_ROBOT_PLATFORM_CATKIN_WS}/devel/setup.bash
fi
