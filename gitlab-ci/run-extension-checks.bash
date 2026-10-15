#!/bin/bash

# This script runs, inside the container of a setup, the checks that the active extensions hold in 'ci/check-in-container.bash', as part of the CI.
# Each check runs in the order of the active folders, with the setup as its argument, once the Catkin workspaces of the setup are built and sourced, and every check runs even when an earlier one fails.
# 'gitlab-ci/test-catkin-workspaces.bash' disconnects the container from every network before, and 'gitlab-ci/check-no-motion.bash' refuses a check that could move a robot, unless it only launches a simulation that the allowlist of its folder names.
#
# Usage: bash ./gitlab-ci/run-extension-checks.bash <robot-setup>
#
# <robot-setup>: The setup whose extensions to check, selected in '.env.custom', such as 'acme-ur5e-lab', or 'openrosde' for the core alone, which has no extension.

################################################################################

# Load the environment that a shell of the container has: the settings of the setup, ROS, and the workspaces.
source ${OPENROSDE_CONTAINER_ROOT_DIR}/scripts/load-openrosde-settings.bash ${OPENROSDE_CONTAINER_ROOT_DIR}
source /opt/ros/${OPENROSDE_ROS_DISTRO}/setup.bash
source ${OPENROSDE_CONTAINER_ROOT_DIR}/docker/openrosde-base/scripts/source-catkin-workspaces.bash > /dev/null

################################################################################

# Run the check of every active folder other than the core that holds one, and remember the ones that fail.
OPENROSDE_FAILED_EXTENSION_CHECKS=""
OPENROSDE_RUN_CHECK_COUNT=0
for OPENROSDE_EXTENSION_ROOT_DIR in "${OPENROSDE_ACTIVE_ROOT_DIRS[@]:1}"; do
  OPENROSDE_EXTENSION_CHECK_FILE="${OPENROSDE_EXTENSION_ROOT_DIR}/ci/check-in-container.bash"
  if [ -f "${OPENROSDE_EXTENSION_CHECK_FILE}" ]; then
    OPENROSDE_RUN_CHECK_COUNT=$((OPENROSDE_RUN_CHECK_COUNT + 1))
    echo "Running '${OPENROSDE_EXTENSION_CHECK_FILE#${OPENROSDE_CONTAINER_ROOT_DIR}/}' for '$1'..."
    if ! bash "${OPENROSDE_EXTENSION_CHECK_FILE}" "$1" < /dev/null; then
      OPENROSDE_FAILED_EXTENSION_CHECKS="${OPENROSDE_FAILED_EXTENSION_CHECKS}"$'\n'"  - ${OPENROSDE_EXTENSION_CHECK_FILE#${OPENROSDE_CONTAINER_ROOT_DIR}/}"
    fi
  fi
done

################################################################################

# Report the result, and fail if any check failed.
echo "Ran ${OPENROSDE_RUN_CHECK_COUNT} checks of the extensions of '$1'."
if [ -n "${OPENROSDE_FAILED_EXTENSION_CHECKS}" ]; then
  echo "These checks of the extensions failed:${OPENROSDE_FAILED_EXTENSION_CHECKS}"
  exit 1
fi
