#!/bin/bash

# This script prints the child pipeline of OpenRoSDE in YAML: the shared jobs of 'gitlab-ci/openrosde-pipeline.yml', one image job per platform, one test job per setup, and the test jobs of the core alone on ROS 1 and on ROS 2, with the check of the robot model through a 'rosbridge' that fragments.
# The platforms and the setups are found by name, in the core and in the extensions that 'gitlab-ci/clone-extensions.bash' cloned, as 'scripts/list-robot-platforms.bash' and 'scripts/list-robot-setups.bash' list them, so adding one changes nothing here.
# The image job of a platform builds it from the folder that holds it, the core, an extension, or a part, on the base image of the ROS that its template declares, and the test job of a setup needs the image job of its platform and 'check-scripts-job'.
# When 'OPENROSDE_CI_EXTENSION_OVERRIDE' names an extension to test at another version, the pipeline tests only the setups that activate that extension, with the extensions of 'OPENROSDE_CI_EXTRA_EXTENSIONS' added to those they list, and builds only their platforms.
# The child pipeline receives no variable of the pipeline that started this one, so this script writes the override, the extra extensions, and the tag of the runner into it, once it has checked that each holds only the characters of its format.
#
# Usage: bash ./gitlab-ci/generate-ci-pipeline.bash > <child-pipeline-file>

################################################################################

# Resolve the repository root directory relative to this script.
OPENROSDE_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Refuse a variable of the pipeline whose value does not match its format, given as a regular expression and in words, since the scripts source it and the child pipeline reads it as written.
function openrosde-ci-check-variable-format () {
  if ! [[ "${!1}" =~ $2 ]]; then
    echo "Error: '$1' $3, but it is '${!1}'." >&2
    exit 1
  fi
}
openrosde-ci-check-variable-format OPENROSDE_CI_RUNNER_TAG '^[A-Za-z0-9_.:/-]+$' "must name the tag of a runner, with letters, digits, and '_.:/-' alone"
openrosde-ci-check-variable-format OPENROSDE_CI_EXTENSION_OVERRIDE '^([A-Za-z0-9_.-]+=[A-Za-z0-9][A-Za-z0-9._/-]*@[0-9a-f]{40})?$' "must read '<name>=<branch>@<commit>', with the full hash of the commit"
openrosde-ci-check-variable-format OPENROSDE_CI_EXTRA_EXTENSIONS '^[A-Za-z0-9_. -]*$' "may hold only folder names separated by spaces"

# List the platforms and the setups, found by name, and fail when a listing fails, such as for a template that declares its setup with quotes, which would otherwise drop out of the pipeline.
OPENROSDE_CI_PLATFORM_NAMES="$(bash "${OPENROSDE_ROOT_DIR}/scripts/list-robot-platforms.bash")" || {
  echo "Error: 'scripts/list-robot-platforms.bash' failed, so the pipeline would leave out a platform." >&2
  exit 1
}
OPENROSDE_CI_SETUP_NAMES="$(bash "${OPENROSDE_ROOT_DIR}/scripts/list-robot-setups.bash")" || {
  echo "Error: 'scripts/list-robot-setups.bash' failed, so the pipeline would leave out a setup." >&2
  exit 1
}

# Name the folder of the extension to test at another version, if any.
OPENROSDE_CI_OVERRIDE_DIR=""
if [ -n "${OPENROSDE_CI_EXTENSION_OVERRIDE}" ]; then
  OPENROSDE_CI_OVERRIDE_DIR="${OPENROSDE_ROOT_DIR}/extensions/${OPENROSDE_CI_EXTENSION_OVERRIDE%%=*}"
fi

# Print the base image of the ROS of a platform, 'openrosde-base' or 'openrosde-base-ros2', as the loader names it from the template of the platform.
function openrosde-ci-describe-platform-base () {
  (
    source "${OPENROSDE_ROOT_DIR}/.env"
    source "${OPENROSDE_ROOT_DIR}/scripts/load-extension-paths.bash" "${OPENROSDE_ROOT_DIR}"
    source "$(openrosde-find-extension-file "env/$1.env")"
    source "${OPENROSDE_ROOT_DIR}/scripts/load-extension-paths.bash" "${OPENROSDE_ROOT_DIR}"
    echo "${OPENROSDE_BASE_IMAGE_NAME}"
  )
}

# Print the platform of a setup, the folder that holds the platform, and the active folders of the setup, one per line, as the loader resolves them with the extensions of 'OPENROSDE_CI_EXTRA_EXTENSIONS' added.
function openrosde-ci-describe-setup () {
  (
    source "${OPENROSDE_ROOT_DIR}/.env"
    source "${OPENROSDE_ROOT_DIR}/scripts/load-extension-paths.bash" "${OPENROSDE_ROOT_DIR}"
    source "$(openrosde-find-extension-file "env/$1.env")"
    OPENROSDE_ROBOT_EXTENSIONS="${OPENROSDE_ROBOT_EXTENSIONS} ${OPENROSDE_CI_EXTRA_EXTENSIONS}"
    source "${OPENROSDE_ROOT_DIR}/scripts/load-extension-paths.bash" "${OPENROSDE_ROOT_DIR}"
    echo "${OPENROSDE_ROBOT_PLATFORM}"
    echo "${OPENROSDE_ROBOT_PLATFORM_ROOT_DIR}"
    printf '%s\n' "${OPENROSDE_ACTIVE_ROOT_DIRS[@]}"
  )
}

################################################################################

# Keep every setup, or only those that activate the extension of the override, and the platforms they run.
OPENROSDE_CI_TESTED_SETUPS=""
OPENROSDE_CI_TESTED_PLATFORMS=""
for OPENROSDE_CI_SETUP_NAME in ${OPENROSDE_CI_SETUP_NAMES}; do
  OPENROSDE_CI_SETUP_DESCRIPTION="$(openrosde-ci-describe-setup "${OPENROSDE_CI_SETUP_NAME}")"
  OPENROSDE_CI_SETUP_PLATFORM="$(echo "${OPENROSDE_CI_SETUP_DESCRIPTION}" | sed -n 1p)"
  if ! printf '%s\n' ${OPENROSDE_CI_PLATFORM_NAMES} | grep -qxF -e "${OPENROSDE_CI_SETUP_PLATFORM}"; then
    echo "Error: The setup '${OPENROSDE_CI_SETUP_NAME}' runs the platform '${OPENROSDE_CI_SETUP_PLATFORM}', which neither the core nor a cloned extension declares." >&2
    exit 1
  fi
  if [ -n "${OPENROSDE_CI_OVERRIDE_DIR}" ] && ! echo "${OPENROSDE_CI_SETUP_DESCRIPTION}" | sed 1,2d | grep -q -x -F -e "${OPENROSDE_CI_OVERRIDE_DIR}" && ! echo "${OPENROSDE_CI_SETUP_DESCRIPTION}" | sed 1,2d | grep -q -F -e "${OPENROSDE_CI_OVERRIDE_DIR}/"; then
    continue
  fi
  OPENROSDE_CI_TESTED_SETUPS="${OPENROSDE_CI_TESTED_SETUPS}${OPENROSDE_CI_SETUP_NAME} ${OPENROSDE_CI_SETUP_PLATFORM}"$'\n'
done
if [ -n "${OPENROSDE_CI_OVERRIDE_DIR}" ]; then
  if [ -z "${OPENROSDE_CI_TESTED_SETUPS}" ]; then
    echo "Error: No setup activates the extension '${OPENROSDE_CI_EXTENSION_OVERRIDE%%=*}' of 'OPENROSDE_CI_EXTENSION_OVERRIDE', so nothing would test it: name it in 'OPENROSDE_CI_EXTRA_EXTENSIONS' to add it to every setup." >&2
    exit 1
  fi
  OPENROSDE_CI_TESTED_PLATFORMS="$(printf '%s' "${OPENROSDE_CI_TESTED_SETUPS}" | awk '{ print $2 }' | sort -u)"
else
  OPENROSDE_CI_TESTED_PLATFORMS="${OPENROSDE_CI_PLATFORM_NAMES}"
fi

################################################################################

# Print the header, the shared jobs, and the variables of the pipeline that the child pipeline needs, checked above.
echo "# Child pipeline of OpenRoSDE, generated by 'gitlab-ci/generate-ci-pipeline.bash'."
echo ""
echo "include:"
echo "  - local: gitlab-ci/openrosde-pipeline.yml"
echo ""
echo "variables:"
echo "  OPENROSDE_CI_RUNNER_TAG: \"${OPENROSDE_CI_RUNNER_TAG}\""
echo "  OPENROSDE_CI_EXTENSION_OVERRIDE: \"${OPENROSDE_CI_EXTENSION_OVERRIDE}\""
echo "  OPENROSDE_CI_EXTRA_EXTENSIONS: \"${OPENROSDE_CI_EXTRA_EXTENSIONS}\""

# Print the image job of every platform, built from the folder that holds it, given from the repository root.
# A platform on ROS 2 builds on 'openrosde-base-ros2', whose image job is 'build-base-ros2-image-job', and whose sources are its folder and the scripts that it copies from 'docker/openrosde-base/scripts', while a platform on ROS 1 keeps the defaults of '.build-platform-image'.
source "${OPENROSDE_ROOT_DIR}/scripts/load-extension-paths.bash" "${OPENROSDE_ROOT_DIR}"
for OPENROSDE_PLATFORM_NAME in ${OPENROSDE_CI_TESTED_PLATFORMS}; do
  OPENROSDE_CI_PLATFORM_ROOT_DIR="$(openrosde-find-platform-root-dir "${OPENROSDE_PLATFORM_NAME}")"
  OPENROSDE_CI_PLATFORM_ROOT_DIR="${OPENROSDE_CI_PLATFORM_ROOT_DIR#${OPENROSDE_ROOT_DIR}}"
  OPENROSDE_CI_PLATFORM_ROOT_DIR="${OPENROSDE_CI_PLATFORM_ROOT_DIR#/}"
  if [ -z "${OPENROSDE_CI_PLATFORM_ROOT_DIR}" ]; then
    OPENROSDE_CI_PLATFORM_ROOT_DIR="."
  fi
  OPENROSDE_CI_PLATFORM_BASE_IMAGE="$(openrosde-ci-describe-platform-base "${OPENROSDE_PLATFORM_NAME}")"
  if [ -z "${OPENROSDE_CI_PLATFORM_BASE_IMAGE}" ]; then
    echo "Error: The template of the platform '${OPENROSDE_PLATFORM_NAME}' declares no ROS that OpenRoSDE runs, since 'OPENROSDE_ROS_VERSION' must be '1' or '2'." >&2
    exit 1
  fi
  echo ""
  echo "build-${OPENROSDE_PLATFORM_NAME}-image-job:"
  echo "  extends: .build-platform-image"
  if [ "${OPENROSDE_CI_PLATFORM_BASE_IMAGE}" != "openrosde-base" ]; then
    echo "  needs:"
    echo "    - build-${OPENROSDE_CI_PLATFORM_BASE_IMAGE#openrosde-}-image-job"
  fi
  echo "  variables:"
  echo "    OPENROSDE_ROBOT_PLATFORM: ${OPENROSDE_PLATFORM_NAME}"
  echo "    OPENROSDE_CI_PLATFORM_ROOT_DIR: ${OPENROSDE_CI_PLATFORM_ROOT_DIR}"
  if [ "${OPENROSDE_CI_PLATFORM_BASE_IMAGE}" != "openrosde-base" ]; then
    echo "    OPENROSDE_CI_BASE_IMAGE_NAME: ${OPENROSDE_CI_PLATFORM_BASE_IMAGE}"
    echo "    OPENROSDE_CI_BASE_SOURCE_DIRS: docker/${OPENROSDE_CI_PLATFORM_BASE_IMAGE},docker/openrosde-base/scripts"
  fi
done

# Print the test job of every setup, which needs the image of its platform and the check of the scripts.
while read -r OPENROSDE_CI_SETUP_NAME OPENROSDE_CI_SETUP_PLATFORM; do
  if [ -z "${OPENROSDE_CI_SETUP_NAME}" ]; then
    continue
  fi
  echo ""
  echo "test-${OPENROSDE_CI_SETUP_NAME}-workspaces-job:"
  echo "  extends: .test-setup"
  echo "  needs:"
  echo "    - build-${OPENROSDE_CI_SETUP_PLATFORM}-image-job"
  echo "    - build-mesh2glb-image-job"
  echo "    - check-scripts-job"
  echo "  variables:"
  echo "    OPENROSDE_CI_ROBOT_SETUP: ${OPENROSDE_CI_SETUP_NAME}"
done <<< "${OPENROSDE_CI_TESTED_SETUPS}"

# Print the test jobs of the core alone, with no platform, in the base images of ROS 1 and ROS 2, unless the pipeline tests one extension, which need the check of the scripts too.
# The job 'robot-model-fragments-job' tests the core alone on ROS 2 again, with the robot model fetched through a 'rosbridge' that splits every message above 1,000,000 bytes into 'fragment' messages, which a client reassembles.
if [ -z "${OPENROSDE_CI_OVERRIDE_DIR}" ]; then
  echo ""
  echo "test-core-workspaces-job:"
  echo "  extends: .test-setup"
  echo "  needs:"
  echo "    - build-base-image-job"
  echo "    - build-mesh2glb-image-job"
  echo "    - check-scripts-job"
  echo "  variables:"
  echo "    OPENROSDE_CI_ROBOT_SETUP: openrosde"
  echo ""
  echo "test-core-ros2-workspaces-job:"
  echo "  extends: .test-setup"
  echo "  needs:"
  echo "    - build-base-ros2-image-job"
  echo "    - build-mesh2glb-image-job"
  echo "    - check-scripts-job"
  echo "  variables:"
  echo "    OPENROSDE_CI_ROBOT_SETUP: openrosde-ros2"
  echo ""
  echo "robot-model-fragments-job:"
  echo "  extends: .test-setup"
  echo "  needs:"
  echo "    - build-base-ros2-image-job"
  echo "    - build-mesh2glb-image-job"
  echo "    - check-scripts-job"
  echo "  variables:"
  echo "    OPENROSDE_CI_ROBOT_SETUP: openrosde-ros2"
  echo "    OPENROSDE_CI_ROBOT_MODEL_ARGS: --fragments"
fi

# Print the publish job, which waits for every image, every test, and the check of the scripts.
echo ""
echo "publish-images-job:"
echo "  extends: .publish-images"
echo "  needs:"
echo "    - build-base-image-job"
echo "    - build-base-ros2-image-job"
echo "    - build-mesh2glb-image-job"
echo "    - check-scripts-job"
echo "    - check-mesh-glbs-job"
if [ -z "${OPENROSDE_CI_OVERRIDE_DIR}" ]; then
  echo "    - test-core-workspaces-job"
  echo "    - test-core-ros2-workspaces-job"
  echo "    - robot-model-fragments-job"
fi
for OPENROSDE_PLATFORM_NAME in ${OPENROSDE_CI_TESTED_PLATFORMS}; do
  echo "    - build-${OPENROSDE_PLATFORM_NAME}-image-job"
done
printf '%s' "${OPENROSDE_CI_TESTED_SETUPS}" | awk '{ print "    - test-" $1 "-workspaces-job" }'
echo "  variables:"
echo "    OPENROSDE_CI_PLATFORM_IMAGES: \"$(for OPENROSDE_PLATFORM_NAME in ${OPENROSDE_CI_TESTED_PLATFORMS}; do printf '%s-devel ' "${OPENROSDE_PLATFORM_NAME}"; done | sed 's/ $//')\""
