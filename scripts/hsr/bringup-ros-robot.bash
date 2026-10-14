#!/bin/bash

# This script explains why the real HSR robot cannot be brought up, as 'BRINGUP-ROS-ROBOT.bash' calls it when 'hsr' is the active platform.
# It runs with every 'OPENROSDE_*' variable exported by 'scripts/load-openrosde-env.bash'.
#
# Usage: bash ./scripts/hsr/bringup-ros-robot.bash <rosmaster-hostname>
#
# <rosmaster-hostname>: Host name or IP address of the ROS master via 'ROS_MASTER_URI=http://<rosmaster-hostname>:11311'.

################################################################################

# Explain why the real HSR cannot be brought up from the open-source OpenRoSDE.
echo "HSR robot bringup is not yet configured. The real HSR requires Toyota's closed-source 'tmc_*' packages, which are not available in this open-source OpenRoSDE."
