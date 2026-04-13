#!/bin/bash

# This script downloads from the cloud all the large binary files required at runtime (models, datasets, dictionaries, weights, etc.).
#
# Usage: bash download-model-data.bash

################################################################################

# Print message when there is no data to download.
echo "No additional data requires download at the moment."

################################################################################

# Download required data for the 'package' package.
# SDE_DATA_SERVER_DOMAIN="https://TODO.com"
# SDE_DATA_SERVER_USER="TODO"
# SDE_DATA_SERVER_PASSWORD="TODO"
# SDE_PLATFORM_CATKIN_WS="${SDE_CONTAINER_ROOT_DIR}/ros/${SDE_PLATFORM}_catkin_ws"
# mkdir -p ${SDE_PLATFORM_CATKIN_WS}/src/package/data/download/
# wget --http-user=${SDE_DATA_SERVER_USER} --http-password=${SDE_DATA_SERVER_PASSWORD} ${SDE_DATA_SERVER_DOMAIN}/path/data.ext -N -P ${SDE_PLATFORM_CATKIN_WS}/src/package/data/download # No trailing '/' here.
