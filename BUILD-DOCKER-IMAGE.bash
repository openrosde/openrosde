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

export SDE_PLATFORM
echo "$0: SDE_PLATFORM=${SDE_PLATFORM}"

################################################################################

# Set the Docker container name from the [docker-project] argument.
# If no [docker-project] is given, use the current user name as the Docker project name.
SDE_DOCKER_PROJECT=$1
if [ -z "${SDE_DOCKER_PROJECT}" ]; then
  SDE_DOCKER_PROJECT=${USER}
fi
SDE_DOCKER_CONTAINER="sde_${SDE_PLATFORM}_${SDE_DOCKER_PROJECT}-1"
echo "$0: SDE_DOCKER_PROJECT=${SDE_DOCKER_PROJECT}"
echo "$0: SDE_DOCKER_CONTAINER=${SDE_DOCKER_CONTAINER}"

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

# Inject the 'Dockerfile' commit hash into the Docker container implicitly via a build argument in 'docker-compose.yaml'.
export SDE_DOCKERFILE_COMMIT_SHORT_SHA="$(git log -n 1 --pretty=format:%h ./docker/${SDE_PLATFORM}-devel/Dockerfile)"

# Export SDE_DOCKER_PROJECT so that it can be interpolated in 'docker-compose.yaml' for the container name.
export SDE_DOCKER_PROJECT

################################################################################

# Ask the user credentials to login into the GitLab Docker registry.
echo "Login into 'registry.gitlab.com' using a deploy token."
docker login -u "<deploy-token-user>" --password-stdin registry.gitlab.com/coarobo/sde

# Build the base image first, then the platform image.
# If the script runs in CI mode, build the images directly.
# Otherwise, try to pull them from the registry. If it fails, build locally.
SDE_BASE_IMAGE="registry.gitlab.com/coarobo/sde/sde-base:latest"

if [[ "$SDE_DOCKER_PROJECT" == "gitlab-ci" ]]; then
  docker build -t ${SDE_BASE_IMAGE} --build-arg SDE_DOCKERFILE_COMMIT_SHORT_SHA -f ./docker/sde-base/Dockerfile .
  docker compose -p ${SDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml build sde # --no-cache
else
  docker pull ${SDE_BASE_IMAGE}
  if [[ "$?" -ne "0" ]]; then
    docker build -t ${SDE_BASE_IMAGE} --build-arg SDE_DOCKERFILE_COMMIT_SHORT_SHA -f ./docker/sde-base/Dockerfile .
  fi
  docker compose -p ${SDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml pull sde
  if [[ "$?" -ne "0" ]]; then
    docker compose -p ${SDE_DOCKER_PROJECT} -f ./docker/docker-compose.yaml build sde
  fi
fi
