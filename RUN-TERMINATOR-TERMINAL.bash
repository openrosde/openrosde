#!/bin/bash

# This script runs multiple terminals in a single window using Terminator with a custom layout.
#
# Usage: bash RUN-TERMINATOR-TERMINAL.bash [docker-project] [terminator-layout]
#
# [docker-project]:    Used to name the Docker container and create multiple instances if needed.
#                      Default value is '$USER'.
# [terminator-layout]: Used to specify a custom Terminator layout with specific preloaded launch files.

################################################################################

# Load the default environment variables from the '.env' file:
source ./.env

# Overwrite the default environment variables with the user's variables from the '.env.custom' file (if it exists):
if [ -f ./.env.custom ]; then
  source ./.env.custom
fi

echo "$0: SDE_PLATFORM=${SDE_PLATFORM}"

################################################################################

# Set the Docker container name from the [docker-project] argument.
# If no [docker-project] is given, use the current user name as the Docker project name.
SDE_DOCKER_PROJECT=$1
if [ -z "${SDE_DOCKER_PROJECT}" ]; then
  SDE_DOCKER_PROJECT=${USER}
fi
SDE_DOCKER_CONTAINER="sde_${SDE_PLATFORM}_${SDE_DOCKER_PROJECT}-1"
echo "$0: SDE_DOCKER_PROJECT=${SDE_DOCKER_PROJECT}"
echo "$0: SDE_DOCKER_CONTAINER=${SDE_DOCKER_CONTAINER}"

################################################################################

# Run Terminator with a custom configuration file and layout after injecting the required environment variables.
sed "s/\${SDE_DOCKER_PROJECT}/${SDE_DOCKER_PROJECT}/g" ./terminator/config > ./terminator/config.tmp
if [ -z "$2" ]; then
  terminator --maximise --config ./terminator/config.tmp --layout sde-${SDE_PLATFORM}-term-11-default-gazebo
else
  terminator --maximise --config ./terminator/config.tmp --layout sde-${SDE_PLATFORM}-term-11-$2
fi
rm ./terminator/config.tmp
sleep 1

################################################################################

# Clear the container shell when returning to the host shell for readability.
clear
