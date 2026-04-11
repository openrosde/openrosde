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
DOCKER_PROJECT=$1
if [ -z "${DOCKER_PROJECT}" ]; then
  DOCKER_PROJECT=${USER}
fi
DOCKER_CONTAINER="${DOCKER_PROJECT}-sde-1"
echo "$0: DOCKER_PROJECT=${DOCKER_PROJECT}"
echo "$0: DOCKER_CONTAINER=${DOCKER_CONTAINER}"

################################################################################

# Stop and remove the Docker container if it exists already.
EXISTING_DOCKER_CONTAINER_ID=`docker ps -aq -f name=${DOCKER_CONTAINER}`
if [ ! -z "${EXISTING_DOCKER_CONTAINER_ID}" ]; then
  echo "Stop the container ${DOCKER_CONTAINER} with ID: ${EXISTING_DOCKER_CONTAINER_ID}."
  docker stop ${EXISTING_DOCKER_CONTAINER_ID}
  echo "Remove the container ${DOCKER_CONTAINER} with ID: ${EXISTING_DOCKER_CONTAINER_ID}."
  docker rm ${EXISTING_DOCKER_CONTAINER_ID}
fi

################################################################################

# Inject the 'Dockerfile' commit hash into the Docker container implicitly via a build argument in 'docker-compose.yaml'.
export DOCKERFILE_COMMIT_SHORT_SHA="$(git log -n 1 --pretty=format:%h ./docker/${SDE_PLATFORM}-devel/Dockerfile)"

################################################################################

# Ask the user credentials to login into the GitLab Docker registry.
echo "Login into 'registry.gitlab.com' using a deploy token."
docker login -u "<deploy-token-user>" --password-stdin registry.gitlab.com/coarobo/sde

# If the script runs in CI mode, build the image directly.
# Otherwise, try to pull it from the registry. If it fails, build locally.
if [[ "$DOCKER_PROJECT" == "gitlab-ci" ]]; then
  docker compose -p ${DOCKER_PROJECT} -f ./docker/docker-compose.yaml build # --no-cache
else
  docker compose -p ${DOCKER_PROJECT} -f ./docker/docker-compose.yaml pull
  if [[ "$?" -ne "0" ]]; then
    docker compose -p ${DOCKER_PROJECT} -f ./docker/docker-compose.yaml build
  fi
fi
