#!/bin/bash

# This script connects by SSH to the robot and executes the commands to:
# 1. Kill all existing ROS processes inside the robot.
# 2. Execute the launch files that bring up the robot.
#
# Usage: bash BRINGUP-ROS-ROBOT.bash <rosmaster-hostname> [docker-project]
#
# <rosmaster-hostname>: Host name or IP address of the ROS master via 'ROS_MASTER_URI=http://<rosmaster-hostname>:11311'.
# [docker-project]:     Used to name the Docker container and create multiple instances if needed.
#                       Default value is '$USER'.

################################################################################

# Check if the user has provided the mandatory <rosmaster-hostname> argument.
if [[ "$#" -lt 1 ]]; then
  echo "Usage: bash BRINGUP-ROS-ROBOT.bash <rosmaster-hostname> [docker-project]"
  exit 1
fi

################################################################################

# Load the SDE environment variables.
source ./scripts/load-sde-env.bash "$2"

################################################################################

docker exec -i ${SDE_DOCKER_CONTAINER} bash <<EOF
ntpdate ntp.ubuntu.com
EOF

################################################################################

# Platform-specific robot bringup commands.
case "${SDE_PLATFORM}" in
  turtlebot3)
    ssh -f -t -l pi turtlebot3.local 'bash -c "
source /opt/ros/kinetic/setup.bash;
source ~/catkin_ws/devel/setup.bash;
export ROS_MASTER_URI=http://'$1':11311;
export ROS_HOSTNAME=turtlebot3.local;
export TURTLEBOT3_MODEL=waffle_pi;
killall -9 roscore;
killall -9 rosmaster;
sudo /usr/sbin/ntpdate ntp.ubuntu.com;
roslaunch turtlebot3_bringup turtlebot3_robot.launch &
sleep 5;
roslaunch turtlebot3_bringup turtlebot3_rpicamera.launch &
sleep 5;
rosrun image_transport republish compressed in:=/raspicam_node/image image_transport:=compressed raw out:=/raspicam_node/image &
sleep 5;
echo "Done"
"'
    ;;
  ur5e)
    echo "UR5e robot bringup is not yet configured. Please start the robot manually."
    ;;
  *)
    echo "Unknown platform '${SDE_PLATFORM}'. No bringup commands available."
    ;;
esac
