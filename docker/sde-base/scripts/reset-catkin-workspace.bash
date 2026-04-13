#!/bin/bash

# This script removes all Catkin workspace build artifacts, installs system dependencies, and cleanly rebuilds and sources the workspaces.
#
# Usage: bash reset-catkin-workspace.bash

################################################################################

# Derive the shared and platform-specific catkin workspace paths.
SDE_SHARED_CATKIN_WS="${SDE_CONTAINER_ROOT_DIR}/ros/sde_catkin_ws"
SDE_PLATFORM_CATKIN_WS="${SDE_CONTAINER_ROOT_DIR}/ros/${SDE_PLATFORM:-turtlebot3}_catkin_ws"

################################################################################

# Download package lists from Ubuntu repositories.
apt-get update

# Install system dependencies required by specific ROS packages.
# http://wiki.ros.org/rosdep
rosdep update --include-eol-distros

################################################################################

# Remove all Catkin workspace leftovers (all workspaces under ros/).

for SDE_WS in ${SDE_CONTAINER_ROOT_DIR}/ros/*_catkin_ws; do
  [ -d "${SDE_WS}" ] || continue
  echo "Cleaning workspace: ${SDE_WS}"

  # Delete unexpected 'catkin_make' artefacts.
  cd ${SDE_WS} && rm -rf .catkin_workspace build/ devel/ install/
  cd ${SDE_WS}/src/ && rm -f CMakeLists.txt

  # Delete expected 'catkin build' artefacts.
  cd ${SDE_WS} && catkin clean -y 2>/dev/null
  cd ${SDE_WS} && rm -rf CMakeLists.txt .catkin_tools/
done

################################################################################

# Initialize and build only the shared and platform-specific workspaces.

for SDE_WS in "${SDE_SHARED_CATKIN_WS}" "${SDE_PLATFORM_CATKIN_WS}"; do
  echo "Initializing workspace: ${SDE_WS}"
  cd ${SDE_WS}/src/ && catkin_init_workspace
done

################################################################################

# Build both workspaces.
source ${SDE_CONTAINER_ROOT_DIR}/docker/sde-base/scripts/build-catkin-workspace.bash
