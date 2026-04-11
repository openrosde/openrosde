#!/bin/bash

# This script tags and pushes the base and platform Docker images to the GitLab registry as 'latest'.
#
# Usage: bash PUSH-DOCKER-IMAGE.bash

################################################################################

# Load the default environment variables from the '.env' file:
source ../.env

# Overwrite the default environment variables with the user's variables from the '.env.custom' file (if it exists):
if [ -f ../.env.custom ]; then
  source ../.env.custom
fi

echo "$0: SDE_PLATFORM=${SDE_PLATFORM}"

################################################################################

# Authenticate with the Docker image registry on GitLab.
docker login registry.gitlab.com/coarobo/sde

################################################################################

# Tag and push the base image (sde-base).
SDE_BASE_DOCKER_FILE_HASH=`git log -n 1 --no-merges --pretty=format:%h ../docker/sde-base/Dockerfile`
docker tag registry.gitlab.com/coarobo/sde/sde-base:latest registry.gitlab.com/coarobo/sde/sde-base:${SDE_BASE_DOCKER_FILE_HASH}

echo "Pushing sde-base image..."
docker push registry.gitlab.com/coarobo/sde/sde-base:${SDE_BASE_DOCKER_FILE_HASH}
docker push registry.gitlab.com/coarobo/sde/sde-base:latest

################################################################################

# Tag and push the platform-specific image (e.g. turtlebot3-devel, ur5e-devel).
SDE_PLATFORM_DOCKER_FILE_HASH=`git log -n 1 --no-merges --pretty=format:%h ../docker/${SDE_PLATFORM}-devel/Dockerfile`
docker tag registry.gitlab.com/coarobo/sde/${SDE_PLATFORM}-devel:latest registry.gitlab.com/coarobo/sde/${SDE_PLATFORM}-devel:${SDE_PLATFORM_DOCKER_FILE_HASH}

echo "Pushing ${SDE_PLATFORM}-devel image..."
docker push registry.gitlab.com/coarobo/sde/${SDE_PLATFORM}-devel:${SDE_PLATFORM_DOCKER_FILE_HASH}
docker push registry.gitlab.com/coarobo/sde/${SDE_PLATFORM}-devel:latest
