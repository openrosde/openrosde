#!/bin/bash

# This script removes all build artifacts of the Catkin workspaces on ROS 1, or of the colcon workspaces on ROS 2, updates 'rosdep', and cleanly rebuilds and sources the workspaces.
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
# '--rosdistro' limits the download to the package lists of the distribution of the platform only, such as 'noetic', skipping other distros and EOL entries.
rosdep update --rosdistro ${OPENROSDE_ROS_DISTRO}

################################################################################

# Remove all workspace leftovers (all workspaces under 'ros/' of the core on ROS 1, or under 'ros2/' on ROS 2, then the workspaces of the platform and the active extensions).
# The core workspaces appear in both lists, so a workspace already cleaned is skipped.

OPENROSDE_CLEANED_CATKIN_WORKSPACES=" "
for OPENROSDE_WS in ${OPENROSDE_CONTAINER_ROOT_DIR}/${OPENROSDE_ROS_WORKSPACE_FOLDER}/*_${OPENROSDE_ROS_WORKSPACE_SUFFIX} "${OPENROSDE_CATKIN_WORKSPACE_DIRS[@]}"; do
  [ -d "${OPENROSDE_WS}" ] || continue
  [[ "${OPENROSDE_CLEANED_CATKIN_WORKSPACES}" == *" ${OPENROSDE_WS} "* ]] && continue
  OPENROSDE_CLEANED_CATKIN_WORKSPACES="${OPENROSDE_CLEANED_CATKIN_WORKSPACES}${OPENROSDE_WS} "
  echo "Cleaning workspace: ${OPENROSDE_WS}"

  # Delete the 'colcon build' artefacts of a colcon workspace on ROS 2, which needs no initialization.
  if [ "${OPENROSDE_ROS_VERSION}" = "2" ]; then
    cd ${OPENROSDE_WS} && rm -rf build/ install/ log/
    continue
  fi

  # Delete unexpected 'catkin_make' artefacts.
  cd ${OPENROSDE_WS} && rm -rf .catkin_workspace build/ devel/ install/
  cd ${OPENROSDE_WS}/src/ && rm -f CMakeLists.txt

  # Delete expected 'catkin build' artefacts.
  cd ${OPENROSDE_WS} && catkin clean -y 2>/dev/null
  cd ${OPENROSDE_WS} && rm -rf CMakeLists.txt .catkin_tools/
done

################################################################################

# Initialize the shared, platform-specific, extension, and (if present) user workspaces, as Catkin workspaces on ROS 1.

for OPENROSDE_WS in "${OPENROSDE_CATKIN_WORKSPACE_DIRS[@]}"; do
  [ "${OPENROSDE_ROS_VERSION}" = "1" ] || continue
  echo "Initializing workspace: ${OPENROSDE_WS}"
  cd ${OPENROSDE_WS}/src/ && catkin_init_workspace
done

################################################################################

# Build all workspaces (shared, platform-specific, extension, and user).
source ${OPENROSDE_CONTAINER_ROOT_DIR}/docker/openrosde-base/scripts/build-catkin-workspaces.bash
