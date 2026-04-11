#!/bin/bash

# This script runs a Docker container instance with a name based on [docker-project].
#
# Usage: bash RUN-DOCKER-CONTAINER.bash [docker-project] [ros-launch]
#
# [docker-project]: Used to name the Docker container and create multiple instances if needed.
#                   Default value is '$USER'.
# [ros-launch]:     Used to automatically preload a ROS launch file when entering the Docker container for convenience.
#                   Format is 'filename.launch'.

################################################################################

# Load the default environment variables from the '.env' file:
source ./.env

# Overwrite the default environment variables with the user's variables from the '.env.custom' file (if it exists):
if [ -f ./.env.custom ]; then
  source ./.env.custom
fi

export SDE_PLATFORM
echo "$0: SDE_PLATFORM=${SDE_PLATFORM}"

################################################################################

# Set the Docker container name from the [docker-project] argument.
# If no [docker-project] is given, use the current user name as the Docker project name.
SDE_DOCKER_PROJECT=$1
if [ -z "${SDE_DOCKER_PROJECT}" ]; then
  SDE_DOCKER_PROJECT=${USER}
fi
SDE_DOCKER_CONTAINER="sde_${SDE_PLATFORM}_${SDE_DOCKER_PROJECT}-1"
echo "$0: SDE_DOCKER_PROJECT=${SDE_DOCKER_PROJECT}"
echo "$0: SDE_DOCKER_CONTAINER=${SDE_DOCKER_CONTAINER}"

################################################################################

# Export current user and group IDs to 'docker-compose.yaml'.
USER_ID="$(id -u)"
GROUP_ID="$(id -g)"
export USER_ID
export GROUP_ID
export SDE_DOCKER_PROJECT

################################################################################

# Run the Docker container in the background.
# Any changes made to './docker/docker-compose*.yml' will recreate and overwrite the container.
if [ -e /proc/driver/nvidia/version ]; then
  docker compose -p ${SDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml -f ./docker/docker-compose-gpu.yaml up -d
else
  docker compose -p ${SDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml up -d
fi

################################################################################

# Configure the known host names with '/etc/hosts' in the Docker container.

if [ -n "${SDE_ROBOT_HOSTNAME}" ]; then
  SDE_ROBOT_RESOLVED_HOSTNAME=${SDE_ROBOT_HOSTNAME}
  echo "Now resolving local host name '${SDE_ROBOT_RESOLVED_HOSTNAME}'..."
  SDE_ROBOT_IP=`avahi-resolve -4 --name ${SDE_ROBOT_RESOLVED_HOSTNAME} | cut -f 2`
  if [ "$?" != "0" ]; then
    echo "Failed to execute 'avahi-resolve'. You may need to install 'avahi-utils'."
  elif [ ! -z "${SDE_ROBOT_IP}" ]; then
    echo "Successfully resolved host name '${SDE_ROBOT_RESOLVED_HOSTNAME}' as '${SDE_ROBOT_IP}': '/etc/hosts' in the container is automatically updated."
    docker exec -i ${SDE_DOCKER_CONTAINER} bash <<EOF
sed -n -e '/^[^#[:space:]]*[[:space:]]\+${SDE_ROBOT_RESOLVED_HOSTNAME}\$/!p' /etc/hosts > /etc/hosts.tmp;
echo '${SDE_ROBOT_IP} ${SDE_ROBOT_RESOLVED_HOSTNAME}' >> /etc/hosts.tmp
cp /etc/hosts.tmp /etc/hosts;
EOF
  else
    echo "Failed to resolve host name '${SDE_ROBOT_RESOLVED_HOSTNAME}': '/etc/hosts' in the container was not automatically updated."
  fi
fi

################################################################################

# Display GUIs through X Server by granting access to Docker.
xhost +local:docker

################################################################################

# Enter the Docker container with a Bash shell (with or without preloading a custom [ros-launch] file).
if [ -z "$2" ]; then
  docker exec -i -t ${SDE_DOCKER_CONTAINER} bash
else
  docker exec -i -t ${SDE_DOCKER_CONTAINER} bash -i -c "source ~/SDE/docker/sde-base/scripts/run-roslaunch-repeatedly.bash $2"
fi
