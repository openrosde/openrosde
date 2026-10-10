#!/bin/bash

# This script connects by SSH to the robot and executes the commands to:
# 1. Kill all existing ROS processes inside the robot.
# 2. Execute the launch files that bring up the robot.
# The commands live in the bringup script of the active platform, 'scripts/<platform>/bringup-ros-robot.bash', if the platform has one.
#
# Usage: bash ./BRINGUP-ROS-ROBOT.bash <rosmaster-hostname> [docker-project]
#
# <rosmaster-hostname>: Host name or IP address of the ROS master via 'ROS_MASTER_URI=http://<rosmaster-hostname>:11311'.
# [docker-project]:     Used to name the Docker container and create multiple instances if needed.
#                       Default value is '$USER'.

################################################################################

# Check if the user has provided the mandatory <rosmaster-hostname> argument.
if [[ "$#" -lt 1 ]]; then
  echo "Usage: bash ./BRINGUP-ROS-ROBOT.bash <rosmaster-hostname> [docker-project]"
  exit 1
fi

################################################################################

# Load the SDE environment variables.
source ./scripts/load-sde-env.bash "$2"

################################################################################

# Run the bringup script of the platform, 'scripts/${SDE_ROBOT_PLATFORM}/bringup-ros-robot.bash', if the platform has one.
SDE_BRINGUP_SCRIPT_PATH="${SDE_ROOT_DIR}/scripts/${SDE_ROBOT_PLATFORM}/bringup-ros-robot.bash"
if [ -f "${SDE_BRINGUP_SCRIPT_PATH}" ]; then
  bash "${SDE_BRINGUP_SCRIPT_PATH}" "$1"
else
  echo "No robot bringup is configured for the '${SDE_ROBOT_PLATFORM}' platform. Please start the robot manually."
fi
