#!/bin/bash

# This script loads the OpenRoSDE environment variables and derives the Docker container name.
# It is sourced by the other OpenRoSDE scripts to avoid code duplication.
#
# Usage: source ./scripts/load-openrosde-env.bash [docker-project]
#
# [docker-project]: Used to name the Docker container and create multiple instances if needed.
#                   Default value is '$USER'.

################################################################################

# Resolve the repository root directory relative to this script.
OPENROSDE_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Load the default environment variables from the '.env' file:
source "${OPENROSDE_ROOT_DIR}/.env"

# Overwrite the default environment variables with the user's variables from the '.env.custom' file (if it exists):
source "${OPENROSDE_ROOT_DIR}/scripts/load-env-custom.bash" "${OPENROSDE_ROOT_DIR}"

# Resolve where the files of the platform and of the extensions live, in the core or in 'extensions/'.
source "${OPENROSDE_ROOT_DIR}/scripts/load-extension-paths.bash" "${OPENROSDE_ROOT_DIR}"

################################################################################

# Set the Docker container name from the [docker-project] argument.
# If no [docker-project] is given, use the current user name as the Docker project name.
OPENROSDE_DOCKER_PROJECT=$1
if [ -z "${OPENROSDE_DOCKER_PROJECT}" ]; then
  OPENROSDE_DOCKER_PROJECT=${USER}
fi
OPENROSDE_DOCKER_CONTAINER="openrosde-${OPENROSDE_ROBOT_PLATFORM}-${OPENROSDE_DOCKER_PROJECT}-1"

################################################################################

# Derive the tag of the base and platform images from the branch when 'OPENROSDE_DOCKER_IMAGE_TAG' is 'auto': 'main' on the 'main' branch and on a release tag, which checks out a detached 'HEAD', and 'dev' everywhere else.
if [ "${OPENROSDE_DOCKER_IMAGE_TAG}" = "auto" ]; then
  OPENROSDE_GIT_BRANCH_NAME="$(git -C "${OPENROSDE_ROOT_DIR}" rev-parse --abbrev-ref HEAD 2>/dev/null)"
  if [ "${OPENROSDE_GIT_BRANCH_NAME}" = "main" ] || [ "${OPENROSDE_GIT_BRANCH_NAME}" = "HEAD" ]; then
    OPENROSDE_DOCKER_IMAGE_TAG=main
  else
    OPENROSDE_DOCKER_IMAGE_TAG=dev
  fi
fi

# Derive the user and group IDs and the Dockerfiles and commit hashes that 'docker-compose.yaml' passes to the images.
OPENROSDE_USER_ID="$(id -u)"
OPENROSDE_GROUP_ID="$(id -g)"
OPENROSDE_BASE_DOCKERFILE_COMMIT_SHORT_SHA="$(git -C "${OPENROSDE_ROOT_DIR}" log -n 1 --pretty=format:%h ./docker/openrosde-base/Dockerfile)"
OPENROSDE_USER_DEVEL_DOCKERFILE_COMMIT_SHORT_SHA="$(git -C "${OPENROSDE_ROOT_DIR}" log -n 1 --pretty=format:%h ./docker/user-devel/Dockerfile)"

# Derive the Dockerfile of a platform, relative to the root directory that holds the platform, the core, an extension, or a part, and its commit hash in the repository that holds it.
# 'docker-compose.yaml' builds the platform image from that root directory, so that its 'COPY' instructions read from there, as the Docker layers do.
function openrosde-derive-platform-dockerfile () {
  local OPENROSDE_PLATFORM_ROOT_DIR
  OPENROSDE_PLATFORM_ROOT_DIR="$(openrosde-find-platform-root-dir "$1")"
  OPENROSDE_ROBOT_PLATFORM_DOCKERFILE="docker/$1-devel/Dockerfile"
  OPENROSDE_ROBOT_PLATFORM_DOCKERFILE_COMMIT_SHORT_SHA="$(git -C "${OPENROSDE_PLATFORM_ROOT_DIR}" log -n 1 --pretty=format:%h "./${OPENROSDE_ROBOT_PLATFORM_DOCKERFILE}")"
  export OPENROSDE_ROBOT_PLATFORM_DOCKERFILE OPENROSDE_ROBOT_PLATFORM_DOCKERFILE_COMMIT_SHORT_SHA
}
openrosde-derive-platform-dockerfile "${OPENROSDE_ROBOT_PLATFORM}"

# Name the images that only this machine builds, the Docker layers of the extensions and the user overlay, under 'openrosde-local/<setup>/', apart from the registry of the base and platform images.
# Their names hold no registry host, so a 'docker push' sends them to Docker Hub, where no repository of three components can exist, and fails, while two setups that share a layer never overwrite each other's image.
OPENROSDE_LOCAL_IMAGE_PREFIX="openrosde-local/${OPENROSDE_ROBOT_SETUP}"

# List the Docker layers of the active extensions: every 'docker/<name>-devel/Dockerfile' of an active folder other than the core, unless '<name>' is a platform.
# They stack between the platform image and the user overlay, in the order of the active folders, and are always built locally, like the user overlay.
# A platform is any name that a template declares as its own platform, as 'scripts/load-extension-paths.bash' reads them.
OPENROSDE_EXTENSION_DOCKERFILES=()
for OPENROSDE_EXTENSION_ROOT_DIR in "${OPENROSDE_ACTIVE_ROOT_DIRS[@]:1}"; do
  for OPENROSDE_EXTENSION_DOCKERFILE in "${OPENROSDE_EXTENSION_ROOT_DIR}"/docker/*-devel/Dockerfile; do
    OPENROSDE_EXTENSION_IMAGE_NAME="$(basename "$(dirname "${OPENROSDE_EXTENSION_DOCKERFILE}")")"
    if [ -f "${OPENROSDE_EXTENSION_DOCKERFILE}" ] && [[ "${OPENROSDE_DECLARED_PLATFORM_NAMES}" != *" ${OPENROSDE_EXTENSION_IMAGE_NAME%-devel} "* ]]; then
      OPENROSDE_EXTENSION_DOCKERFILES+=("${OPENROSDE_EXTENSION_DOCKERFILE}")
    fi
  done
done
unset OPENROSDE_EXTENSION_ROOT_DIR OPENROSDE_EXTENSION_DOCKERFILE OPENROSDE_EXTENSION_IMAGE_NAME

# Derive the parent image of the user overlay: the last Docker layer of the extensions, or else the platform image.
OPENROSDE_USER_PARENT_IMAGE="${OPENROSDE_DOCKER_REGISTRY}/${OPENROSDE_ROBOT_PLATFORM}-devel:${OPENROSDE_DOCKER_IMAGE_TAG}"
if [ "${#OPENROSDE_EXTENSION_DOCKERFILES[@]}" -gt 0 ]; then
  OPENROSDE_USER_PARENT_IMAGE="${OPENROSDE_LOCAL_IMAGE_PREFIX}/$(basename "$(dirname "${OPENROSDE_EXTENSION_DOCKERFILES[${#OPENROSDE_EXTENSION_DOCKERFILES[@]}-1]}")"):latest"
fi

# Export every 'OPENROSDE_*' variable, so that the Docker Compose files of the core, of the platform, and of the user overlay can interpolate it, and the platform scripts in 'scripts/<platform>/' can read it.
for OPENROSDE_VARIABLE_NAME in $(compgen -v OPENROSDE_); do
  export "${OPENROSDE_VARIABLE_NAME}"
done
unset OPENROSDE_VARIABLE_NAME

################################################################################

# Print every 'OPENROSDE_*' variable for debugging purposes.
for OPENROSDE_VARIABLE_NAME in $(compgen -v OPENROSDE_ | sort); do
  echo "$0: ${OPENROSDE_VARIABLE_NAME}=${!OPENROSDE_VARIABLE_NAME}"
done
unset OPENROSDE_VARIABLE_NAME
