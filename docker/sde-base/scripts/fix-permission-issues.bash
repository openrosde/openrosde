#!/bin/bash

################################################################################

# Derive the shared and platform-specific catkin workspace paths.
SDE_SHARED_CATKIN_WS="${SDE_CONTAINER_ROOT_DIR}/ros/sde_catkin_ws"
SDE_PLATFORM_CATKIN_WS="${SDE_CONTAINER_ROOT_DIR}/ros/${SDE_PLATFORM:-turtlebot3}_catkin_ws"

# Find files and directories owned by 'root' in all workspaces and change ownership to current user and group IDs.
for SDE_WS in ${SDE_CONTAINER_ROOT_DIR}/ros/*_catkin_ws; do
  [ -d "${SDE_WS}/src/" ] || continue
  find ${SDE_WS}/src/ -user root -print -exec chown ${SDE_USER_ID}:${SDE_GROUP_ID} {} \;
done
