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

# Load the SDE environment variables.
source ./scripts/load-sde-env.bash "$1"

################################################################################

# Run the Docker container in the background.
# Any changes made to './docker/docker-compose*.yaml' will recreate and overwrite the container.
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
  docker exec -i -t ${SDE_DOCKER_CONTAINER} bash -i -c "source ${SDE_CONTAINER_ROOT_DIR}/docker/sde-base/scripts/run-roslaunch-repeatedly.bash $2"
fi
