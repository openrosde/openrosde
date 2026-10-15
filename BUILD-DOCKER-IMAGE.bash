#!/bin/bash

# This script generates a Docker image with the relevant settings for the [docker-project].
#
# Usage: bash ./BUILD-DOCKER-IMAGE.bash [docker-project]
#
# [docker-project]: Used to name the Docker container and control the build strategy.
#                   Special values:
#                   - 'local': Build current platform image with cache (fast iteration on local machine).
#                   Otherwise, try to pull from registry, fall back to build with cache if pull fails, as far as 'OPENROSDE_DOCKER_BUILD_FALLBACK' allows.
#                   Default value is '$USER'.

################################################################################

# Load the OpenRoSDE environment variables.
source ./scripts/load-openrosde-env.bash "$1"

# Check that 'OPENROSDE_DOCKER_BUILD_FALLBACK' names which images may be built when their pull fails, before anything is stopped or pulled.
if [ "${OPENROSDE_DOCKER_BUILD_FALLBACK}" != "true" ] && [ "${OPENROSDE_DOCKER_BUILD_FALLBACK}" != "platform" ] && [ "${OPENROSDE_DOCKER_BUILD_FALLBACK}" != "false" ]; then
  echo "Error: 'OPENROSDE_DOCKER_BUILD_FALLBACK' is '${OPENROSDE_DOCKER_BUILD_FALLBACK}', but it must be 'true', 'platform', or 'false'."
  exit 1
fi

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
# Otherwise, try to pull from registry, fall back to build with cache if pull fails, as far as 'OPENROSDE_DOCKER_BUILD_FALLBACK' allows.
# The CI builds and publishes the base and platform images itself, as 'gitlab-ci/gitlab-ci.yml' describes.
# The Docker layers of the active extensions are built locally on top of the platform image by 'scripts/build-extension-layers.bash', and the script stops if one fails.
if [[ "${OPENROSDE_DOCKER_PROJECT}" == "local" ]]; then
  # Build current platform, extension, and user images with cache (fast rebuild for local development).
  docker compose -p ${OPENROSDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml build openrosde-base
  docker compose -p ${OPENROSDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml build openrosde-mesh2glb
  docker compose -p ${OPENROSDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml build openrosde-platform
  source ./scripts/build-extension-layers.bash "${OPENROSDE_DOCKER_REGISTRY}/${OPENROSDE_ROBOT_PLATFORM}-devel:${OPENROSDE_DOCKER_IMAGE_TAG}" || exit 1
  docker compose -p ${OPENROSDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml build openrosde
else
  # The registry of the public project needs no login, so the images are pulled anonymously.
  # Try to pull from registry, fall back to build with cache if pull fails: the base image only with 'OPENROSDE_DOCKER_BUILD_FALLBACK=true', and the platform image with 'true' or 'platform'.
  # Otherwise a failed pull stops the script, so that a CI job fails rather than building the base image for hours.
  docker compose -p ${OPENROSDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml pull openrosde-base
  if [[ "$?" -ne "0" ]]; then
    if [ "${OPENROSDE_DOCKER_BUILD_FALLBACK}" != "true" ]; then
      echo "Error: The pull of '${OPENROSDE_DOCKER_REGISTRY}/${OPENROSDE_BASE_IMAGE_NAME}:${OPENROSDE_DOCKER_IMAGE_TAG}' failed, and 'OPENROSDE_DOCKER_BUILD_FALLBACK=${OPENROSDE_DOCKER_BUILD_FALLBACK}' does not build it locally."
      exit 1
    fi
    docker compose -p ${OPENROSDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml build openrosde-base
  fi
  # The converter of robot meshes is small, so it is built whenever its pull fails, unless 'OPENROSDE_DOCKER_BUILD_FALLBACK=false' forbids every build.
  docker compose -p ${OPENROSDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml pull openrosde-mesh2glb
  if [[ "$?" -ne "0" ]]; then
    if [ "${OPENROSDE_DOCKER_BUILD_FALLBACK}" = "false" ]; then
      echo "Error: The pull of '${OPENROSDE_DOCKER_REGISTRY}/openrosde-mesh2glb:${OPENROSDE_DOCKER_IMAGE_TAG}' failed, and 'OPENROSDE_DOCKER_BUILD_FALLBACK=false' does not build it locally."
      exit 1
    fi
    docker compose -p ${OPENROSDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml build openrosde-mesh2glb
  fi
  docker compose -p ${OPENROSDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml pull openrosde-platform
  if [[ "$?" -ne "0" ]]; then
    if [ "${OPENROSDE_DOCKER_BUILD_FALLBACK}" = "false" ]; then
      echo "Error: The pull of '${OPENROSDE_DOCKER_REGISTRY}/${OPENROSDE_ROBOT_PLATFORM}-devel:${OPENROSDE_DOCKER_IMAGE_TAG}' failed, and 'OPENROSDE_DOCKER_BUILD_FALLBACK=false' does not build it locally."
      exit 1
    fi
    docker compose -p ${OPENROSDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml build openrosde-platform
  fi
  # Always build the Docker layers of the active extensions and the user overlay ('openrosde' service) locally on top of the platform image.
  source ./scripts/build-extension-layers.bash "${OPENROSDE_DOCKER_REGISTRY}/${OPENROSDE_ROBOT_PLATFORM}-devel:${OPENROSDE_DOCKER_IMAGE_TAG}" || exit 1
  docker compose -p ${OPENROSDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml build openrosde
fi

################################################################################

# Give every mesh of the Catkin workspaces its GLB, for the file service that serves the robot model to clients of 'rosbridge', as 'docs/robot-models.md' describes.
# The meshes installed in the images got theirs when the user overlay was built.
bash ./scripts/generate-mesh-glbs.bash "${OPENROSDE_DOCKER_REGISTRY}/openrosde-mesh2glb:${OPENROSDE_DOCKER_IMAGE_TAG}"
