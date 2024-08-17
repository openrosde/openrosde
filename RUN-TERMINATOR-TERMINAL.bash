#!/bin/bash

# This script runs multiple terminals in a single window using Terminator with a custom layout.
#
# Usage: bash RUN-TERMINATOR-TERMINAL.bash [docker-project] [terminator-layout]
#
# [docker-project]:    Used to name the Docker container and create multiple instances if needed.
#                      Default value is '$USER'.
# [terminator-layout]: Used to specify a custom Terminator layout with specific preloaded launch files.

################################################################################

# Set the Docker container name from the [docker-project] argument.
# If no [docker-project] is given, use the current user name as the Docker project name.
DOCKER_PROJECT=$1
if [ -z "${DOCKER_PROJECT}" ]; then
  DOCKER_PROJECT=${USER}
fi
DOCKER_CONTAINER="${DOCKER_PROJECT}-sde-1"
echo "$0: DOCKER_PROJECT=${DOCKER_PROJECT}"
echo "$0: DOCKER_CONTAINER=${DOCKER_CONTAINER}"

################################################################################

# Run Terminator with a custom configuration file and layout after injecting the required environment variables.
sed "s/\${DOCKER_PROJECT}/${DOCKER_PROJECT}/g" ./terminator/config > ./terminator/config.tmp
if [ -z "$2" ]; then
  terminator --maximise --config ./terminator/config.tmp --layout sde-term-11-default-gazebo
else
  terminator --maximise --config ./terminator/config.tmp --layout sde-term-11-$2
fi
rm ./terminator/config.tmp
sleep 1

################################################################################

# Clear the container shell when returning to the host shell for readability.
clear
