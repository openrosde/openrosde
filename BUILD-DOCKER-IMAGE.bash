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

# Build the Docker layers of the active extensions locally, each on top of the previous one, from the platform image up to the parent of the user overlay.
# Each layer is built from the folder of its extension, so that its 'COPY' instructions read from there.
function openrosde-build-extension-images () {
  local OPENROSDE_PARENT_IMAGE_TAG="${OPENROSDE_DOCKER_REGISTRY}/${OPENROSDE_ROBOT_PLATFORM}-devel:${OPENROSDE_DOCKER_IMAGE_TAG}"
  local OPENROSDE_EXTENSION_DOCKERFILE OPENROSDE_EXTENSION_ROOT_DIR OPENROSDE_EXTENSION_IMAGE_TAG
  for OPENROSDE_EXTENSION_DOCKERFILE in "${OPENROSDE_EXTENSION_DOCKERFILES[@]}"; do
    OPENROSDE_EXTENSION_ROOT_DIR="$(dirname "$(dirname "$(dirname "${OPENROSDE_EXTENSION_DOCKERFILE}")")")"
    OPENROSDE_EXTENSION_IMAGE_TAG="${OPENROSDE_DOCKER_REGISTRY}/$(basename "$(dirname "${OPENROSDE_EXTENSION_DOCKERFILE}")"):latest"
    echo "Building ${OPENROSDE_EXTENSION_IMAGE_TAG} on top of ${OPENROSDE_PARENT_IMAGE_TAG}..."
    if ! docker build \
      --build-arg OPENROSDE_PARENT_IMAGE=${OPENROSDE_PARENT_IMAGE_TAG} \
      --build-arg OPENROSDE_DOCKERFILE_COMMIT_SHORT_SHA="$(git -C "${OPENROSDE_EXTENSION_ROOT_DIR}" log -n 1 --pretty=format:%h "${OPENROSDE_EXTENSION_DOCKERFILE}")" \
      -f "${OPENROSDE_EXTENSION_DOCKERFILE}" \
      -t "${OPENROSDE_EXTENSION_IMAGE_TAG}" \
      "${OPENROSDE_EXTENSION_ROOT_DIR}"; then
      echo "Error: The Docker layer '${OPENROSDE_EXTENSION_DOCKERFILE#${OPENROSDE_ROOT_DIR}/}' failed to build, so the user overlay is not built on top of it."
      exit 1
    fi
    OPENROSDE_PARENT_IMAGE_TAG="${OPENROSDE_EXTENSION_IMAGE_TAG}"
  done
}

################################################################################

# Determine build strategy based on the Docker project name.
# - 'local': Build current platform image with cache (fast iteration on local machine).
# Otherwise, try to pull from registry, fall back to build with cache if pull fails.
# The CI builds and publishes the base and platform images itself, as 'gitlab-ci/gitlab-ci.yml' describes.
if [[ "${OPENROSDE_DOCKER_PROJECT}" == "local" ]]; then
  # Build current platform, extension, and user images with cache (fast rebuild for local development).
  docker compose -p ${OPENROSDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml build openrosde-base
  docker compose -p ${OPENROSDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml build openrosde-platform
  openrosde-build-extension-images
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
  openrosde-build-extension-images
  docker compose -p ${OPENROSDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml build openrosde
fi
