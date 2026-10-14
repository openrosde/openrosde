#!/bin/bash

# This script removes all Catkin workspace build artifacts, installs system dependencies, and cleanly rebuilds and sources the workspaces.
#
# Usage: bash reset-catkin-workspaces.bash

################################################################################

# List the Catkin workspaces of the core, the platform, and the active extensions, in order.
source ${OPENROSDE_CONTAINER_ROOT_DIR}/scripts/load-extension-paths.bash ${OPENROSDE_CONTAINER_ROOT_DIR}

################################################################################

# Download package lists from Ubuntu repositories.
apt-get update

# Install system dependencies required by specific ROS packages.
# http://wiki.ros.org/rosdep
# '--rosdistro noetic' limits the download to the Noetic package lists only, skipping other distros and EOL entries.
rosdep update --rosdistro noetic

################################################################################

# Remove all Catkin workspace leftovers (all workspaces under 'ros/' of the core, then the workspaces of the platform and the active extensions).
# The core workspaces appear in both lists, so a workspace already cleaned is skipped.

OPENROSDE_CLEANED_CATKIN_WORKSPACES=" "
for OPENROSDE_WS in ${OPENROSDE_CONTAINER_ROOT_DIR}/ros/*_catkin_ws "${OPENROSDE_CATKIN_WORKSPACE_DIRS[@]}"; do
  [ -d "${OPENROSDE_WS}" ] || continue
  [[ "${OPENROSDE_CLEANED_CATKIN_WORKSPACES}" == *" ${OPENROSDE_WS} "* ]] && continue
  OPENROSDE_CLEANED_CATKIN_WORKSPACES="${OPENROSDE_CLEANED_CATKIN_WORKSPACES}${OPENROSDE_WS} "
  echo "Cleaning workspace: ${OPENROSDE_WS}"

  # Delete unexpected 'catkin_make' artefacts.
  cd ${OPENROSDE_WS} && rm -rf .catkin_workspace build/ devel/ install/
  cd ${OPENROSDE_WS}/src/ && rm -f CMakeLists.txt

  # Delete expected 'catkin build' artefacts.
  cd ${OPENROSDE_WS} && catkin clean -y 2>/dev/null
  cd ${OPENROSDE_WS} && rm -rf CMakeLists.txt .catkin_tools/
done

################################################################################

# Initialize the shared, platform-specific, extension, and (if present) user workspaces.

for OPENROSDE_WS in "${OPENROSDE_CATKIN_WORKSPACE_DIRS[@]}"; do
  echo "Initializing workspace: ${OPENROSDE_WS}"
  cd ${OPENROSDE_WS}/src/ && catkin_init_workspace
done

################################################################################

# Build all workspaces (shared, platform-specific, extension, and user).
source ${OPENROSDE_CONTAINER_ROOT_DIR}/docker/openrosde-base/scripts/build-catkin-workspaces.bash
