#!/bin/bash

# This script sources the Catkin workspaces, in the order 'scripts/load-extension-paths.bash' lists them.
# The order is the shared workspace, the platform workspace, the workspaces of the active extensions, then the user workspace.
#
# Usage: source source-catkin-workspaces.bash

################################################################################

# List the Catkin workspaces of the core, the platform, and the active extensions, in order.
source ${OPENROSDE_CONTAINER_ROOT_DIR}/scripts/load-extension-paths.bash ${OPENROSDE_CONTAINER_ROOT_DIR}

# Source each Catkin workspace that has been built.
for OPENROSDE_CATKIN_WS in "${OPENROSDE_CATKIN_WORKSPACE_DIRS[@]}"; do
  echo "Sourcing the Catkin workspace from '${OPENROSDE_CATKIN_WS}/devel/setup.bash'."
  if [ -f ${OPENROSDE_CATKIN_WS}/devel/setup.bash ]; then
    source ${OPENROSDE_CATKIN_WS}/devel/setup.bash
  fi
done
