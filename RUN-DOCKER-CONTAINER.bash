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

# Set the Docker container name from the [docker-project] argument.
# If no [docker-project] is given, use the current user name as the Docker project name.
DOCKER_PROJECT=$1
if [ -z "${DOCKER_PROJECT}" ]; then
  DOCKER_PROJECT=${USER}
fi
DOCKER_CONTAINER="${DOCKER_PROJECT}-sde-1"
echo "$0: DOCKER_PROJECT=${DOCKER_PROJECT}"
echo "$0: DOCKER_CONTAINER=${DOCKER_CONTAINER}"

################################################################################

# Run the Docker container in the background.
# Any changes made to './docker/docker-compose*.yml' will recreate and overwrite the container.
if [ -e /proc/driver/nvidia/version ]; then
  docker compose -p ${DOCKER_PROJECT} -f ./docker/docker-compose.yml -f ./docker/docker-compose-gpu.yml up -d
else
  docker compose -p ${DOCKER_PROJECT} -f ./docker/docker-compose.yml up -d
fi

################################################################################

# Configure the known host names with '/etc/hosts' in the Docker container.

ROBOT_HOSTNAME=turtlebot3.local
echo "Now resolving local host name '${ROBOT_HOSTNAME}'..."
ROBOT_IP=`avahi-resolve -4 --name ${ROBOT_HOSTNAME} | cut -f 2`
if [ "$?" != "0" ]; then
  echo "Failed to execute 'avahi-resolve'. You may need to install 'avahi-utils'."
  docker exec -i ${DOCKER_CONTAINER} bash <<EOF
sed -i 's/REMOTE_HOSTNAME/${ROBOT_HOSTNAME}/' ~/.bashrc
EOF
elif [ ! -z "${ROBOT_IP}" ]; then
  echo "Successfully resolved host name '${ROBOT_HOSTNAME}' as '${ROBOT_IP}': '/etc/hosts' in the container is automatically updated."
  docker exec -i ${DOCKER_CONTAINER} bash <<EOF
sed -i 's/REMOTE_HOSTNAME/${ROBOT_HOSTNAME}/' ~/.bashrc
sed -n -e '/^[^#[:space:]]*[[:space:]]\+${ROBOT_HOSTNAME}\$/!p' /etc/hosts > /etc/hosts.tmp;
echo '${ROBOT_IP} ${ROBOT_HOSTNAME}' >> /etc/hosts.tmp
cp /etc/hosts.tmp /etc/hosts;
EOF
else
  echo "Failed to resolve host name '${ROBOT_HOSTNAME}': '/etc/hosts' in the container was not automatically updated."
fi

################################################################################

# Display GUIs through X Server by granting access to Docker.
xhost +local:docker

################################################################################

# Enter the Docker container with a Bash shell (with or without preloading a custom [ros-launch] file).
if [ -z "$2" ]; then
  docker exec -i -t ${DOCKER_CONTAINER} bash
else
  docker exec -i -t ${DOCKER_CONTAINER} bash -i -c "source ~/SDE/docker/sde-devel/scripts/run-roslaunch-repeatedly.bash $2"
fi
