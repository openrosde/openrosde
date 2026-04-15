#!/bin/bash

# This script generates a Docker image with the relevant settings for the [docker-project].
#
# Usage: bash ./BUILD-DOCKER-IMAGE.bash [docker-project]
#
# [docker-project]: Used to name the Docker container and create multiple instances if needed.
#                   If the [docker-project] is 'gitlab-ci', the image is built from scratch, as if done in GitLab CI, without trying to download it.
#                   Otherwise, the default value is '$USER' and the image is either pulled from the Docker registry, or built as fallback if not found.

################################################################################

# Load the SDE environment variables.
source ./scripts/load-sde-env.bash "$1"

################################################################################

# Stop and remove the Docker container if it exists already.
SDE_EXISTING_DOCKER_CONTAINER_ID=`docker ps -aq -f name=${SDE_DOCKER_CONTAINER}`
if [ ! -z "${SDE_EXISTING_DOCKER_CONTAINER_ID}" ]; then
  echo "Stop the container ${SDE_DOCKER_CONTAINER} with ID: ${SDE_EXISTING_DOCKER_CONTAINER_ID}."
  docker stop ${SDE_EXISTING_DOCKER_CONTAINER_ID}
  echo "Remove the container ${SDE_DOCKER_CONTAINER} with ID: ${SDE_EXISTING_DOCKER_CONTAINER_ID}."
  docker rm ${SDE_EXISTING_DOCKER_CONTAINER_ID}
fi

################################################################################

# Login into the GitLab Docker registry using a read-only deploy token.
echo "Login into 'registry.gitlab.com' using a read-only deploy token."
docker login -u "<deploy-token-user>" --password-stdin registry.gitlab.com/coarobo/sde

# Pull the SDE base image and the platform-specific image from the registry.
# If pulling fails, build both images locally using cached data.
# When passing the 'gitlab-ci' argument, build all platform-specific images without cached data.
if [[ "${SDE_DOCKER_PROJECT}" == "gitlab-ci" ]]; then
  docker compose -p ${SDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml build sde-base --no-cache
  for SDE_PLATFORM in turtlebot3 ur5e fetch; do
    export SDE_ROBOT_PLATFORM=${SDE_PLATFORM}
    export SDE_ROBOT_PLATFORM_DOCKERFILE_COMMIT_SHORT_SHA="$(git -C "${SDE_ROOT_DIR}" log -n 1 --pretty=format:%h ./docker/${SDE_ROBOT_PLATFORM}-devel/Dockerfile)"
    echo "Building ${SDE_ROBOT_PLATFORM}-devel image..."
    docker compose -p ${SDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml build sde --no-cache
  done
else
  docker compose -p ${SDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml pull sde-base
  if [[ "$?" -ne "0" ]]; then
    docker compose -p ${SDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml build sde-base
  fi
  docker compose -p ${SDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml pull sde
  if [[ "$?" -ne "0" ]]; then
    docker compose -p ${SDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml build sde
  fi
fi
