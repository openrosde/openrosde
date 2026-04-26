#!/bin/bash

# This script sources the shared, platform-specific, and user Catkin workspaces.
#
# Usage: source source-catkin-workspaces.bash

################################################################################

# Derive the shared, platform-specific, and user catkin workspace paths.
SDE_SHARED_CATKIN_WS="${SDE_CONTAINER_ROOT_DIR}/ros/sde_catkin_ws"
SDE_ROBOT_PLATFORM_CATKIN_WS="${SDE_CONTAINER_ROOT_DIR}/ros/${SDE_ROBOT_PLATFORM}_catkin_ws"
SDE_USER_CATKIN_WS="${SDE_CONTAINER_ROOT_DIR}/ros/user_catkin_ws"

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

# Source the user Catkin workspace (overlay).
echo "Sourcing the user Catkin workspace from '${SDE_USER_CATKIN_WS}/devel/setup.bash'."
if [ -f ${SDE_USER_CATKIN_WS}/devel/setup.bash ]; then
  source ${SDE_USER_CATKIN_WS}/devel/setup.bash
fi
