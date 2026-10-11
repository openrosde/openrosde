#!/bin/bash

# This script builds the Catkin workspaces of one platform in the CI, inside a container of the platform image of the pipeline.
# The repository goes into the container through 'docker cp', rather than a bind mount, since the Docker-in-Docker daemon cannot see the files of the job on every runner.
# On failure, the Catkin logs are copied to 'ci-logs/' for the artifacts of the job.
#
# Usage: bash ./gitlab-ci/test-catkin-workspaces.bash <robot-platform>
#
# <robot-platform>: The platform whose image and workspaces to test, such as 'ur5e'.

################################################################################

# Name the image of the platform in this pipeline and the container that builds the workspaces.
SDE_CI_IMAGE_NAME="${CI_REGISTRY_IMAGE}/$1-devel:pipeline-${CI_PIPELINE_ID}"
SDE_CI_CONTAINER_NAME="sde-ci-$1"
SDE_CONTAINER_ROOT_DIR=/root/SDE

################################################################################

# Apply the patches of the Git submodules, which the CI checks out without them.
bash ./scripts/apply-submodule-patches.bash "${PWD}"

################################################################################

# Create the container, copy the repository into it, then reset and build the workspaces.
docker create \
  --name "${SDE_CI_CONTAINER_NAME}" \
  --env "SDE_ROBOT_PLATFORM=$1" \
  --env "SDE_CONTAINER_ROOT_DIR=${SDE_CONTAINER_ROOT_DIR}" \
  "${SDE_CI_IMAGE_NAME}" \
  bash ${SDE_CONTAINER_ROOT_DIR}/docker/sde-base/scripts/reset-catkin-workspaces.bash || exit 1
docker cp "${PWD}/." "${SDE_CI_CONTAINER_NAME}:${SDE_CONTAINER_ROOT_DIR}/" || exit 1
docker start --attach "${SDE_CI_CONTAINER_NAME}"
SDE_CI_EXIT_CODE=$?

################################################################################

# Keep the Catkin logs of every workspace when the build fails.
if [ "${SDE_CI_EXIT_CODE}" -ne 0 ]; then
  for SDE_CI_CATKIN_WS in ros/*_catkin_ws; do
    mkdir -p "ci-logs/${SDE_CI_CATKIN_WS}"
    docker cp "${SDE_CI_CONTAINER_NAME}:${SDE_CONTAINER_ROOT_DIR}/${SDE_CI_CATKIN_WS}/logs" "ci-logs/${SDE_CI_CATKIN_WS}/" > /dev/null 2>&1
  done
fi
exit ${SDE_CI_EXIT_CODE}
