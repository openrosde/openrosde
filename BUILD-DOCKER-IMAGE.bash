#!/bin/bash

# This script generates a Docker image with the relevant settings for the [docker-project].
#
# Usage: bash BUILD-DOCKER-IMAGE.bash [docker-project]
#
# [docker-project]: Used to name the Docker container and create multiple instances if needed.
#                   If the [docker-project] is 'gitlab-ci', the image is built from scratch, as if done in GitLab CI, without trying to download it.
#                   Otherwise, the default value is '$USER' and the image is either pulled from the Docker registry, or built as fallback if not found.

################################################################################

# Load the default environment variables from the '.env' file:
source ./.env

# Overwrite the default environment variables with the user's variables from the '.env.custom' file (if it exists):
if [ -f ./.env.custom ]; then
  source ./.env.custom
fi

################################################################################

# Set the Docker container name from the [docker-project] argument.
# If no [docker-project] is given, use the current user name as the Docker project name.
SDE_DOCKER_PROJECT=$1
if [ -z "${SDE_DOCKER_PROJECT}" ]; then
  SDE_DOCKER_PROJECT=${USER}
fi
SDE_DOCKER_CONTAINER="sde_${SDE_PLATFORM}_${SDE_DOCKER_PROJECT}-1"

################################################################################

# Export variables so that they can be interpolated in 'docker-compose.yaml'.
export SDE_PLATFORM
export SDE_DOCKER_PROJECT
export SDE_DOCKERFILE_COMMIT_SHORT_SHA="$(git log -n 1 --pretty=format:%h ./docker/${SDE_PLATFORM}-devel/Dockerfile)"

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

# Ask the user credentials to login into the GitLab Docker registry.
echo "Login into 'registry.gitlab.com' using a deploy token."
docker login -u "<deploy-token-user>" --password-stdin registry.gitlab.com/coarobo/sde

# Build the SDE base image first, then the platform-specific image.
# If the script runs in CI mode, build the images from scratch without cached data.
# Otherwise, try to pull them from the registry, and if it fails, build locally using cached data.

if [[ "$SDE_DOCKER_PROJECT" == "gitlab-ci" ]]; then
  docker compose -p ${SDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml build sde-base --no-cache
  docker compose -p ${SDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml build sde --no-cache
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
