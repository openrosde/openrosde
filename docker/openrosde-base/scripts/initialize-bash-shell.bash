#!/bin/bash

# This script sets up the Bash shell environment inside the Docker container (terminal colors, shell functions, symbolic links, binary paths, environment sourcing, etc.).
# It is appended to '/root/.bashrc' at the end of the Dockerfile and sourced every time the user enters the Bash shell inside the container.
#
# Usage: source initialize-bash-shell.bash

################################################################################

# Load the default environment variables from the '.env' file:
source ${OPENROSDE_CONTAINER_ROOT_DIR}/.env

# Overwrite the default environment variables with the user's variables from the '.env.custom' file (if it exists):
source ${OPENROSDE_CONTAINER_ROOT_DIR}/scripts/load-env-custom.bash ${OPENROSDE_CONTAINER_ROOT_DIR}

# Resolve where the files of the platform and of the extensions live, and list their Catkin workspaces in order.
source ${OPENROSDE_CONTAINER_ROOT_DIR}/scripts/load-extension-paths.bash ${OPENROSDE_CONTAINER_ROOT_DIR}

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
OPENROSDE_DOCKERFILE_LATEST_HASH=$(git -C ${OPENROSDE_ROBOT_PLATFORM_ROOT_DIR}/ log -n 1 --no-merges --pretty=format:%h ./docker/${OPENROSDE_ROBOT_PLATFORM}-devel/Dockerfile)
OPENROSDE_DOCKERFILE_LATEST_DATE=$(git -C ${OPENROSDE_ROBOT_PLATFORM_ROOT_DIR}/ log -n 1 --no-merges --pretty=format:%cd ./docker/${OPENROSDE_ROBOT_PLATFORM}-devel/Dockerfile)

# Compare the dates only when the repository of the platform holds the commit embedded in the image, which a platform outside the core or a clone without that commit does not, so that no false 'Newer image available' is shown.
if git -C ${OPENROSDE_ROBOT_PLATFORM_ROOT_DIR}/ cat-file -e "${OPENROSDE_DOCKER_IMAGE_VERSION}^{commit}" 2>/dev/null; then
  OPENROSDE_DOCKERFILE_CREATION_DATE=$(git -C ${OPENROSDE_ROBOT_PLATFORM_ROOT_DIR}/ show --no-patch --no-notes --pretty='%cd' ${OPENROSDE_DOCKER_IMAGE_VERSION})
  echo -e "Container version: ${OPENROSDE_ROBOT_PLATFORM}-devel:${OPENROSDE_DOCKER_IMAGE_VERSION:0:7} from ${OPENROSDE_DOCKERFILE_CREATION_DATE}"
  if [[ "${OPENROSDE_DOCKERFILE_CREATION_DATE}" != "${OPENROSDE_DOCKERFILE_LATEST_DATE}" ]]; then
    echo -e "Newer image available: ${OPENROSDE_ROBOT_PLATFORM}-devel:${OPENROSDE_DOCKERFILE_LATEST_HASH} from ${OPENROSDE_DOCKERFILE_LATEST_DATE}"
  fi
else
  echo -e "Container version: ${OPENROSDE_ROBOT_PLATFORM}-devel:${OPENROSDE_DOCKER_IMAGE_VERSION:0:7}"
fi

################################################################################

# Disable ROS end-of-life warning messages.
export DISABLE_ROS1_EOL_WARNINGS=1

# Source the ROS distribution.
echo "Sourcing the ROS distribution from '/opt/ros/noetic/setup.bash'."
source /opt/ros/noetic/setup.bash

# Source the Catkin workspaces.
source ${OPENROSDE_CONTAINER_ROOT_DIR}/docker/openrosde-base/scripts/source-catkin-workspaces.bash

################################################################################

# Add the shared, platform-specific, extension, and user Catkin workspaces to the 'ROS_PACKAGE_PATH'.
for OPENROSDE_CATKIN_WS in "${OPENROSDE_CATKIN_WORKSPACE_DIRS[@]}"; do
  export ROS_PACKAGE_PATH=${ROS_PACKAGE_PATH}:${OPENROSDE_CATKIN_WS}/src/
done

################################################################################

# Define Bash functions to conveniently execute the helper scripts in the current shell process.

function openrosde-source-catkin-workspaces () {
  # Store the current directory and execute scripts in the current shell process.
  pushd .
  source ${OPENROSDE_CONTAINER_ROOT_DIR}/docker/openrosde-base/scripts/source-catkin-workspaces.bash
  popd
}

function openrosde-build-catkin-workspaces () {
  # Store the current directory and execute scripts in the current shell process.
  pushd .
  source ${OPENROSDE_CONTAINER_ROOT_DIR}/docker/openrosde-base/scripts/build-catkin-workspaces.bash
  source ${OPENROSDE_CONTAINER_ROOT_DIR}/docker/openrosde-base/scripts/fix-permission-issues.bash
  popd
}

function openrosde-reset-catkin-workspaces () {
  # Store the current directory and execute scripts in the current shell process.
  pushd .
  source ${OPENROSDE_CONTAINER_ROOT_DIR}/docker/openrosde-base/scripts/reset-catkin-workspaces.bash
  source ${OPENROSDE_CONTAINER_ROOT_DIR}/docker/openrosde-base/scripts/fix-permission-issues.bash
  popd
}

function openrosde-fix-permission-issues () {
  # Store the current directory and execute scripts in the current shell process.
  pushd .
  source ${OPENROSDE_CONTAINER_ROOT_DIR}/docker/openrosde-base/scripts/fix-permission-issues.bash
  popd
}

function openrosde-download-model-data () {
  # Store the current directory and execute scripts in the current shell process.
  pushd .
  source ${OPENROSDE_CONTAINER_ROOT_DIR}/docker/openrosde-base/scripts/download-model-data.bash
  source ${OPENROSDE_CONTAINER_ROOT_DIR}/docker/openrosde-base/scripts/fix-permission-issues.bash
  popd
}

function openrosde-initialize-new-container () {
  # Store the current directory and execute scripts in the current shell process.
  pushd .
  source ${OPENROSDE_CONTAINER_ROOT_DIR}/docker/openrosde-base/scripts/download-model-data.bash
  source ${OPENROSDE_CONTAINER_ROOT_DIR}/docker/openrosde-base/scripts/reset-catkin-workspaces.bash
  source ${OPENROSDE_CONTAINER_ROOT_DIR}/docker/openrosde-base/scripts/fix-permission-issues.bash
  popd
}

function openrosde-cleanup-output-data () {
  # Store the current directory and execute scripts in the current shell process.
  pushd .
  source ${OPENROSDE_CONTAINER_ROOT_DIR}/docker/openrosde-base/scripts/cleanup-output-data.bash
  popd
}

function openrosde-kill-ros-nodes () {
  # Store the current directory and execute scripts in the current shell process.
  pushd .
  source ${OPENROSDE_CONTAINER_ROOT_DIR}/docker/openrosde-base/scripts/kill-ros-nodes.bash
  popd
}

################################################################################

# Set the ROS network interface.

# Set the ROS master hostname from the '.env' configuration.
export OPENROSDE_ROS_MASTER_HOSTNAME=${OPENROSDE_ROS_MASTER_HOSTNAME}

# Set 'ROS_IP' with 'OPENROSDE_ROS_CLIENT_IP' found in '.env.custom' (if not empty).
if [ -n "${OPENROSDE_ROS_CLIENT_IP}" ]; then
  export ROS_IP="${OPENROSDE_ROS_CLIENT_IP}"
else
  # Look for the ROS master host name inside the local network and resolve it to get its IP address.
  OPENROSDE_ROS_MASTER_IP=$(getent hosts ${OPENROSDE_ROS_MASTER_HOSTNAME} | cut -d ' ' -f 1)
  if [ -z "${OPENROSDE_ROS_MASTER_IP}" ]; then
    # If no ROS master host name is found, set the local 'ROS_IP' using the default Docker network interface ('docker0').
    export ROS_IP=$(LANG=C /sbin/ifconfig docker0 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*')
  else
    # If the ROS master host name is found, set the local 'ROS_IP' using the network interface that connects to the ROS master.
    # TODO: Use Bash instead of Python.
    export ROS_IP=$(python3 ${OPENROSDE_CONTAINER_ROOT_DIR}/docker/openrosde-base/scripts/print-interface-ip.py ${OPENROSDE_ROS_MASTER_IP})
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
export remote_mode='export ROS_MASTER_URI=http://${OPENROSDE_ROS_MASTER_HOSTNAME}:11311; echo "Setting remote ROS master: ROS_MASTER_URI=${ROS_MASTER_URI}"; echo "Setting local ROS client: ROS_IP=${ROS_IP}"; export PS1="\[\e[41;1;37m\]<remote>\[\e[0m\] ${PS1_DEFAULT}"'
alias local_mode="${local_mode}"
alias remote_mode="${remote_mode}"

# Set the default ROS network mode based on configuration.
if [ "${OPENROSDE_ROS_MASTER_HOSTNAME}" = "localhost" ]; then
  eval ${local_mode}
else
  eval ${remote_mode}
fi

################################################################################

# Set platform-specific configuration.

# Name the launch package of the platform, which every platform calls 'openrosde_<platform>_launch'.
OPENROSDE_LAUNCH_PACKAGE=openrosde_${OPENROSDE_ROBOT_PLATFORM}_launch
export OPENROSDE_LAUNCH_PACKAGE

# Source the shell configuration of the setup, or else of the platform, 'scripts/<setup or platform>/initialize-bash-shell.bash' in the core or in an extension, if either has one.
OPENROSDE_SHELL_SCRIPT_PATH="$(openrosde-find-setup-file "scripts/%s/initialize-bash-shell.bash")"
if [ -n "${OPENROSDE_SHELL_SCRIPT_PATH}" ]; then
  source ${OPENROSDE_SHELL_SCRIPT_PATH}
fi

################################################################################

# Move to the working directory.
cd ${OPENROSDE_CONTAINER_ROOT_DIR}/
