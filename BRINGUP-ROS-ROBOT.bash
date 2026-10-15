#!/bin/bash

# This script connects by SSH to the robot and executes the commands to:
# 1. Kill all existing ROS processes inside the robot.
# 2. Execute the launch files that bring up the robot.
# The commands live in the bringup script of the active setup or platform, 'scripts/<setup>/bringup-ros-robot.bash' or 'scripts/<platform>/bringup-ros-robot.bash', if it has one.
#
# Usage: bash ./BRINGUP-ROS-ROBOT.bash <rosmaster-hostname> [docker-project]
#
# <rosmaster-hostname>: Host name or IP address of the ROS master via 'ROS_MASTER_URI=http://<rosmaster-hostname>:11311'.
#                       A platform on ROS 2, which has no master, passes it to its bringup script, which may ignore it.
# [docker-project]:     Used to name the Docker container and create multiple instances if needed.
#                       Default value is '$USER'.

################################################################################

# Check if the user has provided the mandatory <rosmaster-hostname> argument.
if [[ "$#" -lt 1 ]]; then
  echo "Usage: bash ./BRINGUP-ROS-ROBOT.bash <rosmaster-hostname> [docker-project]"
  exit 1
fi

################################################################################

# Load the OpenRoSDE environment variables.
source ./scripts/load-openrosde-env.bash "$2"

################################################################################

# Run the bringup script of the setup, or else of the platform, in the core or in an extension, if either has one.
OPENROSDE_BRINGUP_SCRIPT_PATH="$(openrosde-find-setup-file "scripts/%s/bringup-ros-robot.bash")"
if [ -n "${OPENROSDE_BRINGUP_SCRIPT_PATH}" ]; then
  bash "${OPENROSDE_BRINGUP_SCRIPT_PATH}" "$1"
else
  echo "No robot bringup is configured for the '${OPENROSDE_ROBOT_PLATFORM}' platform. Please start the robot manually."
fi
