#!/bin/bash

# This script generates a Docker image with the relevant settings for the [docker-project].
#
# Usage: bash ./BUILD-DOCKER-IMAGE.bash [docker-project]
#
# [docker-project]: Used to name the Docker container and control the build strategy.
#                   Special values:
#                   - 'local': Build current platform image with cache (fast iteration on local machine).
#                   Otherwise, try to pull from registry, fall back to build with cache if pull fails.
#                   Default value is '$USER'.

################################################################################

# Load the OpenRoSDE environment variables.
source ./scripts/load-openrosde-env.bash "$1"

################################################################################

# Stop and remove the Docker container if it exists already.
OPENROSDE_EXISTING_DOCKER_CONTAINER_ID=$(docker ps -aq -f name=${OPENROSDE_DOCKER_CONTAINER})
if [ ! -z "${OPENROSDE_EXISTING_DOCKER_CONTAINER_ID}" ]; then
  echo "Stop the container ${OPENROSDE_DOCKER_CONTAINER} with ID: ${OPENROSDE_EXISTING_DOCKER_CONTAINER_ID}."
  docker stop ${OPENROSDE_EXISTING_DOCKER_CONTAINER_ID}
  echo "Remove the container ${OPENROSDE_DOCKER_CONTAINER} with ID: ${OPENROSDE_EXISTING_DOCKER_CONTAINER_ID}."
  docker rm ${OPENROSDE_EXISTING_DOCKER_CONTAINER_ID}
fi

################################################################################

# Determine build strategy based on the Docker project name.
# - 'local': Build current platform image with cache (fast iteration on local machine).
# Otherwise, try to pull from registry, fall back to build with cache if pull fails.
# The CI builds and publishes the base and platform images itself, as 'gitlab-ci/gitlab-ci.yml' describes.
# The Docker layers of the active extensions are built locally on top of the platform image by 'scripts/build-extension-layers.bash', and the script stops if one fails.
if [[ "${OPENROSDE_DOCKER_PROJECT}" == "local" ]]; then
  # Build current platform, extension, and user images with cache (fast rebuild for local development).
  docker compose -p ${OPENROSDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml build openrosde-base
  docker compose -p ${OPENROSDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml build openrosde-platform
  source ./scripts/build-extension-layers.bash "${OPENROSDE_DOCKER_REGISTRY}/${OPENROSDE_ROBOT_PLATFORM}-devel:${OPENROSDE_DOCKER_IMAGE_TAG}" || exit 1
  docker compose -p ${OPENROSDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml build openrosde
else
  # The registry of the public project needs no login, so the images are pulled anonymously.
  # Try to pull from registry, fall back to build with cache if pull fails.
  docker compose -p ${OPENROSDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml pull openrosde-base
  if [[ "$?" -ne "0" ]]; then
    docker compose -p ${OPENROSDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml build openrosde-base
  fi
  docker compose -p ${OPENROSDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml pull openrosde-platform
  if [[ "$?" -ne "0" ]]; then
    docker compose -p ${OPENROSDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml build openrosde-platform
  fi
  # Always build the Docker layers of the active extensions and the user overlay ('openrosde' service) locally on top of the platform image.
  source ./scripts/build-extension-layers.bash "${OPENROSDE_DOCKER_REGISTRY}/${OPENROSDE_ROBOT_PLATFORM}-devel:${OPENROSDE_DOCKER_IMAGE_TAG}" || exit 1
  docker compose -p ${OPENROSDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml build openrosde
fi
