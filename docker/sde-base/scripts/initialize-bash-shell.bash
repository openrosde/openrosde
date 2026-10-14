#!/bin/bash

# This script sets up the Bash shell environment inside the Docker container (terminal colors, shell functions, symbolic links, binary paths, environment sourcing, etc.).
# It is appended to '/root/.bashrc' at the end of the Dockerfile and sourced every time the user enters the Bash shell inside the container.
#
# Usage: source initialize-bash-shell.bash

################################################################################

# Load the default environment variables from the '.env' file:
source ${SDE_CONTAINER_ROOT_DIR}/.env

# Overwrite the default environment variables with the user's variables from the '.env.custom' file (if it exists):
if [ -f ${SDE_CONTAINER_ROOT_DIR}/.env.custom ]; then
  source ${SDE_CONTAINER_ROOT_DIR}/.env.custom
fi

# Derive the shared, platform-specific, and user catkin workspace paths.
SDE_SHARED_CATKIN_WS="${SDE_CONTAINER_ROOT_DIR}/ros/sde_catkin_ws"
SDE_ROBOT_PLATFORM_CATKIN_WS="${SDE_CONTAINER_ROOT_DIR}/ros/${SDE_ROBOT_PLATFORM}_catkin_ws"
SDE_USER_CATKIN_WS="${SDE_CONTAINER_ROOT_DIR}/ros/user_catkin_ws"

################################################################################

# Clear the host shell when entering to the container shell for readability.
clear

################################################################################

# Link the default shell 'sh' to Bash.
alias sh='/bin/bash'

################################################################################

# Configure the terminal.

# Disable flow control to prevent accidentally locking the terminal with 'Ctrl+s' (until it is unlocked with 'Ctrl+q').
stty -ixon

################################################################################

# Display the Docker container version.

# TODO: If switched from Dockerfile-sensitive generation to folder-sensitive generation,
# then show latest commit of the platform-devel folder with 'git log -n 1 --format="%h %aN %s %ad" -- $directory'.
SDE_DOCKERFILE_LATEST_HASH=$(git -C ${SDE_CONTAINER_ROOT_DIR}/ log -n 1 --no-merges --pretty=format:%h ./docker/${SDE_ROBOT_PLATFORM}-devel/Dockerfile)
SDE_DOCKERFILE_LATEST_DATE=$(git -C ${SDE_CONTAINER_ROOT_DIR}/ log -n 1 --no-merges --pretty=format:%cd ./docker/${SDE_ROBOT_PLATFORM}-devel/Dockerfile)
SDE_DOCKERFILE_CREATION_DATE=$(git -C ${SDE_CONTAINER_ROOT_DIR}/ show --no-patch --no-notes --pretty='%cd' ${SDE_DOCKER_IMAGE_VERSION})

echo -e "Container version: ${SDE_ROBOT_PLATFORM}-devel:${SDE_DOCKER_IMAGE_VERSION:0:7} from ${SDE_DOCKERFILE_CREATION_DATE}"
if [[ "${SDE_DOCKERFILE_CREATION_DATE}" != "${SDE_DOCKERFILE_LATEST_DATE}" ]]; then
  echo -e "Newer image available: ${SDE_ROBOT_PLATFORM}-devel:${SDE_DOCKERFILE_LATEST_HASH} from ${SDE_DOCKERFILE_LATEST_DATE}"
fi

################################################################################

# Disable ROS end-of-life warning messages.
export DISABLE_ROS1_EOL_WARNINGS=1

# Source the ROS distribution.
echo "Sourcing the ROS distribution from '/opt/ros/noetic/setup.bash'."
source /opt/ros/noetic/setup.bash

# Source the Catkin workspaces.
source ${SDE_CONTAINER_ROOT_DIR}/docker/sde-base/scripts/source-catkin-workspaces.bash

################################################################################

# Add the shared, platform-specific, and user Catkin workspaces to the 'ROS_PACKAGE_PATH'.
export ROS_PACKAGE_PATH=${ROS_PACKAGE_PATH}:${SDE_SHARED_CATKIN_WS}/src/:${SDE_ROBOT_PLATFORM_CATKIN_WS}/src/:${SDE_USER_CATKIN_WS}/src/

################################################################################

# Define Bash functions to conveniently execute the helper scripts in the current shell process.

function sde-source-catkin-workspaces () {
  # Store the current directory and execute scripts in the current shell process.
  pushd .
  source ${SDE_CONTAINER_ROOT_DIR}/docker/sde-base/scripts/source-catkin-workspaces.bash
  popd
}

function sde-build-catkin-workspaces () {
  # Store the current directory and execute scripts in the current shell process.
  pushd .
  source ${SDE_CONTAINER_ROOT_DIR}/docker/sde-base/scripts/build-catkin-workspaces.bash
  source ${SDE_CONTAINER_ROOT_DIR}/docker/sde-base/scripts/fix-permission-issues.bash
  popd
}

function sde-reset-catkin-workspaces () {
  # Store the current directory and execute scripts in the current shell process.
  pushd .
  source ${SDE_CONTAINER_ROOT_DIR}/docker/sde-base/scripts/reset-catkin-workspaces.bash
  source ${SDE_CONTAINER_ROOT_DIR}/docker/sde-base/scripts/fix-permission-issues.bash
  popd
}

function sde-fix-permission-issues () {
  # Store the current directory and execute scripts in the current shell process.
  pushd .
  source ${SDE_CONTAINER_ROOT_DIR}/docker/sde-base/scripts/fix-permission-issues.bash
  popd
}

function sde-download-model-data () {
  # Store the current directory and execute scripts in the current shell process.
  pushd .
  source ${SDE_CONTAINER_ROOT_DIR}/docker/sde-base/scripts/download-model-data.bash
  source ${SDE_CONTAINER_ROOT_DIR}/docker/sde-base/scripts/fix-permission-issues.bash
  popd
}

function sde-initialize-new-container () {
  # Store the current directory and execute scripts in the current shell process.
  pushd .
  source ${SDE_CONTAINER_ROOT_DIR}/docker/sde-base/scripts/download-model-data.bash
  source ${SDE_CONTAINER_ROOT_DIR}/docker/sde-base/scripts/reset-catkin-workspaces.bash
  source ${SDE_CONTAINER_ROOT_DIR}/docker/sde-base/scripts/fix-permission-issues.bash
  popd
}

function sde-cleanup-output-data () {
  # Store the current directory and execute scripts in the current shell process.
  pushd .
  source ${SDE_CONTAINER_ROOT_DIR}/docker/sde-base/scripts/cleanup-output-data.bash
  popd
}

function sde-kill-ros-nodes () {
  # Store the current directory and execute scripts in the current shell process.
  pushd .
  source ${SDE_CONTAINER_ROOT_DIR}/docker/sde-base/scripts/kill-ros-nodes.bash
  popd
}

################################################################################

# Set the ROS network interface.

# Set the ROS master hostname from the '.env' configuration.
export SDE_ROS_MASTER_HOSTNAME=${SDE_ROS_MASTER_HOSTNAME}

# Set 'ROS_IP' with 'SDE_ROS_CLIENT_IP' found in '.env.custom' (if not empty).
if [ -n "${SDE_ROS_CLIENT_IP}" ]; then
  export ROS_IP="${SDE_ROS_CLIENT_IP}"
else
  # Look for the ROS master host name inside the local network and resolve it to get its IP address.
  SDE_ROS_MASTER_IP=$(getent hosts ${SDE_ROS_MASTER_HOSTNAME} | cut -d ' ' -f 1)
  if [ -z "${SDE_ROS_MASTER_IP}" ]; then
    # If no ROS master host name is found, set the local 'ROS_IP' using the default Docker network interface ('docker0').
    export ROS_IP=$(LANG=C /sbin/ifconfig docker0 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*')
  else
    # If the ROS master host name is found, set the local 'ROS_IP' using the network interface that connects to the ROS master.
    # TODO: Use Bash instead of Python.
    export ROS_IP=$(python3 ${SDE_CONTAINER_ROOT_DIR}/docker/sde-base/scripts/print-interface-ip.py ${SDE_ROS_MASTER_IP})
  fi
  if [ -z "${ROS_IP}" ]; then
    # If the local 'ROS_IP' is still empty, default to the Docker network interface ('docker0') for sanity.
    export ROS_IP=$(LANG=C /sbin/ifconfig docker0 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*')
  fi
fi

export ROS_HOME=~/.ros

# Set the ROS master network location.
PS1_DEFAULT="${PS1}"
export local_mode='export ROS_MASTER_URI=http://localhost:11311; echo "Setting local ROS master: ROS_MASTER_URI=${ROS_MASTER_URI}"; echo "Setting local ROS client: ROS_IP=${ROS_IP}"; export PS1="\[\e[44;1;37m\]<local>\[\e[0m\] ${PS1_DEFAULT}"'
export remote_mode='export ROS_MASTER_URI=http://${SDE_ROS_MASTER_HOSTNAME}:11311; echo "Setting remote ROS master: ROS_MASTER_URI=${ROS_MASTER_URI}"; echo "Setting local ROS client: ROS_IP=${ROS_IP}"; export PS1="\[\e[41;1;37m\]<remote>\[\e[0m\] ${PS1_DEFAULT}"'
alias local_mode="${local_mode}"
alias remote_mode="${remote_mode}"

# Set the default ROS network mode based on configuration.
if [ "${SDE_ROS_MASTER_HOSTNAME}" = "localhost" ]; then
  eval ${local_mode}
else
  eval ${remote_mode}
fi

################################################################################

# Set platform-specific configuration.

# Name the launch package of the platform, which every platform calls 'sde_<platform>_launch'.
SDE_LAUNCH_PACKAGE=sde_${SDE_ROBOT_PLATFORM}_launch
export SDE_LAUNCH_PACKAGE

# Source the shell configuration of the platform, 'scripts/${SDE_ROBOT_PLATFORM}/initialize-bash-shell.bash', if the platform has one.
if [ -f ${SDE_CONTAINER_ROOT_DIR}/scripts/${SDE_ROBOT_PLATFORM}/initialize-bash-shell.bash ]; then
  source ${SDE_CONTAINER_ROOT_DIR}/scripts/${SDE_ROBOT_PLATFORM}/initialize-bash-shell.bash
fi

################################################################################

# Move to the working directory.
cd ${SDE_CONTAINER_ROOT_DIR}/
