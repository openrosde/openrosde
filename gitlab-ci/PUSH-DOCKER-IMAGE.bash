#!/bin/bash

# This script tags and pushes the base and all platform Docker images to the GitLab registry as 'latest'.
# Images are only pushed if their Dockerfile commit hash differs from the one already on the registry.
#
# Usage: bash PUSH-DOCKER-IMAGE.bash

################################################################################

# Load the SDE environment variables.
source ../scripts/load-sde-env.bash

################################################################################

# Authenticate with the Docker image registry on GitLab.
# Clear cached credentials first to force re-authentication.
docker logout registry.gitlab.com > /dev/null 2>&1
docker login registry.gitlab.com/coarobo/sde

################################################################################

# Tag and push the SDE base image if the commit hash is not already on the registry.
SDE_BASE_REGISTRY_TAG="registry.gitlab.com/coarobo/sde/sde-base:${SDE_BASE_DOCKERFILE_COMMIT_SHORT_SHA}"
if docker manifest inspect ${SDE_BASE_REGISTRY_TAG} > /dev/null 2>&1; then
  echo "Skipping 'sde-base' ('${SDE_BASE_DOCKERFILE_COMMIT_SHORT_SHA}' already exists on the registry)."
else
  docker tag registry.gitlab.com/coarobo/sde/sde-base:latest ${SDE_BASE_REGISTRY_TAG}
  echo "Pushing 'sde-base' image..."
  docker push ${SDE_BASE_REGISTRY_TAG}
  docker push registry.gitlab.com/coarobo/sde/sde-base:latest
fi

################################################################################

# Tag and push all platform-specific images, skipping those whose commit hash already exists on the registry.
for SDE_PLATFORM in turtlebot3 ur5e; do
  SDE_PLATFORM_COMMIT_SHORT_SHA="$(git -C "${SDE_ROOT_DIR}" log -n 1 --pretty=format:%h ./docker/${SDE_PLATFORM}-devel/Dockerfile)"
  SDE_PLATFORM_REGISTRY_TAG="registry.gitlab.com/coarobo/sde/${SDE_PLATFORM}-devel:${SDE_PLATFORM_COMMIT_SHORT_SHA}"
  if docker manifest inspect ${SDE_PLATFORM_REGISTRY_TAG} > /dev/null 2>&1; then
    echo "Skipping '${SDE_PLATFORM}-devel' ('${SDE_PLATFORM_COMMIT_SHORT_SHA}' already exists on the registry)."
  else
    docker tag registry.gitlab.com/coarobo/sde/${SDE_PLATFORM}-devel:latest ${SDE_PLATFORM_REGISTRY_TAG}
    echo "Pushing '${SDE_PLATFORM}-devel' image..."
    docker push ${SDE_PLATFORM_REGISTRY_TAG}
    docker push registry.gitlab.com/coarobo/sde/${SDE_PLATFORM}-devel:latest
  fi
done
