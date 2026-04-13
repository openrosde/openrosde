#!/bin/bash

# This script tags and pushes the base and platform Docker images to the GitLab registry as 'latest'.
#
# Usage: bash PUSH-DOCKER-IMAGE.bash

################################################################################

# Load the SDE environment variables.
source ../scripts/load-sde-env.bash

################################################################################

# Authenticate with the Docker image registry on GitLab.
docker login registry.gitlab.com/coarobo/sde

################################################################################

# Tag and push the base image (sde-base).
docker tag registry.gitlab.com/coarobo/sde/sde-base:latest registry.gitlab.com/coarobo/sde/sde-base:${SDE_BASE_DOCKERFILE_COMMIT_SHORT_SHA}

echo "Pushing sde-base image..."
docker push registry.gitlab.com/coarobo/sde/sde-base:${SDE_BASE_DOCKERFILE_COMMIT_SHORT_SHA}
docker push registry.gitlab.com/coarobo/sde/sde-base:latest

################################################################################

# Tag and push the platform-specific image (e.g. turtlebot3-devel, ur5e-devel).
docker tag registry.gitlab.com/coarobo/sde/${SDE_PLATFORM}-devel:latest registry.gitlab.com/coarobo/sde/${SDE_PLATFORM}-devel:${SDE_PLATFORM_DOCKERFILE_COMMIT_SHORT_SHA}

echo "Pushing ${SDE_PLATFORM}-devel image..."
docker push registry.gitlab.com/coarobo/sde/${SDE_PLATFORM}-devel:${SDE_PLATFORM_DOCKERFILE_COMMIT_SHORT_SHA}
docker push registry.gitlab.com/coarobo/sde/${SDE_PLATFORM}-devel:latest
