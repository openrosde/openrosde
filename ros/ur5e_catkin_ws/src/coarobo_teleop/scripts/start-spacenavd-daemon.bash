#!/bin/bash

# This script starts the 'spacenavd' daemon if it is not already running.
# It is used as a ROS node to integrate 'spacenavd' startup into roslaunch.

################################################################################

# Start the 'spacenavd' daemon if it is not already running:
if ! pgrep -x spacenavd > /dev/null 2>&1; then
  service spacenavd start
fi

# Keep the node alive until roslaunch shuts it down:
tail -f /dev/null
