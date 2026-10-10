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

################################################################################

# Set the Docker container name from the [docker-project] argument.
# If no [docker-project] is given, use the current user name as the Docker project name.
SDE_DOCKER_PROJECT=$1
if [ -z "${SDE_DOCKER_PROJECT}" ]; then
  SDE_DOCKER_PROJECT=${USER}
fi
SDE_DOCKER_CONTAINER="sde-${SDE_ROBOT_PLATFORM}-${SDE_DOCKER_PROJECT}-1"

################################################################################

# Derive the user and group IDs and the Dockerfile commit hashes that 'docker-compose.yaml' passes to the images.
SDE_USER_ID="$(id -u)"
SDE_GROUP_ID="$(id -g)"
SDE_BASE_DOCKERFILE_COMMIT_SHORT_SHA="$(git -C "${SDE_ROOT_DIR}" log -n 1 --pretty=format:%h ./docker/sde-base/Dockerfile)"
SDE_ROBOT_PLATFORM_DOCKERFILE_COMMIT_SHORT_SHA="$(git -C "${SDE_ROOT_DIR}" log -n 1 --pretty=format:%h ./docker/${SDE_ROBOT_PLATFORM}-devel/Dockerfile)"
SDE_USER_DEVEL_DOCKERFILE_COMMIT_SHORT_SHA="$(git -C "${SDE_ROOT_DIR}" log -n 1 --pretty=format:%h ./docker/user-devel/Dockerfile)"

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
