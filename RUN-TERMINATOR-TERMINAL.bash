#!/bin/bash

# This script runs multiple terminals in a single window using Terminator with a custom layout.
#
# Usage: bash ./RUN-TERMINATOR-TERMINAL.bash [docker-project] [terminator-layout]
#
# [docker-project]:    Used to name the Docker container and create multiple instances if needed.
#                      Default value is '$USER'.
# [terminator-layout]: Used to specify a custom Terminator layout variant.
#                      Default value is 'default-gazebo'.

################################################################################

# Load the OpenRoSDE environment variables.
source ./scripts/load-openrosde-env.bash "$1"

################################################################################

# Pre-start the Docker container before launching Terminator.
# This avoids race conditions when multiple Terminator panes run 'RUN-DOCKER-CONTAINER.bash' simultaneously.
bash ./RUN-DOCKER-CONTAINER.bash "${OPENROSDE_DOCKER_PROJECT}" --no-exec > /dev/null 2>&1 &
wait $!

################################################################################

# Resolve the Terminator layout variant (defaults to 'default-gazebo').
# The argument is the layout variant name (e.g. 'default-gazebo' or 'default-realworld').
# It is prepended with '11-' to form the full layout name suffix (e.g. '11-default-gazebo').
OPENROSDE_TERMINATOR_LAYOUT_ARG=$2
if [ -z "${OPENROSDE_TERMINATOR_LAYOUT_ARG}" ]; then
  OPENROSDE_TERMINATOR_LAYOUT_ARG="default-gazebo"
fi
OPENROSDE_TERMINATOR_LAYOUT="11-${OPENROSDE_TERMINATOR_LAYOUT_ARG}"

################################################################################

# Run Terminator with the selected configuration file and layout after injecting the required environment variables.
# The configuration file of the setup, or else of the platform, lives in the core or in an extension, and its injected copy always goes to './terminator/' of the core.
# Its layouts are named after the platform in either case.
sed "s/\${OPENROSDE_DOCKER_PROJECT}/${OPENROSDE_DOCKER_PROJECT}/g" "$(openrosde-find-setup-file "terminator/%s.config")" > ./terminator/${OPENROSDE_ROBOT_PLATFORM}.config.tmp
terminator --maximise --config ./terminator/${OPENROSDE_ROBOT_PLATFORM}.config.tmp --layout openrosde-${OPENROSDE_ROBOT_PLATFORM}-term-${OPENROSDE_TERMINATOR_LAYOUT}
rm ./terminator/${OPENROSDE_ROBOT_PLATFORM}.config.tmp
sleep 1

################################################################################

# Clear the container shell when returning to the host shell for readability.
clear
