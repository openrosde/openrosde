#!/bin/bash

# This script tests one setup in the CI: it builds the Catkin or colcon workspaces of the setup inside a container of the image of its platform, with the Docker layers of its extensions on top, then checks that every launch entry point of its 'tmux' sessions resolves, with 'check-launch-files.bash', and runs the checks of its extensions, with 'run-extension-checks.bash'.
# The setup is selected as 'SWITCH-ROBOT-SETUP.bash' selects it, by copying its template 'env/<setup>.env', from the core or from a cloned extension, to '.env.custom', and the extensions of 'OPENROSDE_CI_EXTRA_EXTENSIONS' are added to those it lists.
# The setup 'openrosde' stands for the core alone, with no platform and no extension, whose shared and user workspaces build in the base image of ROS 1, and the setup 'openrosde-ros2' for the core alone on ROS 2, with the settings of 'env/openrosde-ros2.env', in the base image of ROS 2.
# The Docker layers are built in the Docker-in-Docker daemon of the job with 'scripts/build-extension-layers.bash', and never pushed.
# The repository goes into the container through 'docker cp', rather than a bind mount, since the Docker-in-Docker daemon cannot see the files of the job on every runner.
# The workspaces build with the network, which the FlexBE app needs to download its runtime, and the container is then disconnected from every network before any check runs, so that no check can reach a robot.
# The meshes of the container get their GLBs from the converter image of the same registry and tag, with 'generate-ci-mesh-glbs.bash', before the workspaces build, since a colcon workspace serves the files that its build copied into its install space, and 'check-robot-model.bash' then checks the file service of the robot model through 'rosbridge', with the arguments of 'OPENROSDE_CI_ROBOT_MODEL_ARGS', such as '--fragments'.
# On failure, the logs of every workspace of the setup, 'logs/' of 'catkin build' or 'log/' of 'colcon build', are copied to 'ci-logs/' for the artifacts of the job.
# Outside the CI, where 'CI' is not 'true', it refuses to run in a checkout that holds '.env.custom', which it would replace, so that the setup a developer selected is never lost.
#
# Usage: bash ./gitlab-ci/test-catkin-workspaces.bash <robot-setup> [<image>]
#
# <robot-setup>: The setup to test, such as 'ur5e' or 'acme-ur5e-lab', or 'openrosde' or 'openrosde-ros2' for the core alone on ROS 1 or ROS 2.
# [<image>]:     The image to test in, below the Docker layers of the setup.
#                Default value is the image of the platform of the setup, '${OPENROSDE_CI_IMAGE_REGISTRY}/<platform>-devel:${OPENROSDE_CI_IMAGE_TAG}', or the base image of its ROS for 'openrosde' and 'openrosde-ros2'.
#                'gitlab-ci/openrosde-pipeline.yml' sets both variables to the images of the pipeline, and a pipeline of another project sets them to published images, such as 'ghcr.io/openrosde' and 'v3.0.0'.

################################################################################

# Name the container that builds the workspaces and its root directory.
OPENROSDE_CI_CONTAINER_NAME="openrosde-ci-$1"
OPENROSDE_CONTAINER_ROOT_DIR=/root/OpenRoSDE

# Refuse to replace the '.env.custom' of a developer outside the CI.
if [ "${CI}" != "true" ] && [ -f .env.custom ]; then
  echo "Error: This script replaces '.env.custom' with the settings of the setup '$1', so outside the CI it runs only in a checkout without '.env.custom': move it aside first, such as with 'mv .env.custom .env.custom.bak', and back afterwards."
  exit 1
fi

# Check that the image to test in can be named, given or else from the registry and the tag of the images to read.
if [ -z "$2" ] && { [ -z "${OPENROSDE_CI_IMAGE_REGISTRY}" ] || [ -z "${OPENROSDE_CI_IMAGE_TAG}" ]; }; then
  echo "Error: No image was given, and 'OPENROSDE_CI_IMAGE_REGISTRY' and 'OPENROSDE_CI_IMAGE_TAG', which name the default one, are not both set."
  exit 1
fi

# Refuse extra extensions other than folder names separated by spaces, since they are written into '.env.custom', which the job and the container source.
if ! [[ "${OPENROSDE_CI_EXTRA_EXTENSIONS}" =~ ^[A-Za-z0-9_.\ -]*$ ]]; then
  echo "Error: 'OPENROSDE_CI_EXTRA_EXTENSIONS' may hold only folder names separated by spaces, but it is '${OPENROSDE_CI_EXTRA_EXTENSIONS}'."
  exit 1
fi

################################################################################

# Select the setup in '.env.custom': the settings of the core alone for 'openrosde', with those of ROS 2 for 'openrosde-ros2', or else the template of the setup, followed by the settings of the CI job.
if [ "$1" = "openrosde" ] || [ "$1" = "openrosde-ros2" ]; then
  printf '%s\n' \
    "# Settings of the core alone, with no platform and no extension, written by 'gitlab-ci/test-catkin-workspaces.bash'." \
    "OPENROSDE_ROBOT_PLATFORM=" \
    "OPENROSDE_ROBOT_SETUP=" \
    "OPENROSDE_ROBOT_EXTENSIONS=" > .env.custom
  if [ "$1" = "openrosde-ros2" ]; then
    grep -E '^OPENROSDE_ROS_(VERSION|DISTRO)=' env/openrosde-ros2.env >> .env.custom
  fi
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
if [ "$1" = "openrosde" ] || [ "$1" = "openrosde-ros2" ]; then
  source ./scripts/load-openrosde-settings.bash "${PWD}"
  OPENROSDE_EXTENSION_DOCKERFILES=()
  OPENROSDE_CI_DEFAULT_IMAGE="${OPENROSDE_CI_IMAGE_REGISTRY}/${OPENROSDE_BASE_IMAGE_NAME}:${OPENROSDE_CI_IMAGE_TAG}"
  echo "Testing the core alone on ROS ${OPENROSDE_ROS_VERSION}, with no platform and no extension."
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
  OPENROSDE_CI_DEFAULT_IMAGE="${OPENROSDE_CI_IMAGE_REGISTRY}/${OPENROSDE_ROBOT_PLATFORM}-devel:${OPENROSDE_CI_IMAGE_TAG}"
  echo "Testing the setup '$1' of the platform '${OPENROSDE_ROBOT_PLATFORM}' with the extensions '${OPENROSDE_ROBOT_EXTENSIONS}'."
fi

# Name the image to test in, the one given or else the default one.
OPENROSDE_CI_TEST_IMAGE="$2"
if [ -z "${OPENROSDE_CI_TEST_IMAGE}" ]; then
  OPENROSDE_CI_TEST_IMAGE="${OPENROSDE_CI_DEFAULT_IMAGE}"
fi

# Name the converter of robot meshes, of the same registry and tag as the images to read, or none when an image was given without them.
OPENROSDE_CI_MESH2GLB_IMAGE=""
if [ -n "${OPENROSDE_CI_IMAGE_REGISTRY}" ] && [ -n "${OPENROSDE_CI_IMAGE_TAG}" ]; then
  OPENROSDE_CI_MESH2GLB_IMAGE="${OPENROSDE_CI_IMAGE_REGISTRY}/openrosde-mesh2glb:${OPENROSDE_CI_IMAGE_TAG}"
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
# 'JOB_CPUS', which a self-managed runner may set to the CPUs that a job may use, caps the parallel jobs of 'catkin build' in the container, and is empty on the instance runners of GitLab.com, where 'catkin build' uses every CPU of the virtual machine.
docker rm --force "${OPENROSDE_CI_CONTAINER_NAME}" > /dev/null 2>&1
docker create \
  --name "${OPENROSDE_CI_CONTAINER_NAME}" \
  --env "OPENROSDE_ROBOT_PLATFORM=${OPENROSDE_ROBOT_PLATFORM}" \
  --env "OPENROSDE_ROBOT_SETUP=${OPENROSDE_ROBOT_SETUP}" \
  --env "OPENROSDE_ROBOT_EXTENSIONS=${OPENROSDE_ROBOT_EXTENSIONS}" \
  --env "OPENROSDE_CONTAINER_ROOT_DIR=${OPENROSDE_CONTAINER_ROOT_DIR}" \
  --env "OPENROSDE_BUILD_JOBS=${JOB_CPUS:-}" \
  "${OPENROSDE_CI_TEST_IMAGE}" \
  sleep infinity || exit 1
docker cp "${PWD}/." "${OPENROSDE_CI_CONTAINER_NAME}:${OPENROSDE_CONTAINER_ROOT_DIR}/" || exit 1
docker start "${OPENROSDE_CI_CONTAINER_NAME}" > /dev/null || exit 1

# Give the meshes of the container their GLBs before the workspaces build, unless the converter cannot be pulled, such as in the pipeline of an extension before the core publishes it, which skips the check of the robot model.
OPENROSDE_CI_MESH_GLBS_EXIT_CODE=2
if [ -n "${OPENROSDE_CI_MESH2GLB_IMAGE}" ]; then
  bash ./gitlab-ci/generate-ci-mesh-glbs.bash "${OPENROSDE_CI_CONTAINER_NAME}" "${OPENROSDE_CI_MESH2GLB_IMAGE}" "${OPENROSDE_ROS_DISTRO}"
  OPENROSDE_CI_MESH_GLBS_EXIT_CODE=$?
else
  echo "Warning: No converter of robot meshes is named, since 'OPENROSDE_CI_IMAGE_REGISTRY' or 'OPENROSDE_CI_IMAGE_TAG' is not set, so the robot model is not checked."
fi

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
  # Check the robot model that the file service serves, once the meshes got their GLBs.
  case ${OPENROSDE_CI_MESH_GLBS_EXIT_CODE} in
    0) docker exec "${OPENROSDE_CI_CONTAINER_NAME}" bash ${OPENROSDE_CONTAINER_ROOT_DIR}/gitlab-ci/check-robot-model.bash ${OPENROSDE_CI_ROBOT_MODEL_ARGS} || OPENROSDE_CI_EXIT_CODE=1 ;;
    2) ;;
    *) OPENROSDE_CI_EXIT_CODE=1 ;;
  esac
  docker exec "${OPENROSDE_CI_CONTAINER_NAME}" bash ${OPENROSDE_CONTAINER_ROOT_DIR}/gitlab-ci/check-launch-files.bash "$1" || OPENROSDE_CI_EXIT_CODE=1
  docker exec "${OPENROSDE_CI_CONTAINER_NAME}" bash ${OPENROSDE_CONTAINER_ROOT_DIR}/gitlab-ci/run-extension-checks.bash "$1" || OPENROSDE_CI_EXIT_CODE=1
fi

################################################################################

# Keep the logs of every workspace of the setup when the test fails, from 'logs/' of 'catkin build' on ROS 1 or 'log/' of 'colcon build' on ROS 2.
OPENROSDE_CI_LOG_FOLDER=logs
if [ "${OPENROSDE_ROS_VERSION}" = "2" ]; then
  OPENROSDE_CI_LOG_FOLDER=log
fi
if [ "${OPENROSDE_CI_EXIT_CODE}" -ne 0 ]; then
  for OPENROSDE_CI_CATKIN_WS in "${OPENROSDE_CATKIN_WORKSPACE_DIRS[@]}"; do
    OPENROSDE_CI_CATKIN_WS="${OPENROSDE_CI_CATKIN_WS#${PWD}/}"
    mkdir -p "ci-logs/${OPENROSDE_CI_CATKIN_WS}"
    docker cp "${OPENROSDE_CI_CONTAINER_NAME}:${OPENROSDE_CONTAINER_ROOT_DIR}/${OPENROSDE_CI_CATKIN_WS}/${OPENROSDE_CI_LOG_FOLDER}" "ci-logs/${OPENROSDE_CI_CATKIN_WS}/" > /dev/null 2>&1
  done
fi
exit ${OPENROSDE_CI_EXIT_CODE}
