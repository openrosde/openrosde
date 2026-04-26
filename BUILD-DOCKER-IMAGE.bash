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

# Determine build strategy based on the Docker project name.
# - 'gitlab-ci': Build all platform images without cache (CI/CD pipeline).
# - 'local': Build current platform image with cache (fast iteration on local machine).
# Otherwise, try to pull from registry, fall back to build with cache if pull fails.
if [[ "${SDE_DOCKER_PROJECT}" == "gitlab-ci" ]]; then
  # Build all platform images from scratch without cache.
  # The user overlay ('sde' service) is built locally on top of each platform.
  docker compose -p ${SDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml build sde-base --no-cache
  for SDE_PLATFORM in turtlebot3 ur5e fetch sciurus17 cobotta hsr; do
    export SDE_ROBOT_PLATFORM=${SDE_PLATFORM}
    export SDE_ROBOT_PLATFORM_DOCKERFILE_COMMIT_SHORT_SHA="$(git -C "${SDE_ROOT_DIR}" log -n 1 --pretty=format:%h ./docker/${SDE_ROBOT_PLATFORM}-devel/Dockerfile)"
    echo "Building ${SDE_ROBOT_PLATFORM}-devel image..."
    docker compose -p ${SDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml build sde-platform --no-cache
    echo "Building user-devel image on top of ${SDE_ROBOT_PLATFORM}-devel..."
    docker compose -p ${SDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml build sde --no-cache
  done
elif [[ "${SDE_DOCKER_PROJECT}" == "local" ]]; then
  # Build current platform and user images with cache (fast rebuild for local development).
  docker compose -p ${SDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml build sde-base
  docker compose -p ${SDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml build sde-platform
  docker compose -p ${SDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml build sde
else
  # Login into the GitLab Docker registry using a read-only deploy token.
  echo "Login into 'registry.gitlab.com' using a read-only deploy token."
  docker login -u "<deploy-token-user>" --password-stdin registry.gitlab.com/coarobo/sde
  # Try to pull from registry, fall back to build with cache if pull fails.
  docker compose -p ${SDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml pull sde-base
  if [[ "$?" -ne "0" ]]; then
    docker compose -p ${SDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml build sde-base
  fi
  docker compose -p ${SDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml pull sde-platform
  if [[ "$?" -ne "0" ]]; then
    docker compose -p ${SDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml build sde-platform
  fi
  # Always build the user overlay ('sde' service) locally on top of the platform image.
  docker compose -p ${SDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml build sde
fi
