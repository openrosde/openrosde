#!/bin/bash

# This script resyncs the host and robot clocks via Chrony.
# Docker containers use the host clock, so their time is accurate if the host clock is.
# The robot side lives in the Chrony script of the active platform, 'scripts/<platform>/restart-chrony-service.bash', if the platform has one.
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

# Run the Chrony script of the platform, 'scripts/${SDE_ROBOT_PLATFORM}/restart-chrony-service.bash' in the core or in an extension, if the platform has one.
SDE_CHRONY_SCRIPT_PATH="$(sde-find-extension-file "scripts/${SDE_ROBOT_PLATFORM}/restart-chrony-service.bash")"
if [ -n "${SDE_CHRONY_SCRIPT_PATH}" ]; then
  bash "${SDE_CHRONY_SCRIPT_PATH}"
else
  echo "No robot Chrony restart is configured for the '${SDE_ROBOT_PLATFORM}' platform."
fi
