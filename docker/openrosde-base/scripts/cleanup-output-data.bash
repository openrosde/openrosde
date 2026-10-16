#!/bin/bash

# This script deletes files and data output at runtime to clean up the environment between experiment trials.
#
# Usage: bash cleanup-output-data.bash

################################################################################

# Print message when there is no data to clean up.
echo "No output data requires clean-up at the moment."

################################################################################

# Delete all output data inside the 'package' package.
# OPENROSDE_ROBOT_PLATFORM_CATKIN_WS="${OPENROSDE_CONTAINER_ROOT_DIR}/ros/${OPENROSDE_ROBOT_PLATFORM}_catkin_ws"
# rm -r ${OPENROSDE_ROBOT_PLATFORM_CATKIN_WS}/src/package/data/output/*
