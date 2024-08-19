#!/bin/bash

################################################################################

# Find files and directories owned by 'root' in path and change ownership to current user and group IDs.
find /root/SDE/ros/catkin_ws/src/ -user root -print -exec chown ${USER_ID}:${GROUP_ID} {} \;
