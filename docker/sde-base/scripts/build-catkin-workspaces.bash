#!/bin/bash

# This script builds and sources the Catkin workspaces on top of the system ROS environment, in the order 'scripts/load-extension-paths.bash' lists them.
# The order is the shared workspace, the platform workspace, the workspaces of the active extensions, then the user workspace.
#
# Usage: bash build-catkin-workspaces.bash

################################################################################

# List the Catkin workspaces of the core, the platform, and the active extensions, in order.
source ${SDE_CONTAINER_ROOT_DIR}/scripts/load-extension-paths.bash ${SDE_CONTAINER_ROOT_DIR}

# Source the ROS distribution environment.
source /opt/ros/noetic/setup.bash

# Build each Catkin workspace, then source it, so that the next workspace extends it.
# Remember every workspace that fails to build, while the next ones still build.
SDE_FAILED_CATKIN_WORKSPACES=""
for SDE_CATKIN_WS in "${SDE_CATKIN_WORKSPACE_DIRS[@]}"; do
  echo "Building the Catkin workspace '${SDE_CATKIN_WS}'."
  if ! (cd ${SDE_CATKIN_WS} && catkin build); then
    SDE_FAILED_CATKIN_WORKSPACES="${SDE_FAILED_CATKIN_WORKSPACES} ${SDE_CATKIN_WS}"
  fi
  if [ -f ${SDE_CATKIN_WS}/devel/setup.bash ]; then
    source ${SDE_CATKIN_WS}/devel/setup.bash
  fi
done

# Source all Catkin workspaces.
source ${SDE_CONTAINER_ROOT_DIR}/docker/sde-base/scripts/source-catkin-workspaces.bash

# Report the workspaces that failed to build, and end with a failure status if any did, which 'reset-catkin-workspaces.bash' and the CI pass on.
if [ -n "${SDE_FAILED_CATKIN_WORKSPACES}" ]; then
  echo "Failed to build the Catkin workspaces:${SDE_FAILED_CATKIN_WORKSPACES}"
fi
[ -z "${SDE_FAILED_CATKIN_WORKSPACES}" ]
