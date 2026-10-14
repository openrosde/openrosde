#!/bin/bash

# This script builds the Catkin workspaces of one platform in the CI, inside a container of the platform image of the pipeline, then checks that every launch entry point of its 'tmux' sessions resolves, with 'check-launch-files.bash'.
# The repository goes into the container through 'docker cp', rather than a bind mount, since the Docker-in-Docker daemon cannot see the files of the job on every runner.
# On failure, the Catkin logs are copied to 'ci-logs/' for the artifacts of the job.
#
# Usage: bash ./gitlab-ci/test-catkin-workspaces.bash <robot-platform>
#
# <robot-platform>: The platform whose image and workspaces to test, such as 'ur5e'.

################################################################################

# Name the image of the platform in this pipeline and the container that builds the workspaces.
OPENROSDE_CI_IMAGE_NAME="${CI_REGISTRY_IMAGE}/$1-devel:pipeline-${CI_PIPELINE_ID}"
OPENROSDE_CI_CONTAINER_NAME="openrosde-ci-$1"
OPENROSDE_CONTAINER_ROOT_DIR=/root/OpenRoSDE

################################################################################

# Apply the patches of the Git submodules, which the CI checks out without them.
bash ./scripts/apply-submodule-patches.bash "${PWD}"

################################################################################

# Create the container, copy the repository into it, then reset and build the workspaces, and check the launch entry points.
docker create \
  --name "${OPENROSDE_CI_CONTAINER_NAME}" \
  --env "OPENROSDE_ROBOT_PLATFORM=$1" \
  --env "OPENROSDE_CONTAINER_ROOT_DIR=${OPENROSDE_CONTAINER_ROOT_DIR}" \
  "${OPENROSDE_CI_IMAGE_NAME}" \
  bash -c "bash ${OPENROSDE_CONTAINER_ROOT_DIR}/docker/openrosde-base/scripts/reset-catkin-workspaces.bash && bash ${OPENROSDE_CONTAINER_ROOT_DIR}/gitlab-ci/check-launch-files.bash $1" || exit 1
docker cp "${PWD}/." "${OPENROSDE_CI_CONTAINER_NAME}:${OPENROSDE_CONTAINER_ROOT_DIR}/" || exit 1
docker start --attach "${OPENROSDE_CI_CONTAINER_NAME}"
OPENROSDE_CI_EXIT_CODE=$?

################################################################################

# Keep the Catkin logs of every workspace when the build fails.
if [ "${OPENROSDE_CI_EXIT_CODE}" -ne 0 ]; then
  for OPENROSDE_CI_CATKIN_WS in ros/*_catkin_ws; do
    mkdir -p "ci-logs/${OPENROSDE_CI_CATKIN_WS}"
    docker cp "${OPENROSDE_CI_CONTAINER_NAME}:${OPENROSDE_CONTAINER_ROOT_DIR}/${OPENROSDE_CI_CATKIN_WS}/logs" "ci-logs/${OPENROSDE_CI_CATKIN_WS}/" > /dev/null 2>&1
  done
fi
exit ${OPENROSDE_CI_EXIT_CODE}
