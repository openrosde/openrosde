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

# Make a backup of the user's original Terminator configuration.
mkdir -p ~/.config/terminator/
if [ ! -f ~/.config/terminator/config.backup ]; then
  cp ~/.config/terminator/config ~/.config/terminator/config.backup
fi

# Update the user's current Terminator configuration with the project's one.
cp ./terminator/config ~/.config/terminator/config

################################################################################

# Run Terminator with the project's custom layout.
if [ -z "$2" ]; then
  terminator -m -l sde-term-11-gazebo
else
  terminator -m -l sde-term-11-$2
fi
sleep 1

################################################################################

# Clear the container shell when returning to the host shell for readability.
clear