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

# Load the SDE environment variables.
source ./scripts/load-sde-env.bash "$1"

################################################################################

# Pre-start the Docker container before launching Terminator.
# This avoids race conditions when multiple Terminator panes run 'RUN-DOCKER-CONTAINER.bash' simultaneously.
bash ./RUN-DOCKER-CONTAINER.bash "${SDE_DOCKER_PROJECT}" --no-exec > /dev/null 2>&1 &
wait $!

################################################################################

# Resolve the Terminator layout variant (defaults to 'default-gazebo').
# The argument is the layout variant name (e.g. 'default-gazebo' or 'default-realworld').
# It is prepended with '11-' to form the full layout name suffix (e.g. '11-default-gazebo').
SDE_TERMINATOR_LAYOUT_ARG=$2
if [ -z "${SDE_TERMINATOR_LAYOUT_ARG}" ]; then
  SDE_TERMINATOR_LAYOUT_ARG="default-gazebo"
fi
SDE_TERMINATOR_LAYOUT="11-${SDE_TERMINATOR_LAYOUT_ARG}"

################################################################################

# Run Terminator with the selected configuration file and layout after injecting the required environment variables.
# The configuration file of the platform lives in the core or in the extension that holds the platform, and its injected copy always goes to './terminator/' of the core.
sed "s/\${SDE_DOCKER_PROJECT}/${SDE_DOCKER_PROJECT}/g" "$(sde-find-extension-file "terminator/${SDE_ROBOT_PLATFORM}.config")" > ./terminator/${SDE_ROBOT_PLATFORM}.config.tmp
terminator --maximise --config ./terminator/${SDE_ROBOT_PLATFORM}.config.tmp --layout sde-${SDE_ROBOT_PLATFORM}-term-${SDE_TERMINATOR_LAYOUT}
rm ./terminator/${SDE_ROBOT_PLATFORM}.config.tmp
sleep 1

################################################################################

# Clear the container shell when returning to the host shell for readability.
clear
