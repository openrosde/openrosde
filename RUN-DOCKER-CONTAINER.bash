#!/bin/bash

# This script runs a Docker container instance with a name based on [docker-project].
#
# Usage: bash RUN-DOCKER-CONTAINER.bash [docker-project] [ros-launch]
#
# [docker-project]: Used to name the Docker container and create multiple instances if needed. Default value is '$USER'.
# [ros-launch]: Used to automatically preload a ROS launch file when entering the Docker container for convenience. Format is 'filename.launch'.

#################################################################################

# Set the default Docker runtime to use in './docker/docker-compose.yml'.
if [ -e /proc/driver/nvidia/version ]; then
  export DOCKER_RUNTIME=nvidia
else
  export DOCKER_RUNTIME=runc
fi

################################################################################

# Set the Docker container name from the [docker-project] argument.
# If no [docker-project] is given, use the current user name as the Docker project name.
DOCKER_PROJECT=$1
if [ -z "${DOCKER_PROJECT}" ]; then
  DOCKER_PROJECT=${USER}
fi
DOCKER_CONTAINER="${DOCKER_PROJECT}_sde_1"
echo "$0: DOCKER_PROJECT=${DOCKER_PROJECT}"
echo "$0: DOCKER_CONTAINER=${DOCKER_CONTAINER}"

# Run the Docker container in the background.
# Any changes made to './docker/docker-compose.yml' will recreate and overwrite the container.
docker-compose -p ${DOCKER_PROJECT} -f ./docker/docker-compose.yml up -d

################################################################################

# Configure the known host names with '/etc/hosts' in the Docker container.

for i in {1..3}
do
ROBOT_HOSTNAME=turtlebot3-0${i}.local
echo "Now resolving local host name '${ROBOT_HOSTNAME}'..."
ROBOT_IP=`avahi-resolve -4 --name ${ROBOT_HOSTNAME} | cut -f 2`
if [ "$?" != "0" ]; then
  echo "Failed to execute 'avahi-resolve'. You may need to install 'avahi-utils'."
  docker exec -i ${DOCKER_CONTAINER} bash <<EOF
sed -i 's/TMP_HOSTNAME/${ROBOT_HOSTNAME}/' ~/.bashrc
EOF
elif [ ! -z "${ROBOT_IP}" ]; then
  echo "Successfully resolved host name '${ROBOT_HOSTNAME}' as '${ROBOT_IP}': '/etc/hosts' in the container is automatically updated."
  docker exec -i ${DOCKER_CONTAINER} bash <<EOF
sed -i 's/TMP_HOSTNAME/${ROBOT_HOSTNAME}/' ~/.bashrc
sed -n -e '/^[^#[:space:]]*[[:space:]]\+${ROBOT_HOSTNAME}\$/!p' /etc/hosts > /etc/hosts.tmp;
echo '${ROBOT_IP} ${ROBOT_HOSTNAME}' >> /etc/hosts.tmp
cp /etc/hosts.tmp /etc/hosts;
EOF
else
  echo "Failed to resolve host name '${ROBOT_HOSTNAME}': '/etc/hosts' in the container was not automatically updated."
fi
done

################################################################################

# Display GUIs through X Server by granting full access to any external client.
xhost +

################################################################################

# Enter the Docker container with a Bash shell (with or without preloading a custom [ros-launch] file).
case "$2" in
  ( "" )
  docker exec -i -t ${DOCKER_CONTAINER} bash
  ;;
  ( "turtlebot3_robot_bringup_default.launch" | \
    "turtlebot3_robot_bringup_multi.launch" | \
    "turtlebot3_robot_rviz_default.launch" | \
    "turtlebot3_robot_rviz_multi.launch" | \
    "turtlebot3_simulation_gazebo_default.launch" | \
    "turtlebot3_simulation_gazebo_multi.launch" | \
    "turtlebot3_simulation_rviz_default.launch" | \
    "turtlebot3_simulation_rviz_multi.launch" )
  docker exec -i -t ${DOCKER_CONTAINER} bash -i -c "source ~/SDE/docker/sde-devel/scripts/run-roslaunch-repeatedly.bash $2"
  ;;
  ( * )
  echo "Failed to enter the Docker container '${DOCKER_CONTAINER}': '$2' is not a valid argument value."
  ;;
esac
