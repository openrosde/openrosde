#!/bin/bash

################################################################################

# Kill all ROS nodes.
rosnode kill --all

# Kill 'roscore' and 'rosmaster'.
killall -9 roscore
killall -9 rosmaster
