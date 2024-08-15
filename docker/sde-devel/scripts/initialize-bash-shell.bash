#!/bin/bash

################################################################################

# Clear the host shell when entering to the container shell for readability.
clear

################################################################################

# Link the default shell 'sh' to Bash.
alias sh='/bin/bash'

################################################################################

# Configure the terminal.

# Disable flow control. If enabled, inputting 'ctrl+s' locks the terminal until inputting 'ctrl+q'.
stty -ixon

################################################################################

# Configure 'umask' for giving read/write/execute permission to group members.
umask 0002

################################################################################

# Display the Docker container version.

# TODO: If switched from Dockerfile-sensitive generation to folder-sensitive generation,
# then show latest commit of the 'sde-devel' folder with 'git log -n 1 --format="%h %aN %s %ad" -- $directory'.
DOCKERFILE_LATEST_HASH=$(git -C /root/SDE/ log -n 1 --no-merges --pretty=format:%h ./docker/sde-devel/Dockerfile)
DOCKERFILE_LATEST_DATE=$(git -C /root/SDE/ log -n 1 --no-merges --pretty=format:%cd ./docker/sde-devel/Dockerfile)
DOCKERFILE_CREATION_DATE=$(git -C /root/SDE/ show --no-patch --no-notes --pretty='%cd' ${DOCKER_IMAGE_VERSION})

echo -e "Container version: sde-devel:${DOCKER_IMAGE_VERSION:0:7} from ${DOCKERFILE_CREATION_DATE}"
if [[ "${DOCKERFILE_CREATION_DATE}" != "${DOCKERFILE_LATEST_DATE}" ]]; then
  echo -e "Newer image available: sde-devel:${DOCKERFILE_LATEST_HASH} from ${DOCKERFILE_LATEST_DATE}"
fi

################################################################################

# Source the ROS distribution.
echo "Sourcing the ROS distribution from '/opt/ros/noetic/setup.bash'."
source /opt/ros/noetic/setup.bash

# Source the Catkin workspace.
echo "Sourcing the Catkin workspace from '/root/SDE/catkin_ws/devel/setup.bash'."
source /root/SDE/catkin_ws/devel/setup.bash

################################################################################

# Add the Catkin workspace to the 'ROS_PACKAGE_PATH'.
export ROS_PACKAGE_PATH=${ROS_PACKAGE_PATH}:/root/SDE/catkin_ws/src/

################################################################################

# Define Bash functions to conveniently execute the helper scripts in the current shell process.

function sde-build-catkin-workspace () {
  # Store the current directory and execute scripts in the current shell process.
  pushd .
  source /root/SDE/docker/sde-devel/scripts/fix-permission-issues.bash
  source /root/SDE/docker/sde-devel/scripts/build-catkin-workspace.bash
  popd
}

function sde-reset-catkin-workspace () {
  # Store the current directory and execute scripts in the current shell process.
  pushd .
  source /root/SDE/docker/sde-devel/scripts/fix-permission-issues.bash
  source /root/SDE/docker/sde-devel/scripts/reset-catkin-workspace.bash
  popd
}

function sde-fix-permission-issues () {
  # Store the current directory and execute scripts in the current shell process.
  pushd .
  source /root/SDE/docker/sde-devel/scripts/fix-permission-issues.bash
  popd
}

function sde-download-model-data () {
  # Store the current directory and execute scripts in the current shell process.
  pushd .
  source /root/SDE/docker/sde-devel/scripts/fix-permission-issues.bash
  source /root/SDE/docker/sde-devel/scripts/download-model-data.bash
  popd
}

function sde-get-fully-started () {
  # Store the current directory and execute scripts in the current shell process.
  pushd .
  source /root/SDE/docker/sde-devel/scripts/fix-permission-issues.bash
  source /root/SDE/docker/sde-devel/scripts/download-model-data.bash
  source /root/SDE/docker/sde-devel/scripts/reset-catkin-workspace.bash
  popd
}

function sde-cleanup-output-data () {
  # Store the current directory and execute scripts in the current shell process.
  pushd .
  source /root/SDE/docker/sde-devel/scripts/cleanup-output-data.bash
  popd
}

################################################################################

# Set the ROS network interface.

# Look for the robot host name inside the local network and resolve it to get its IP address.
# The value of 'ROBOT_HOSTNAME' should be initialized in '~/.bashrc' by './RUN-DOCKER-CONTAINER.bash' when entering the container.
ROBOT_IP=`getent hosts ${ROBOT_HOSTNAME} | cut -d ' ' -f 1`

if [ -z "${ROBOT_IP}" ]; then
  # If no robot host name is found, set the local 'ROS_IP' using the default Docker network interface ('docker0').
  export ROS_IP=$(LANG=C /sbin/ifconfig docker0 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*')
else
  # If the robot host name is found, set the local 'ROS_IP' using the network interface that connects to the robot.
  # TODO: Use Bash instead of Python.
  export ROS_IP=`python3 /root/SDE/docker/sde-devel/scripts/print-interface-ip.py ${ROBOT_IP}`
fi
if [ -z "${ROS_IP}" ]; then
  # If the local 'ROS_IP' is still empty, default to the Docker network interface ('docker0') for sanity.
  export ROS_IP=$(LANG=C /sbin/ifconfig docker0 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*')
fi
echo "ROS_IP is set to '${ROS_IP}'."

export ROS_HOME=~/.ros

PS1_DEFAULT="${PS1}"
export local_mode='export ROS_MASTER_URI=http://localhost:11311; export PS1=" \[\e[44;1;37m\]<local>\[\e[0m\] ${PS1_DEFAULT}"'
export remote_mode='export ROS_MASTER_URI=http://${ROBOT_HOSTNAME}:11311; export PS1="\[\e[41;1;37m\]<remote>\[\e[0m\] ${PS1_DEFAULT}"'

alias local_mode="${local_mode}"
alias remote_mode="${remote_mode}"

eval ${local_mode}

################################################################################

# Select the TurtleBot3 model name.
# https://emanual.robotis.com/docs/en/platform/turtlebot3/quick-start/#set-turtlebot3-model-name-1

export TURTLEBOT3_MODEL=waffle_pi

################################################################################

# Move to the working directory.
cd /root/SDE/
