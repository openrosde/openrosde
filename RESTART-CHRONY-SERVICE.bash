#!/bin/bash

# This script resyncs the host and robot clocks via Chrony.
# Docker containers use the host clock, so their time is accurate if the host clock is.
#
# Usage: bash ./RESTART-CHRONY-SERVICE.bash [docker-project]
#
# [docker-project]: Used to resolve the SDE environment variables.
#                   Default value is '$USER'.

################################################################################

# Load the SDE environment variables.
source ./scripts/load-sde-env.bash "$1"

################################################################################

# Restart the Chrony service on the host machine.

echo "Restarting the Chrony service on the host machine (password required)..."

sudo service chrony restart
echo "Waiting for 5 seconds to ensure the Chrony service restarts..."
sleep 5
echo "Checking Chrony service status..."
sudo systemctl status --no-pager chrony
chronyc sources

echo "Chrony service restarted on the host machine."

################################################################################

# Platform-specific robot Chrony restart commands.
case "${SDE_ROBOT_PLATFORM}" in
  turtlebot3)
    echo "TurtleBot3 Chrony restart is not yet configured."
    ;;
  ur5e)
    echo "UR5e Chrony restart is not yet configured."
    ;;
  fetch)
    SDE_ROBOT_USER="fetch"
    SDE_ROBOT_PASSWORD="robotics"

    echo "Connecting to the robot machine at ${SDE_ROBOT_USER}@${SDE_ROBOT_HOSTNAME} via SSH (password required: ${SDE_ROBOT_PASSWORD})..."

    ssh -t -l ${SDE_ROBOT_USER} ${SDE_ROBOT_HOSTNAME} 'bash -l -c "
echo \"Restarting the Chrony service on the robot machine (password required: '${SDE_ROBOT_PASSWORD}')...\";
sudo service chrony restart;
echo \"Waiting for 5 seconds to ensure the Chrony service restarts...\";
sleep 5;
echo \"Checking Chrony service status...\";
sudo systemctl status --no-pager chrony;
chronyc sources;
"'

    echo "Chrony service restarted on the robot machine."
    ;;
  sciurus17)
    SDE_ROBOT_USER="sciurus"
    SDE_ROBOT_PASSWORD="sciurus"

    echo "Connecting to the robot machine at ${SDE_ROBOT_USER}@${SDE_ROBOT_HOSTNAME} via SSH (password required: ${SDE_ROBOT_PASSWORD})..."

    ssh -t -l ${SDE_ROBOT_USER} ${SDE_ROBOT_HOSTNAME} 'bash -l -c "
echo \"Restarting the Chrony service on the robot machine (password required: '${SDE_ROBOT_PASSWORD}')...\";
sudo service chrony restart;
echo \"Waiting for 5 seconds to ensure the Chrony service restarts...\";
sleep 5;
echo \"Checking Chrony service status...\";
sudo systemctl status --no-pager chrony;
chronyc sources;
"'

    echo "Chrony service restarted on the robot machine."
    ;;
  *)
    echo "Unknown platform '${SDE_ROBOT_PLATFORM}'. No robot Chrony restart commands available."
    ;;
esac
