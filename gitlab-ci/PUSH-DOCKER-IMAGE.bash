#!/bin/bash

# This script tags and pushes the base and all platform Docker images to the registry of 'SDE_DOCKER_REGISTRY' as 'latest'.
# Images are only pushed if their Dockerfile commit hash differs from the one already on the registry.
#
# Usage: bash PUSH-DOCKER-IMAGE.bash

################################################################################

# Load the SDE environment variables.
source ../scripts/load-sde-env.bash

################################################################################

# Authenticate with the Docker image registry.
# Clear cached credentials first to force re-authentication.
docker logout ${SDE_DOCKER_REGISTRY%%/*} > /dev/null 2>&1
docker login ${SDE_DOCKER_REGISTRY%%/*}

################################################################################

# Tag and push the SDE base image if the commit hash is not already on the registry.
SDE_BASE_REGISTRY_TAG="${SDE_DOCKER_REGISTRY}/sde-base:${SDE_BASE_DOCKERFILE_COMMIT_SHORT_SHA}"
if docker manifest inspect ${SDE_BASE_REGISTRY_TAG} > /dev/null 2>&1; then
  echo "Skipping 'sde-base' ('${SDE_BASE_DOCKERFILE_COMMIT_SHORT_SHA}' already exists on the registry)."
else
  docker tag ${SDE_DOCKER_REGISTRY}/sde-base:latest ${SDE_BASE_REGISTRY_TAG}
  echo "Pushing 'sde-base' image..."
  docker push ${SDE_BASE_REGISTRY_TAG}
  docker push ${SDE_DOCKER_REGISTRY}/sde-base:latest
fi

################################################################################

# Tag and push all platform-specific images, skipping those whose commit hash already exists on the registry.
# The platforms are found by name, as 'scripts/list-robot-platforms.bash' lists them.
for SDE_PLATFORM in $(bash "${SDE_ROOT_DIR}/scripts/list-robot-platforms.bash"); do
  SDE_PLATFORM_COMMIT_SHORT_SHA="$(git -C "$(sde-find-platform-root-dir "${SDE_PLATFORM}")" log -n 1 --pretty=format:%h ./docker/${SDE_PLATFORM}-devel/Dockerfile)"
  SDE_PLATFORM_REGISTRY_TAG="${SDE_DOCKER_REGISTRY}/${SDE_PLATFORM}-devel:${SDE_PLATFORM_COMMIT_SHORT_SHA}"
  if docker manifest inspect ${SDE_PLATFORM_REGISTRY_TAG} > /dev/null 2>&1; then
    echo "Skipping '${SDE_PLATFORM}-devel' ('${SDE_PLATFORM_COMMIT_SHORT_SHA}' already exists on the registry)."
  else
    docker tag ${SDE_DOCKER_REGISTRY}/${SDE_PLATFORM}-devel:latest ${SDE_PLATFORM_REGISTRY_TAG}
    echo "Pushing '${SDE_PLATFORM}-devel' image..."
    docker push ${SDE_PLATFORM_REGISTRY_TAG}
    docker push ${SDE_DOCKER_REGISTRY}/${SDE_PLATFORM}-devel:latest
  fi
done

################################################################################

# The 'user-devel' image is intentionally not pushed to the registry.
# It is the user-overlay layer (see 'docker/user-devel/Dockerfile') and is built locally on top of the platform image by 'BUILD-DOCKER-IMAGE.bash' on every developer machine.
