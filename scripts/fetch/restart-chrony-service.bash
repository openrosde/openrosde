#!/bin/bash

# This script restarts the Chrony service on the Fetch robot by SSH, as 'RESTART-CHRONY-SERVICE.bash' calls it when 'fetch' is the active platform.
# It runs with every 'OPENROSDE_*' variable exported by 'scripts/load-openrosde-env.bash'.
#
# Usage: bash ./scripts/fetch/restart-chrony-service.bash

################################################################################

# Restart the Chrony service on the robot machine.
OPENROSDE_ROBOT_USER="fetch"
OPENROSDE_ROBOT_PASSWORD="robotics"

echo "Connecting to the robot machine at ${OPENROSDE_ROBOT_USER}@${OPENROSDE_ROBOT_HOSTNAME} via SSH (password required: ${OPENROSDE_ROBOT_PASSWORD})..."

ssh -t -l ${OPENROSDE_ROBOT_USER} ${OPENROSDE_ROBOT_HOSTNAME} 'bash -l -c "
echo \"Restarting the Chrony service on the robot machine (password required: '${OPENROSDE_ROBOT_PASSWORD}')...\";
sudo service chrony restart;
echo \"Waiting for 5 seconds to ensure the Chrony service restarts...\";
sleep 5;
echo \"Checking Chrony service status...\";
sudo systemctl status --no-pager chrony;
chronyc sources;
"'

echo "Chrony service restarted on the robot machine."
