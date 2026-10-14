#!/bin/bash

# This script tests one setup in the CI: it builds the Catkin workspaces of the setup inside a container of the image of its platform, with the Docker layers of its extensions on top, then checks that every launch entry point of its 'tmux' sessions resolves, with 'check-launch-files.bash', and runs the checks of its extensions, with 'run-extension-checks.bash'.
# The setup is selected as 'SWITCH-ROBOT-SETUP.bash' selects it, by copying its template 'env/<setup>.env', from the core or from a cloned extension, to '.env.custom', and the extensions of 'OPENROSDE_CI_EXTRA_EXTENSIONS' are added to those it lists.
# The setup 'openrosde' stands for the core alone, with no platform and no extension, whose shared and user workspaces build in the base image.
# The Docker layers are built in the Docker-in-Docker daemon of the job with 'scripts/build-extension-layers.bash', and never pushed.
# The repository goes into the container through 'docker cp', rather than a bind mount, since the Docker-in-Docker daemon cannot see the files of the job on every runner.
# The workspaces build with the network, which the FlexBE app needs to download its runtime, and the container is then disconnected from every network before any check runs, so that no check can reach a robot.
# On failure, the Catkin logs of every workspace of the setup are copied to 'ci-logs/' for the artifacts of the job.
#
# Usage: bash ./gitlab-ci/test-catkin-workspaces.bash <robot-setup> [<image>]
#
# <robot-setup>: The setup to test, such as 'ur5e' or 'acme-ur5e-lab', or 'openrosde' for the core alone.
# [<image>]:     The image to test in, below the Docker layers of the setup.
#                Default value is the image of the platform of the setup in this pipeline, '${OPENROSDE_CI_IMAGE_REGISTRY}/<platform>-devel:pipeline-${CI_PIPELINE_ID}', or the base image for 'openrosde'.

################################################################################

# Name the container that builds the workspaces and its root directory.
OPENROSDE_CI_CONTAINER_NAME="openrosde-ci-$1"
OPENROSDE_CONTAINER_ROOT_DIR=/root/OpenRoSDE

################################################################################

# Select the setup in '.env.custom': the settings of the core alone for 'openrosde', or else the template of the setup, followed by the settings of the CI job.
if [ "$1" = "openrosde" ]; then
  printf '%s\n' \
    "# Settings of the core alone, with no platform and no extension, written by 'gitlab-ci/test-catkin-workspaces.bash'." \
    "OPENROSDE_ROBOT_PLATFORM=" \
    "OPENROSDE_ROBOT_SETUP=" \
    "OPENROSDE_ROBOT_EXTENSIONS=" > .env.custom
else
  source ./scripts/load-extension-paths.bash "${PWD}"
  OPENROSDE_CI_SETUP_ENV_FILE="$(openrosde-find-extension-file "env/$1.env")"
  if [ -z "${OPENROSDE_CI_SETUP_ENV_FILE}" ]; then
    echo "Error: Neither the core nor a cloned extension holds the template 'env/$1.env' of the setup '$1'."
    exit 1
  fi
  cp "${OPENROSDE_CI_SETUP_ENV_FILE}" .env.custom
  printf '\n%s\n' "# Settings of the CI job, written by 'gitlab-ci/test-catkin-workspaces.bash'." >> .env.custom
  if [ -n "${OPENROSDE_CI_EXTRA_EXTENSIONS}" ]; then
    echo "OPENROSDE_ROBOT_EXTENSIONS=\"\${OPENROSDE_ROBOT_EXTENSIONS} ${OPENROSDE_CI_EXTRA_EXTENSIONS}\"" >> .env.custom
  fi
fi
echo "OPENROSDE_QUIET=true" >> .env.custom

# Load the settings of the setup as the host scripts do, with the paths of the job, and check them: the setup must be the one selected, its platform must be found, and so must every extension it lists.
if [ "$1" = "openrosde" ]; then
  source ./scripts/load-openrosde-settings.bash "${PWD}"
  OPENROSDE_EXTENSION_DOCKERFILES=()
  OPENROSDE_CI_DEFAULT_IMAGE="${OPENROSDE_CI_IMAGE_REGISTRY}/openrosde-base:pipeline-${CI_PIPELINE_ID}"
  echo "Testing the core alone, with no platform and no extension."
else
  source ./scripts/load-openrosde-env.bash ci
  if [ "${OPENROSDE_ROBOT_SETUP}" != "$1" ]; then
    echo "Error: The template of the setup '$1' does not declare 'OPENROSDE_ROBOT_SETUP=$1' alone on its line."
    exit 1
  fi
  if [[ "${OPENROSDE_DECLARED_PLATFORM_NAMES}" != *" ${OPENROSDE_ROBOT_PLATFORM} "* ]]; then
    echo "Error: The setup '$1' runs the platform '${OPENROSDE_ROBOT_PLATFORM}', which neither the core nor a cloned extension declares."
    exit 1
  fi
  OPENROSDE_CI_MISSING_EXTENSIONS=""
  for OPENROSDE_CI_EXTENSION_NAME in ${OPENROSDE_ROBOT_EXTENSIONS}; do
    openrosde-find-extension-root "${OPENROSDE_CI_EXTENSION_NAME}" > /dev/null || OPENROSDE_CI_MISSING_EXTENSIONS="${OPENROSDE_CI_MISSING_EXTENSIONS} ${OPENROSDE_CI_EXTENSION_NAME}"
  done
  if [ -n "${OPENROSDE_CI_MISSING_EXTENSIONS}" ]; then
    echo "Error: The setup '$1' lists extensions that no single folder holds:${OPENROSDE_CI_MISSING_EXTENSIONS}."
    exit 1
  fi
  OPENROSDE_CI_DEFAULT_IMAGE="${OPENROSDE_CI_IMAGE_REGISTRY}/${OPENROSDE_ROBOT_PLATFORM}-devel:pipeline-${CI_PIPELINE_ID}"
  echo "Testing the setup '$1' of the platform '${OPENROSDE_ROBOT_PLATFORM}' with the extensions '${OPENROSDE_ROBOT_EXTENSIONS}'."
fi

# Name the image to test in, the one given or else the default one.
OPENROSDE_CI_TEST_IMAGE="$2"
if [ -z "${OPENROSDE_CI_TEST_IMAGE}" ]; then
  OPENROSDE_CI_TEST_IMAGE="${OPENROSDE_CI_DEFAULT_IMAGE}"
fi

################################################################################

# Apply the patches of the core, of every cloned extension, and of every part to their own Git submodules, which the CI checks out without them.
for OPENROSDE_CI_PATCHED_ROOT_DIR in "${PWD}/" "${PWD}"/extensions/*/ "${PWD}"/extensions/*/parts/*/; do
  if [ -d "${OPENROSDE_CI_PATCHED_ROOT_DIR}patches" ]; then
    bash ./scripts/apply-submodule-patches.bash "${OPENROSDE_CI_PATCHED_ROOT_DIR%/}"
  fi
done

# Build the Docker layers of the setup on top of the image, without pushing them, and test in the last one.
if [ "${#OPENROSDE_EXTENSION_DOCKERFILES[@]}" -gt 0 ]; then
  source ./scripts/build-extension-layers.bash "${OPENROSDE_CI_TEST_IMAGE}" || exit 1
  OPENROSDE_CI_TEST_IMAGE="${OPENROSDE_USER_PARENT_IMAGE}"
fi

################################################################################

# Create the container with the platform, the setup, and the extensions, and copy the repository into it, with the cloned extensions and '.env.custom'.
# The container only waits, so that every step below runs in it with 'docker exec'.
docker rm --force "${OPENROSDE_CI_CONTAINER_NAME}" > /dev/null 2>&1
docker create \
  --name "${OPENROSDE_CI_CONTAINER_NAME}" \
  --env "OPENROSDE_ROBOT_PLATFORM=${OPENROSDE_ROBOT_PLATFORM}" \
  --env "OPENROSDE_ROBOT_SETUP=${OPENROSDE_ROBOT_SETUP}" \
  --env "OPENROSDE_ROBOT_EXTENSIONS=${OPENROSDE_ROBOT_EXTENSIONS}" \
  --env "OPENROSDE_CONTAINER_ROOT_DIR=${OPENROSDE_CONTAINER_ROOT_DIR}" \
  "${OPENROSDE_CI_TEST_IMAGE}" \
  sleep infinity || exit 1
docker cp "${PWD}/." "${OPENROSDE_CI_CONTAINER_NAME}:${OPENROSDE_CONTAINER_ROOT_DIR}/" || exit 1
docker start "${OPENROSDE_CI_CONTAINER_NAME}" > /dev/null || exit 1

# Reset and build the workspaces, with the settings loaded and exported as in a shell of the container.
docker exec "${OPENROSDE_CI_CONTAINER_NAME}" bash -c "source ${OPENROSDE_CONTAINER_ROOT_DIR}/scripts/load-openrosde-settings.bash ${OPENROSDE_CONTAINER_ROOT_DIR} && bash ${OPENROSDE_CONTAINER_ROOT_DIR}/docker/openrosde-base/scripts/reset-catkin-workspaces.bash"
OPENROSDE_CI_EXIT_CODE=$?

# Disconnect the container from every network, and stop if any network is left, then check the launch entry points and run the checks of the extensions, each even when the other fails.
if [ "${OPENROSDE_CI_EXIT_CODE}" -eq 0 ]; then
  for OPENROSDE_CI_NETWORK_NAME in $(docker inspect --format '{{ range $name, $network := .NetworkSettings.Networks }}{{ $name }} {{ end }}' "${OPENROSDE_CI_CONTAINER_NAME}"); do
    docker network disconnect "${OPENROSDE_CI_NETWORK_NAME}" "${OPENROSDE_CI_CONTAINER_NAME}"
  done
  if [ "$(docker inspect --format '{{ len .NetworkSettings.Networks }}' "${OPENROSDE_CI_CONTAINER_NAME}")" != "0" ]; then
    echo "Error: The container '${OPENROSDE_CI_CONTAINER_NAME}' is still connected to a network, so no check runs in it."
    exit 1
  fi
  echo "Disconnected the container '${OPENROSDE_CI_CONTAINER_NAME}' from every network before the checks."
  docker exec "${OPENROSDE_CI_CONTAINER_NAME}" bash ${OPENROSDE_CONTAINER_ROOT_DIR}/gitlab-ci/check-launch-files.bash "$1" || OPENROSDE_CI_EXIT_CODE=1
  docker exec "${OPENROSDE_CI_CONTAINER_NAME}" bash ${OPENROSDE_CONTAINER_ROOT_DIR}/gitlab-ci/run-extension-checks.bash "$1" || OPENROSDE_CI_EXIT_CODE=1
fi

################################################################################

# Keep the Catkin logs of every workspace of the setup when the test fails.
if [ "${OPENROSDE_CI_EXIT_CODE}" -ne 0 ]; then
  for OPENROSDE_CI_CATKIN_WS in "${OPENROSDE_CATKIN_WORKSPACE_DIRS[@]}"; do
    OPENROSDE_CI_CATKIN_WS="${OPENROSDE_CI_CATKIN_WS#${PWD}/}"
    mkdir -p "ci-logs/${OPENROSDE_CI_CATKIN_WS}"
    docker cp "${OPENROSDE_CI_CONTAINER_NAME}:${OPENROSDE_CONTAINER_ROOT_DIR}/${OPENROSDE_CI_CATKIN_WS}/logs" "ci-logs/${OPENROSDE_CI_CATKIN_WS}/" > /dev/null 2>&1
  done
fi
exit ${OPENROSDE_CI_EXIT_CODE}
