#!/bin/bash

# This script downloads from the cloud all the large binary files required at runtime (models, datasets, dictionaries, weights, etc.).
#
# Usage: bash download-model-data.bash

################################################################################

# Print message when there is no data to download.
echo "No additional data requires download at the moment."

################################################################################

# Download required data for the 'package' package.
# OPENROSDE_DATA_SERVER_DOMAIN="https://TODO.com"
# OPENROSDE_DATA_SERVER_USER="TODO"
# OPENROSDE_DATA_SERVER_PASSWORD="TODO"
# OPENROSDE_ROBOT_PLATFORM_CATKIN_WS="${OPENROSDE_CONTAINER_ROOT_DIR}/ros/${OPENROSDE_ROBOT_PLATFORM}_catkin_ws"
# mkdir -p ${OPENROSDE_ROBOT_PLATFORM_CATKIN_WS}/src/package/data/download/
# wget --http-user=${OPENROSDE_DATA_SERVER_USER} --http-password=${OPENROSDE_DATA_SERVER_PASSWORD} ${OPENROSDE_DATA_SERVER_DOMAIN}/path/data.ext -N -P ${OPENROSDE_ROBOT_PLATFORM_CATKIN_WS}/src/package/data/download # No trailing '/' here.
