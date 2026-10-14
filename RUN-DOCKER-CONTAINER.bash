#!/bin/bash

# This script runs a Docker container instance with a name based on [docker-project].
#
# Usage: bash ./RUN-DOCKER-CONTAINER.bash [docker-project] [ros-launch] [launch-args...]
#
# [docker-project]: Used to name the Docker container and create multiple instances if needed.
#                   Default value is '$USER'.
# [ros-launch]:     Used to automatically preload a ROS launch file when entering the Docker container for convenience.
#                   Format is 'filename.launch'.
#                   Use '--no-exec' to start the container without entering it.
# [launch-args...]: Optional 'arg:=value' tokens forwarded to 'roslaunch' after the launch file.
#                   They override a launch file argument without modifying the launch file itself
#                   (e.g., 'bash ./RUN-DOCKER-CONTAINER.bash myproject ur5e_teleop_default_realworld.launch input_source:=sightline').

################################################################################

# Load the OpenRoSDE environment variables.
source ./scripts/load-openrosde-env.bash "$1"

################################################################################

# Stop and remove any OpenRoSDE container from a different platform under the same Docker project.
# This allows switching platforms by simply changing '.env.custom' without manual cleanup.
# Uses 'docker compose down' to properly clean up the Docker Compose project state.
OPENROSDE_OTHER_CONTAINERS=$(docker ps -a --format "{{.Names}}" | grep "openrosde-.*-${OPENROSDE_DOCKER_PROJECT}-1" | grep -v "^${OPENROSDE_DOCKER_CONTAINER}$")
if [ -n "${OPENROSDE_OTHER_CONTAINERS}" ]; then
  echo "Switching platform: stopping previous container(s)..."
  docker compose -p ${OPENROSDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml down 2>/dev/null
fi

################################################################################

# Build the list of Docker Compose files.
OPENROSDE_COMPOSE_FILES="-f ./docker/docker-compose.yaml"

# Add the overlay of the platform, then the overlays of the active extensions and the setup, in the order 'scripts/load-extension-paths.bash' lists them.
# Relative paths in an overlay are resolved against './docker/' of the core, as Docker Compose resolves them against the first file.
for OPENROSDE_COMPOSE_OVERLAY_FILE in "${OPENROSDE_COMPOSE_OVERLAY_FILES[@]}"; do
  OPENROSDE_COMPOSE_FILES="${OPENROSDE_COMPOSE_FILES} -f ${OPENROSDE_COMPOSE_OVERLAY_FILE}"
done

# Add the user overlay (always present, ships with OpenRoSDE).
OPENROSDE_COMPOSE_FILES="${OPENROSDE_COMPOSE_FILES} -f ./docker/docker-compose-user.yaml"

# Run the Docker container in the background.
# Any changes made to './docker/docker-compose*.yaml' will recreate and overwrite the container.
if [ -e /proc/driver/nvidia/version ]; then
  # Native Nvidia GPU detected: enable GPU acceleration via Nvidia Container Toolkit.
  docker compose -p ${OPENROSDE_DOCKER_PROJECT} ${OPENROSDE_COMPOSE_FILES} -f ./docker/docker-compose-nvidia.yaml up -d openrosde
elif [ -e /dev/dxg ]; then
  # WSL 2 GPU detected: enable GPU-accelerated rendering via the WSLg D3D12 Mesa driver.
  docker compose -p ${OPENROSDE_DOCKER_PROJECT} ${OPENROSDE_COMPOSE_FILES} -f ./docker/docker-compose-wsl.yaml up -d openrosde
else
  docker compose -p ${OPENROSDE_DOCKER_PROJECT} ${OPENROSDE_COMPOSE_FILES} up -d openrosde
fi

################################################################################

# Configure the known host names with '/etc/hosts' in the Docker container.

if [ -n "${OPENROSDE_ROBOT_HOSTNAME}" ]; then
  OPENROSDE_ROBOT_RESOLVED_HOSTNAME=${OPENROSDE_ROBOT_HOSTNAME}
  echo "Now resolving local host name '${OPENROSDE_ROBOT_RESOLVED_HOSTNAME}'..."
  OPENROSDE_ROBOT_IP=$(avahi-resolve -4 --name ${OPENROSDE_ROBOT_RESOLVED_HOSTNAME} | cut -f 2)
  if [ "$?" != "0" ]; then
    echo "Failed to execute 'avahi-resolve'. You may need to install 'avahi-utils'."
  elif [ ! -z "${OPENROSDE_ROBOT_IP}" ]; then
    echo "Successfully resolved host name '${OPENROSDE_ROBOT_RESOLVED_HOSTNAME}' as '${OPENROSDE_ROBOT_IP}': '/etc/hosts' in the container is automatically updated."
    docker exec -i ${OPENROSDE_DOCKER_CONTAINER} bash <<EOF
sed -n -e '/^[^#[:space:]]*[[:space:]]\+${OPENROSDE_ROBOT_RESOLVED_HOSTNAME}\$/!p' /etc/hosts > /etc/hosts.tmp;
echo '${OPENROSDE_ROBOT_IP} ${OPENROSDE_ROBOT_RESOLVED_HOSTNAME}' >> /etc/hosts.tmp
cp /etc/hosts.tmp /etc/hosts;
EOF
  else
    echo "Failed to resolve host name '${OPENROSDE_ROBOT_RESOLVED_HOSTNAME}': '/etc/hosts' in the container was not automatically updated."
  fi
fi

################################################################################

# Display GUIs through X Server by granting access to Docker.
xhost +local:docker

################################################################################

# Enter the Docker container with a Bash shell (with or without preloading a custom [ros-launch] file).
# Skip entering the container if '--no-exec' is passed as the second argument.
if [ "$2" = "--no-exec" ]; then
  exit 0
elif [ -z "$2" ]; then
  docker exec -i -t ${OPENROSDE_DOCKER_CONTAINER} bash
else
  docker exec -i -t ${OPENROSDE_DOCKER_CONTAINER} bash -i -c "source ${OPENROSDE_CONTAINER_ROOT_DIR}/docker/openrosde-base/scripts/run-roslaunch-repeatedly.bash ${*:2}"
fi
