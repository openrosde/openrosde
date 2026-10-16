#!/bin/bash

# This script kills all ROS nodes as well as 'roscore' and 'rosmaster' still running in the Docker container on ROS 1, or every ROS 2 launch, node, and Gazebo simulation, and the ROS 2 daemon on ROS 2.
#
# Usage: bash kill-ros-nodes.bash

################################################################################

# On ROS 2, which has no master, stop every 'ros2 launch', which stops the nodes it started, then every node left, which runs with '--ros-args', then Gazebo and the daemon.
if [ "${OPENROSDE_ROS_VERSION}" = "2" ]; then
  pkill -INT -f "ros2 launch"
  pkill -f -- "--ros-args"
  pkill -f "gz sim"
  ros2 daemon stop
else
  # Kill all ROS nodes.
  rosnode kill --all

  # Kill 'roscore' and 'rosmaster'.
  killall -9 roscore
  killall -9 rosmaster
fi
