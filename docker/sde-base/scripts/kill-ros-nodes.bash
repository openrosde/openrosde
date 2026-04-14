#!/bin/bash

# This script kills all ROS nodes as well as 'roscore' and 'rosmaster' still running in the Docker container.
#
# Usage: bash kill-ros-nodes.bash

################################################################################

# Kill all ROS nodes.
rosnode kill --all

# Kill 'roscore' and 'rosmaster'.
killall -9 roscore
killall -9 rosmaster
