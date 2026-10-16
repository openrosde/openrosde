#!/bin/bash

# This script sources the Catkin workspaces on ROS 1, or the colcon workspaces on ROS 2, in the order 'scripts/load-extension-paths.bash' lists them.
# The order is the shared workspace, the platform workspace, the workspaces of the active extensions, then the user workspace.
#
# Usage: source source-catkin-workspaces.bash

################################################################################

# List the Catkin workspaces of the core, the platform, and the active extensions, in order.
source ${OPENROSDE_CONTAINER_ROOT_DIR}/scripts/load-extension-paths.bash ${OPENROSDE_CONTAINER_ROOT_DIR}

# Source each workspace that has been built, from its devel space on ROS 1, or from its install space on ROS 2.
if [ "${OPENROSDE_ROS_VERSION}" = "2" ]; then
  for OPENROSDE_CATKIN_WS in "${OPENROSDE_CATKIN_WORKSPACE_DIRS[@]}"; do
    echo "Sourcing the colcon workspace from '${OPENROSDE_CATKIN_WS}/install/setup.bash'."
    if [ -f ${OPENROSDE_CATKIN_WS}/install/setup.bash ]; then
      source ${OPENROSDE_CATKIN_WS}/install/setup.bash
    fi
  done
else
  for OPENROSDE_CATKIN_WS in "${OPENROSDE_CATKIN_WORKSPACE_DIRS[@]}"; do
    echo "Sourcing the Catkin workspace from '${OPENROSDE_CATKIN_WS}/devel/setup.bash'."
    if [ -f ${OPENROSDE_CATKIN_WS}/devel/setup.bash ]; then
      source ${OPENROSDE_CATKIN_WS}/devel/setup.bash
    fi
  done
fi
