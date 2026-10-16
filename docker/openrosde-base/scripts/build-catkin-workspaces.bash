#!/bin/bash

# This script builds and sources the Catkin workspaces with 'catkin build' on ROS 1, or the colcon workspaces with 'colcon build' on ROS 2, on top of the system ROS environment, in the order 'scripts/load-extension-paths.bash' lists them.
# The order is the shared workspace, the platform workspace, the workspaces of the active extensions, then the user workspace.
# On ROS 2, 'colcon build' copies the files of a package into its install space, without '--symlink-install', since the file service of the robot model refuses a file whose real path leaves the share directory of its package.
#
# Usage: bash build-catkin-workspaces.bash

################################################################################

# List the Catkin workspaces of the core, the platform, and the active extensions, in order.
source ${OPENROSDE_CONTAINER_ROOT_DIR}/scripts/load-extension-paths.bash ${OPENROSDE_CONTAINER_ROOT_DIR}

# Source the ROS distribution environment.
source /opt/ros/${OPENROSDE_ROS_DISTRO}/setup.bash

# Limit the parallel jobs of 'catkin build' to 'OPENROSDE_BUILD_JOBS' when it is set, such as in a CI job that may use only a share of the CPUs, which 'nproc' does not see inside a container.
# The same number caps the packages built at once and the compiler jobs that they share, and an unset or invalid value keeps the defaults of 'catkin build', which use every CPU.
# On ROS 2, the same number caps the packages that 'colcon build' builds at once, and the compiler jobs of each, which 'make' starts only while the load stays below it.
OPENROSDE_CATKIN_BUILD_ARGS=()
OPENROSDE_COLCON_BUILD_ARGS=()
if [[ "${OPENROSDE_BUILD_JOBS}" =~ ^[1-9][0-9]*$ ]]; then
  OPENROSDE_CATKIN_BUILD_ARGS=(--jobs "${OPENROSDE_BUILD_JOBS}" --parallel-packages "${OPENROSDE_BUILD_JOBS}")
  OPENROSDE_COLCON_BUILD_ARGS=(--parallel-workers "${OPENROSDE_BUILD_JOBS}")
  if [ "${OPENROSDE_ROS_VERSION}" = "2" ]; then
    export MAKEFLAGS="-j${OPENROSDE_BUILD_JOBS} -l${OPENROSDE_BUILD_JOBS}"
  fi
elif [ -n "${OPENROSDE_BUILD_JOBS}" ]; then
  echo "Warning: 'OPENROSDE_BUILD_JOBS' is '${OPENROSDE_BUILD_JOBS}', not a positive number, so 'catkin build' uses every CPU."
fi

# Build each Catkin workspace, then source it, so that the next workspace extends it.
# Remember every workspace that fails to build, while the next ones still build.
OPENROSDE_FAILED_CATKIN_WORKSPACES=""
for OPENROSDE_CATKIN_WS in "${OPENROSDE_CATKIN_WORKSPACE_DIRS[@]}"; do
  if [ "${OPENROSDE_ROS_VERSION}" = "2" ]; then
    echo "Building the colcon workspace '${OPENROSDE_CATKIN_WS}'."
    if ! (cd ${OPENROSDE_CATKIN_WS} && colcon build "${OPENROSDE_COLCON_BUILD_ARGS[@]}"); then
      OPENROSDE_FAILED_CATKIN_WORKSPACES="${OPENROSDE_FAILED_CATKIN_WORKSPACES} ${OPENROSDE_CATKIN_WS}"
    fi
    if [ -f ${OPENROSDE_CATKIN_WS}/install/setup.bash ]; then
      source ${OPENROSDE_CATKIN_WS}/install/setup.bash
    fi
    continue
  fi
  echo "Building the Catkin workspace '${OPENROSDE_CATKIN_WS}'."
  if ! (cd ${OPENROSDE_CATKIN_WS} && catkin build "${OPENROSDE_CATKIN_BUILD_ARGS[@]}"); then
    OPENROSDE_FAILED_CATKIN_WORKSPACES="${OPENROSDE_FAILED_CATKIN_WORKSPACES} ${OPENROSDE_CATKIN_WS}"
  fi
  if [ -f ${OPENROSDE_CATKIN_WS}/devel/setup.bash ]; then
    source ${OPENROSDE_CATKIN_WS}/devel/setup.bash
  fi
done

# Source all Catkin workspaces.
source ${OPENROSDE_CONTAINER_ROOT_DIR}/docker/openrosde-base/scripts/source-catkin-workspaces.bash

# Report the workspaces that failed to build, and end with a failure status if any did, which 'reset-catkin-workspaces.bash' and the CI pass on.
if [ -n "${OPENROSDE_FAILED_CATKIN_WORKSPACES}" ]; then
  echo "Failed to build the Catkin workspaces:${OPENROSDE_FAILED_CATKIN_WORKSPACES}"
fi
[ -z "${OPENROSDE_FAILED_CATKIN_WORKSPACES}" ]
