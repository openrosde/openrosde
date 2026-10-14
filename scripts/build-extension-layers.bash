#!/bin/bash

# This script builds the Docker layers of the active extensions locally, each on top of the previous one, from a parent image up to the parent of the user overlay.
# Each layer is built from the folder of its extension, so that its 'COPY' instructions read from there, and is tagged 'openrosde-local/<setup>/<name>-devel:latest' in lowercase, which no 'docker push' can publish.
# It is sourced by 'BUILD-DOCKER-IMAGE.bash' on the platform image, and can be sourced the same way by a CI job, after 'scripts/load-openrosde-env.bash', whose 'OPENROSDE_EXTENSION_DOCKERFILES' and 'OPENROSDE_LOCAL_IMAGE_PREFIX' it reads.
# Its status is that of the build, so the caller stops when a layer fails to build, rather than building the user overlay on an older layer.
#
# Usage: source ./scripts/build-extension-layers.bash <parent-image>
#
# <parent-image>: Image below the first layer, usually the platform image, such as 'registry.gitlab.com/coarobo/sde/ur5e-devel:dev'.

################################################################################

# Build every layer on top of the previous one, and fail at the first layer that does not build.
function openrosde-build-extension-layers () {
  local OPENROSDE_PARENT_IMAGE_TAG="$1"
  local OPENROSDE_EXTENSION_DOCKERFILE OPENROSDE_EXTENSION_ROOT_DIR OPENROSDE_EXTENSION_IMAGE_TAG
  if [ -z "${OPENROSDE_PARENT_IMAGE_TAG}" ]; then
    echo "Usage: source ./scripts/build-extension-layers.bash <parent-image>"
    return 1
  fi
  for OPENROSDE_EXTENSION_DOCKERFILE in "${OPENROSDE_EXTENSION_DOCKERFILES[@]}"; do
    OPENROSDE_EXTENSION_ROOT_DIR="$(dirname "$(dirname "$(dirname "${OPENROSDE_EXTENSION_DOCKERFILE}")")")"
    OPENROSDE_EXTENSION_IMAGE_TAG="${OPENROSDE_LOCAL_IMAGE_PREFIX}/$(basename "$(dirname "${OPENROSDE_EXTENSION_DOCKERFILE}")" | tr '[:upper:]' '[:lower:]'):latest"
    echo "Building ${OPENROSDE_EXTENSION_IMAGE_TAG} on top of ${OPENROSDE_PARENT_IMAGE_TAG}..."
    if ! docker build \
      --build-arg OPENROSDE_PARENT_IMAGE=${OPENROSDE_PARENT_IMAGE_TAG} \
      --build-arg OPENROSDE_DOCKERFILE_COMMIT_SHORT_SHA="$(git -C "${OPENROSDE_EXTENSION_ROOT_DIR}" log -n 1 --pretty=format:%h "${OPENROSDE_EXTENSION_DOCKERFILE}")" \
      -f "${OPENROSDE_EXTENSION_DOCKERFILE}" \
      -t "${OPENROSDE_EXTENSION_IMAGE_TAG}" \
      "${OPENROSDE_EXTENSION_ROOT_DIR}"; then
      echo "Error: The Docker layer '${OPENROSDE_EXTENSION_DOCKERFILE#${OPENROSDE_ROOT_DIR}/}' failed to build, so the user overlay is not built on top of it."
      return 1
    fi
    OPENROSDE_PARENT_IMAGE_TAG="${OPENROSDE_EXTENSION_IMAGE_TAG}"
  done
}

################################################################################

# Build the layers on top of the parent image given as argument.
openrosde-build-extension-layers "$1"
