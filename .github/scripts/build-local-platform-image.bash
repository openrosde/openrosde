#!/bin/bash

# This script builds the image of a platform in a job of the reusable workflow 'extension.yml', on top of a published base image, with the published image of the platform as its cache, and never pushes it.
# A workflow of an extension cannot push to the registry of the core, so each test job builds the image of its platform for itself, from the folder that holds the platform, as 'gitlab-ci/build-ci-image.bash' does in the pipeline of the core.
# A platform whose sources the extension under test leaves unchanged builds from the layers of the published image, much like a pull, while a changed one builds its changed layers again, so the test runs on the image of the commit under test.
# The image is tagged 'openrosde-ci-local/<platform>-devel:latest', which no 'docker push' can publish.
#
# Usage: bash ./.github/scripts/build-local-platform-image.bash <platform> <platform-root-dir> <base-image>
#
# <platform>:          Name of the platform, such as 'ur5e'.
# <platform-root-dir>: Folder that holds the platform, relative to the repository root, such as 'extensions/openrosde-platform-ur5e'.
# <base-image>:        Base image to build on, such as 'ghcr.io/openrosde/openrosde-base:dev'.
#
# The published image of the platform that serves as the cache is read from 'OPENROSDE_CI_IMAGE_REGISTRY' and 'OPENROSDE_CI_IMAGE_TAG', such as 'ghcr.io/openrosde/ur5e-devel:dev'.

################################################################################

# Name the Dockerfile, the cache, and the local image.
OPENROSDE_CI_DOCKERFILE="docker/$1-devel/Dockerfile"
OPENROSDE_CI_CACHE_IMAGE="${OPENROSDE_CI_IMAGE_REGISTRY}/$1-devel:${OPENROSDE_CI_IMAGE_TAG}"
OPENROSDE_CI_LOCAL_IMAGE="openrosde-ci-local/$1-devel:latest"

# Check the arguments and the variables that name the cache.
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
  echo "Usage: bash ./.github/scripts/build-local-platform-image.bash <platform> <platform-root-dir> <base-image>"
  exit 1
fi
if [ -z "${OPENROSDE_CI_IMAGE_REGISTRY}" ] || [ -z "${OPENROSDE_CI_IMAGE_TAG}" ]; then
  echo "Error: 'OPENROSDE_CI_IMAGE_REGISTRY' and 'OPENROSDE_CI_IMAGE_TAG' must name the published images, such as 'ghcr.io/openrosde' and 'dev'."
  exit 1
fi
if [ ! -f "$2/${OPENROSDE_CI_DOCKERFILE}" ]; then
  echo "Error: The platform '$1' has no Dockerfile '$2/${OPENROSDE_CI_DOCKERFILE}'."
  exit 1
fi

################################################################################

# Build the image from the folder that holds the platform, with the commit of its Dockerfile embedded for the version check of 'initialize-bash-shell.bash', as 'gitlab-ci/build-ci-image.bash' builds it.
echo "Building '${OPENROSDE_CI_LOCAL_IMAGE}' from '$2' on '$3', with '${OPENROSDE_CI_CACHE_IMAGE}' as its cache..."
docker buildx build \
  --build-arg "OPENROSDE_DOCKERFILE_COMMIT_SHORT_SHA=$(git -C "$2" log -n 1 --pretty=format:%h -- "${OPENROSDE_CI_DOCKERFILE}")" \
  --build-arg "OPENROSDE_BASE_IMAGE=$3" \
  --build-arg "OPENROSDE_ROBOT_PLATFORM=$1" \
  --cache-from "${OPENROSDE_CI_CACHE_IMAGE}" \
  --file "$2/${OPENROSDE_CI_DOCKERFILE}" \
  --tag "${OPENROSDE_CI_LOCAL_IMAGE}" \
  --load \
  "$2"
