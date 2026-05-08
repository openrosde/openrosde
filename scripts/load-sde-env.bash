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

# Export shared SDE variables so that they can be interpolated in 'docker-compose.yaml'.
export SDE_USER_ID="$(id -u)"
export SDE_GROUP_ID="$(id -g)"
export SDE_ROBOT_PLATFORM
export SDE_CONTAINER_ROOT_DIR
export SDE_DOCKER_PROJECT
export SDE_BASE_DOCKERFILE_COMMIT_SHORT_SHA="$(git -C "${SDE_ROOT_DIR}" log -n 1 --pretty=format:%h ./docker/sde-base/Dockerfile)"
export SDE_ROBOT_PLATFORM_DOCKERFILE_COMMIT_SHORT_SHA="$(git -C "${SDE_ROOT_DIR}" log -n 1 --pretty=format:%h ./docker/${SDE_ROBOT_PLATFORM}-devel/Dockerfile)"
export SDE_USER_DEVEL_DOCKERFILE_COMMIT_SHORT_SHA="$(git -C "${SDE_ROOT_DIR}" log -n 1 --pretty=format:%h ./docker/user-devel/Dockerfile)"

# Export user overlay variables so that they can be interpolated in 'docker-compose-user.yaml'.
export SDE_USER_EXAMPLE_VAR

# Export platform-specific variables so that they can be interpolated in 'docker-compose-${SDE_ROBOT_PLATFORM}.yaml'.
if [ "${SDE_ROBOT_PLATFORM}" = "ur5e" ]; then
  export SDE_UR5E_TEACH_PENDANT_IP
  export SDE_ONROBOT_COMPUTE_BOX_IP
  export SDE_UR5E_ENABLE_EXTERNAL_CAMERA
  export SDE_UR5E_WRIST_CAMERA_SERIAL_NO
  export SDE_UR5E_EXTERNAL_CAMERA_SERIAL_NO
  export SDE_UR5E_EXTERNAL_CAMERA_X
  export SDE_UR5E_EXTERNAL_CAMERA_Y
  export SDE_UR5E_EXTERNAL_CAMERA_Z
  export SDE_UR5E_EXTERNAL_CAMERA_ROLL
  export SDE_UR5E_EXTERNAL_CAMERA_PITCH
  export SDE_UR5E_EXTERNAL_CAMERA_YAW
fi

################################################################################

# Print shared SDE variables for debugging purposes.
echo "$0: SDE_USER_ID=${SDE_USER_ID}"
echo "$0: SDE_GROUP_ID=${SDE_GROUP_ID}"
echo "$0: SDE_ROBOT_PLATFORM=${SDE_ROBOT_PLATFORM}"
echo "$0: SDE_CONTAINER_ROOT_DIR=${SDE_CONTAINER_ROOT_DIR}"
echo "$0: SDE_DOCKER_PROJECT=${SDE_DOCKER_PROJECT}"
echo "$0: SDE_DOCKER_CONTAINER=${SDE_DOCKER_CONTAINER}"
echo "$0: SDE_BASE_DOCKERFILE_COMMIT_SHORT_SHA=${SDE_BASE_DOCKERFILE_COMMIT_SHORT_SHA}"
echo "$0: SDE_ROBOT_PLATFORM_DOCKERFILE_COMMIT_SHORT_SHA=${SDE_ROBOT_PLATFORM_DOCKERFILE_COMMIT_SHORT_SHA}"
echo "$0: SDE_USER_DEVEL_DOCKERFILE_COMMIT_SHORT_SHA=${SDE_USER_DEVEL_DOCKERFILE_COMMIT_SHORT_SHA}"

# Print user overlay variables for debugging purposes.
echo "$0: SDE_USER_EXAMPLE_VAR=${SDE_USER_EXAMPLE_VAR}"

# Print platform-specific variables for debugging purposes.
if [ "${SDE_ROBOT_PLATFORM}" = "ur5e" ]; then
  echo "$0: SDE_UR5E_TEACH_PENDANT_IP=${SDE_UR5E_TEACH_PENDANT_IP}"
  echo "$0: SDE_ONROBOT_COMPUTE_BOX_IP=${SDE_ONROBOT_COMPUTE_BOX_IP}"
  echo "$0: SDE_UR5E_ENABLE_EXTERNAL_CAMERA=${SDE_UR5E_ENABLE_EXTERNAL_CAMERA}"
  echo "$0: SDE_UR5E_WRIST_CAMERA_SERIAL_NO=${SDE_UR5E_WRIST_CAMERA_SERIAL_NO}"
  echo "$0: SDE_UR5E_EXTERNAL_CAMERA_SERIAL_NO=${SDE_UR5E_EXTERNAL_CAMERA_SERIAL_NO}"
  echo "$0: SDE_UR5E_EXTERNAL_CAMERA_X=${SDE_UR5E_EXTERNAL_CAMERA_X}"
  echo "$0: SDE_UR5E_EXTERNAL_CAMERA_Y=${SDE_UR5E_EXTERNAL_CAMERA_Y}"
  echo "$0: SDE_UR5E_EXTERNAL_CAMERA_Z=${SDE_UR5E_EXTERNAL_CAMERA_Z}"
  echo "$0: SDE_UR5E_EXTERNAL_CAMERA_ROLL=${SDE_UR5E_EXTERNAL_CAMERA_ROLL}"
  echo "$0: SDE_UR5E_EXTERNAL_CAMERA_PITCH=${SDE_UR5E_EXTERNAL_CAMERA_PITCH}"
  echo "$0: SDE_UR5E_EXTERNAL_CAMERA_YAW=${SDE_UR5E_EXTERNAL_CAMERA_YAW}"
fi
