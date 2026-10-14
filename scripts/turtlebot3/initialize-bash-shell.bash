#!/bin/bash

# This script sets the shell configuration of the TurtleBot3 platform inside the Docker container.
# 'docker/openrosde-base/scripts/initialize-bash-shell.bash' sources it when 'turtlebot3' is the active platform.
#
# Usage: source ${OPENROSDE_CONTAINER_ROOT_DIR}/scripts/turtlebot3/initialize-bash-shell.bash

################################################################################

# Select the TurtleBot3 model name.
# https://emanual.robotis.com/docs/en/platform/turtlebot3/quick-start/#set-turtlebot3-model-name-1
export TURTLEBOT3_MODEL=waffle_pi
