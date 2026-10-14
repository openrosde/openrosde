#!/bin/bash

# This script loads the SDE environment variables and derives the Docker container name.
# It is sourced by the other SDE scripts to avoid code duplication.
#
# Usage: source ./scripts/load-sde-env.bash [docker-project]
#
# [docker-project]: Used to name the Docker container and create multiple instances if needed.
#                   Default value is '$USER'.

################################################################################

# Resolve the repository root directory relative to this script.
SDE_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Load the default environment variables from the '.env' file:
source "${SDE_ROOT_DIR}/.env"

# Overwrite the default environment variables with the user's variables from the '.env.custom' file (if it exists):
if [ -f "${SDE_ROOT_DIR}/.env.custom" ]; then
  source "${SDE_ROOT_DIR}/.env.custom"
fi

# Resolve where the files of the platform and of the extensions live, in the core or in 'extensions/'.
source "${SDE_ROOT_DIR}/scripts/load-extension-paths.bash" "${SDE_ROOT_DIR}"

################################################################################

# Set the Docker container name from the [docker-project] argument.
# If no [docker-project] is given, use the current user name as the Docker project name.
SDE_DOCKER_PROJECT=$1
if [ -z "${SDE_DOCKER_PROJECT}" ]; then
  SDE_DOCKER_PROJECT=${USER}
fi
SDE_DOCKER_CONTAINER="sde-${SDE_ROBOT_PLATFORM}-${SDE_DOCKER_PROJECT}-1"

################################################################################

# Derive the user and group IDs and the Dockerfiles and commit hashes that 'docker-compose.yaml' passes to the images.
SDE_USER_ID="$(id -u)"
SDE_GROUP_ID="$(id -g)"
SDE_BASE_DOCKERFILE_COMMIT_SHORT_SHA="$(git -C "${SDE_ROOT_DIR}" log -n 1 --pretty=format:%h ./docker/sde-base/Dockerfile)"
SDE_USER_DEVEL_DOCKERFILE_COMMIT_SHORT_SHA="$(git -C "${SDE_ROOT_DIR}" log -n 1 --pretty=format:%h ./docker/user-devel/Dockerfile)"

# Derive the Dockerfile of a platform, relative to the SDE root directory, and its commit hash in the repository that holds it.
# 'BUILD-DOCKER-IMAGE.bash' calls it again for every platform it builds.
function sde-derive-platform-dockerfile () {
  local SDE_PLATFORM_ROOT_DIR
  SDE_PLATFORM_ROOT_DIR="$(sde-find-platform-root-dir "$1")"
  SDE_ROBOT_PLATFORM_DOCKERFILE="docker/$1-devel/Dockerfile"
  if [ "${SDE_PLATFORM_ROOT_DIR}" != "${SDE_ROOT_DIR}" ]; then
    SDE_ROBOT_PLATFORM_DOCKERFILE="${SDE_PLATFORM_ROOT_DIR#${SDE_ROOT_DIR}/}/${SDE_ROBOT_PLATFORM_DOCKERFILE}"
  fi
  SDE_ROBOT_PLATFORM_DOCKERFILE_COMMIT_SHORT_SHA="$(git -C "${SDE_PLATFORM_ROOT_DIR}" log -n 1 --pretty=format:%h "./docker/$1-devel/Dockerfile")"
  export SDE_ROBOT_PLATFORM_DOCKERFILE SDE_ROBOT_PLATFORM_DOCKERFILE_COMMIT_SHORT_SHA
}
sde-derive-platform-dockerfile "${SDE_ROBOT_PLATFORM}"

# List the Docker layers of the active extensions: every 'docker/<name>-devel/Dockerfile' of an active folder other than the core, unless '<name>' is a platform.
# They stack between the platform image and the user overlay, in the order of the active folders, and are always built locally, like the user overlay.
SDE_EXTENSION_DOCKERFILES=()
SDE_ROBOT_PLATFORM_NAMES=" $(bash "${SDE_ROOT_DIR}/scripts/list-robot-platforms.bash" | tr '\n' ' ') "
for SDE_EXTENSION_ROOT_DIR in "${SDE_ACTIVE_ROOT_DIRS[@]:1}"; do
  for SDE_EXTENSION_DOCKERFILE in "${SDE_EXTENSION_ROOT_DIR}"/docker/*-devel/Dockerfile; do
    SDE_EXTENSION_IMAGE_NAME="$(basename "$(dirname "${SDE_EXTENSION_DOCKERFILE}")")"
    if [ -f "${SDE_EXTENSION_DOCKERFILE}" ] && [[ "${SDE_ROBOT_PLATFORM_NAMES}" != *" ${SDE_EXTENSION_IMAGE_NAME%-devel} "* ]]; then
      SDE_EXTENSION_DOCKERFILES+=("${SDE_EXTENSION_DOCKERFILE}")
    fi
  done
done
unset SDE_EXTENSION_ROOT_DIR SDE_EXTENSION_DOCKERFILE SDE_EXTENSION_IMAGE_NAME

# Derive the parent image of the user overlay: the last Docker layer of the extensions, or else the platform image.
SDE_USER_PARENT_IMAGE="${SDE_DOCKER_REGISTRY}/${SDE_ROBOT_PLATFORM}-devel:latest"
if [ "${#SDE_EXTENSION_DOCKERFILES[@]}" -gt 0 ]; then
  SDE_USER_PARENT_IMAGE="${SDE_DOCKER_REGISTRY}/$(basename "$(dirname "${SDE_EXTENSION_DOCKERFILES[${#SDE_EXTENSION_DOCKERFILES[@]}-1]}")"):latest"
fi

# Export every 'SDE_*' variable, so that the Docker Compose files of the core, of the platform, and of the user overlay can interpolate it, and the platform scripts in 'scripts/<platform>/' can read it.
for SDE_VARIABLE_NAME in $(compgen -v SDE_); do
  export "${SDE_VARIABLE_NAME}"
done
unset SDE_VARIABLE_NAME

################################################################################

# Print every 'SDE_*' variable for debugging purposes.
for SDE_VARIABLE_NAME in $(compgen -v SDE_ | sort); do
  echo "$0: ${SDE_VARIABLE_NAME}=${!SDE_VARIABLE_NAME}"
done
unset SDE_VARIABLE_NAME
