#!/bin/bash

# This script generates a Docker image with the relevant settings for the [docker-project].
#
# Usage: bash ./BUILD-DOCKER-IMAGE.bash [docker-project]
#
# [docker-project]: Used to name the Docker container and control the build strategy.
#                   Special values:
#                   - 'gitlab-ci': Build all platform images without cache (CI/CD pipeline).
#                   - 'local': Build current platform image with cache (fast iteration on local machine).
#                   Otherwise, try to pull from registry, fall back to build with cache if pull fails.
#                   Default value is '$USER'.

################################################################################

# Load the SDE environment variables.
source ./scripts/load-sde-env.bash "$1"

################################################################################

# Stop and remove the Docker container if it exists already.
SDE_EXISTING_DOCKER_CONTAINER_ID=$(docker ps -aq -f name=${SDE_DOCKER_CONTAINER})
if [ ! -z "${SDE_EXISTING_DOCKER_CONTAINER_ID}" ]; then
  echo "Stop the container ${SDE_DOCKER_CONTAINER} with ID: ${SDE_EXISTING_DOCKER_CONTAINER_ID}."
  docker stop ${SDE_EXISTING_DOCKER_CONTAINER_ID}
  echo "Remove the container ${SDE_DOCKER_CONTAINER} with ID: ${SDE_EXISTING_DOCKER_CONTAINER_ID}."
  docker rm ${SDE_EXISTING_DOCKER_CONTAINER_ID}
fi

################################################################################

# Build the Docker layers of the active extensions locally, each on top of the previous one, from the platform image up to the parent of the user overlay.
# Each layer is built from the folder of its extension, so that its 'COPY' instructions read from there.
function sde-build-extension-images () {
  local SDE_PARENT_IMAGE_TAG="${SDE_DOCKER_REGISTRY}/${SDE_ROBOT_PLATFORM}-devel:latest"
  local SDE_EXTENSION_DOCKERFILE SDE_EXTENSION_ROOT_DIR SDE_EXTENSION_IMAGE_TAG
  for SDE_EXTENSION_DOCKERFILE in "${SDE_EXTENSION_DOCKERFILES[@]}"; do
    SDE_EXTENSION_ROOT_DIR="$(dirname "$(dirname "$(dirname "${SDE_EXTENSION_DOCKERFILE}")")")"
    SDE_EXTENSION_IMAGE_TAG="${SDE_DOCKER_REGISTRY}/$(basename "$(dirname "${SDE_EXTENSION_DOCKERFILE}")"):latest"
    echo "Building ${SDE_EXTENSION_IMAGE_TAG} on top of ${SDE_PARENT_IMAGE_TAG}..."
    if ! docker build \
      --build-arg SDE_PARENT_IMAGE=${SDE_PARENT_IMAGE_TAG} \
      --build-arg SDE_DOCKERFILE_COMMIT_SHORT_SHA="$(git -C "${SDE_EXTENSION_ROOT_DIR}" log -n 1 --pretty=format:%h "${SDE_EXTENSION_DOCKERFILE}")" \
      -f "${SDE_EXTENSION_DOCKERFILE}" \
      -t "${SDE_EXTENSION_IMAGE_TAG}" \
      "${SDE_EXTENSION_ROOT_DIR}"; then
      echo "Error: The Docker layer '${SDE_EXTENSION_DOCKERFILE#${SDE_ROOT_DIR}/}' failed to build, so the user overlay is not built on top of it."
      exit 1
    fi
    SDE_PARENT_IMAGE_TAG="${SDE_EXTENSION_IMAGE_TAG}"
  done
}

################################################################################

# Determine build strategy based on the Docker project name.
# - 'gitlab-ci': Build all platform images without cache (CI/CD pipeline).
# - 'local': Build current platform image with cache (fast iteration on local machine).
# Otherwise, try to pull from registry, fall back to build with cache if pull fails.
if [[ "${SDE_DOCKER_PROJECT}" == "gitlab-ci" ]]; then
  # Build all platform images from scratch without cache.
  # The platforms are found by name, as 'scripts/list-robot-platforms.bash' lists them.
  # The user overlay ('sde' service) is built locally on top of each platform, without the Docker layers of extensions, which belong to a setup.
  docker compose -p ${SDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml build sde-base --no-cache
  for SDE_PLATFORM in $(bash ./scripts/list-robot-platforms.bash); do
    export SDE_ROBOT_PLATFORM=${SDE_PLATFORM}
    sde-derive-platform-dockerfile "${SDE_ROBOT_PLATFORM}"
    echo "Building ${SDE_ROBOT_PLATFORM}-devel image..."
    docker compose -p ${SDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml build sde-platform --no-cache
    echo "Building user-devel image on top of ${SDE_ROBOT_PLATFORM}-devel..."
    export SDE_USER_PARENT_IMAGE="${SDE_DOCKER_REGISTRY}/${SDE_ROBOT_PLATFORM}-devel:latest"
    docker compose -p ${SDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml build sde --no-cache
  done
elif [[ "${SDE_DOCKER_PROJECT}" == "local" ]]; then
  # Build current platform, extension, and user images with cache (fast rebuild for local development).
  docker compose -p ${SDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml build sde-base
  docker compose -p ${SDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml build sde-platform
  sde-build-extension-images
  docker compose -p ${SDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml build sde
else
  # The registry of the public project needs no login, so the images are pulled anonymously.
  # Try to pull from registry, fall back to build with cache if pull fails.
  docker compose -p ${SDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml pull sde-base
  if [[ "$?" -ne "0" ]]; then
    docker compose -p ${SDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml build sde-base
  fi
  docker compose -p ${SDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml pull sde-platform
  if [[ "$?" -ne "0" ]]; then
    docker compose -p ${SDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml build sde-platform
  fi
  # Always build the Docker layers of the active extensions and the user overlay ('sde' service) locally on top of the platform image.
  sde-build-extension-images
  docker compose -p ${SDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml build sde
fi
