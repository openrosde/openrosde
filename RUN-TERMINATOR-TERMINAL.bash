#!/bin/bash

# This script runs multiple terminals in a single window using Terminator with a custom layout.
#
# Usage: bash ./RUN-TERMINATOR-TERMINAL.bash [docker-project] [terminator-layout]
#
# [docker-project]:    Used to name the Docker container and create multiple instances if needed.
#                      Default value is '$USER'.
# [terminator-layout]: Used to specify a custom Terminator layout with specific preloaded launch files.

################################################################################

# Load the SDE environment variables.
source ./scripts/load-sde-env.bash "$1"

################################################################################

# Pre-start the Docker container before launching Terminator.
# This avoids race conditions when multiple Terminator panes run 'RUN-DOCKER-CONTAINER.bash' simultaneously.
bash ./RUN-DOCKER-CONTAINER.bash "${SDE_DOCKER_PROJECT}" --no-exec > /dev/null 2>&1 &
wait $!

################################################################################

# Run Terminator with the platform-specific configuration file and layout after injecting the required environment variables.
sed "s/\${SDE_DOCKER_PROJECT}/${SDE_DOCKER_PROJECT}/g" ./terminator/${SDE_ROBOT_PLATFORM}.config > ./terminator/${SDE_ROBOT_PLATFORM}.config.tmp
if [ -z "$2" ]; then
  terminator --maximise --config ./terminator/${SDE_ROBOT_PLATFORM}.config.tmp --layout sde-${SDE_ROBOT_PLATFORM}-term-11-default-gazebo
else
  terminator --maximise --config ./terminator/${SDE_ROBOT_PLATFORM}.config.tmp --layout sde-${SDE_ROBOT_PLATFORM}-term-11-$2
fi
rm ./terminator/${SDE_ROBOT_PLATFORM}.config.tmp
sleep 1

################################################################################

# Clear the container shell when returning to the host shell for readability.
clear
