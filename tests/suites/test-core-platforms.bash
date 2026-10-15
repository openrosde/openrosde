#!/bin/bash

# This suite checks the platforms of the core and the canonical platforms cloned into 'extensions/' of the repository under test, with no other extension: the switch, the folders and workspaces, the Docker Compose files, the images, and the platform scripts.
# The canonical platforms live in repositories of their own, 'openrosde-platform-<platform>', so the suite checks those that a developer cloned into 'extensions/', and names the others that it skips.
# The bringup and the Chrony restart run with the fake platform 'rover' of the extension 'openrosde-platform-rover', which the suite writes.
#
# Usage: bash ./tests/run.bash test-core-platforms

################################################################################

# Load the helpers and create the scratch copy, with the canonical platforms that the repository under test holds in 'extensions/'.
source "${OPENROSDE_TEST_SOURCE_DIR}/tests/load-test-helpers.bash"
openrosde-test-create-copy
mkdir -p "${OPENROSDE_TEST_ROOT_DIR}/.git"
OPENROSDE_TEST_REGISTRY="registry.gitlab.com/coarobo/sde"
OPENROSDE_TEST_CLONED_PLATFORM_NAMES=""
for OPENROSDE_TEST_PLATFORM_NAME in cobotta fetch hsr sciurus17 turtlebot3; do
  if openrosde-test-copy-cloned-extension "openrosde-platform-${OPENROSDE_TEST_PLATFORM_NAME}"; then
    OPENROSDE_TEST_CLONED_PLATFORM_NAMES="${OPENROSDE_TEST_CLONED_PLATFORM_NAMES} ${OPENROSDE_TEST_PLATFORM_NAME}"
  else
    echo "Skipping the platform '${OPENROSDE_TEST_PLATFORM_NAME}', which is not cloned into 'extensions/openrosde-platform-${OPENROSDE_TEST_PLATFORM_NAME}/'."
  fi
done
OPENROSDE_TEST_PLATFORM_NAMES="$( (openrosde-test-print-core-platforms; printf '%s\n' ${OPENROSDE_TEST_CLONED_PLATFORM_NAMES}) | sort)"

################################################################################

# Check the listings of the platforms and the setups, which hold the platforms of the core and of the clones, and nothing else.
openrosde-test-run bash ./scripts/list-robot-platforms.bash
openrosde-test-check "lists the platforms of the core and of the clones" "$(printf '%s\n' ${OPENROSDE_TEST_PLATFORM_NAMES}) 0" "${OPENROSDE_TEST_OUTPUT} ${OPENROSDE_TEST_EXIT_CODE}"
openrosde-test-run bash ./scripts/list-robot-setups.bash
openrosde-test-check "lists the default setups of the core and of the clones" "$(printf '%s\n' ${OPENROSDE_TEST_PLATFORM_NAMES}) 0" "${OPENROSDE_TEST_OUTPUT} ${OPENROSDE_TEST_EXIT_CODE}"

################################################################################

# Check each platform after switching to it, in the core or in its clone.
for OPENROSDE_TEST_PLATFORM_NAME in ${OPENROSDE_TEST_PLATFORM_NAMES}; do
  echo "Platform '${OPENROSDE_TEST_PLATFORM_NAME}':"
  OPENROSDE_TEST_PLATFORM_ROOT="."
  OPENROSDE_TEST_ACTIVE_ROOTS="."
  if [ ! -f "${OPENROSDE_TEST_ROOT_DIR}/env/${OPENROSDE_TEST_PLATFORM_NAME}.env" ]; then
    OPENROSDE_TEST_PLATFORM_ROOT="./extensions/openrosde-platform-${OPENROSDE_TEST_PLATFORM_NAME}"
    OPENROSDE_TEST_ACTIVE_ROOTS=". ${OPENROSDE_TEST_PLATFORM_ROOT}"
  fi

  # The switch copies the template of the platform to '.env.custom' and updates the Git submodules of the core first.
  openrosde-test-run bash ./SWITCH-ROBOT-PLATFORM.bash "${OPENROSDE_TEST_PLATFORM_NAME}"
  openrosde-test-check "switches to '${OPENROSDE_TEST_PLATFORM_NAME}' and updates the submodules" \
    "0 same git -C . submodule update --init --recursive" \
    "${OPENROSDE_TEST_EXIT_CODE} $(cmp -s "${OPENROSDE_TEST_ROOT_DIR}/${OPENROSDE_TEST_PLATFORM_ROOT}/env/${OPENROSDE_TEST_PLATFORM_NAME}.env" "${OPENROSDE_TEST_ROOT_DIR}/.env.custom" && echo same) $(openrosde-test-print-calls | grep -m 1 '^git ')"

  # The platform, its setup, and its workspace come from the folder that holds the platform.
  openrosde-test-check "resolves the folders and workspaces of '${OPENROSDE_TEST_PLATFORM_NAME}' in '${OPENROSDE_TEST_PLATFORM_ROOT}'" \
    "$(printf '%s\n' "platform-root: ${OPENROSDE_TEST_PLATFORM_ROOT}" "setup: ${OPENROSDE_TEST_PLATFORM_NAME}" "setup-root: ${OPENROSDE_TEST_PLATFORM_ROOT}" "active: ${OPENROSDE_TEST_ACTIVE_ROOTS}" "workspaces: ./ros/openrosde_catkin_ws ${OPENROSDE_TEST_PLATFORM_ROOT}/ros/${OPENROSDE_TEST_PLATFORM_NAME}_catkin_ws ./ros/user_catkin_ws")" \
    "$(openrosde-test-print-paths | grep -E '^(platform-root|setup|setup-root|active|workspaces):')"

  # The container runs with the base file, the overlay of the platform, and the user overlay.
  openrosde-test-run bash ./RUN-DOCKER-CONTAINER.bash test --no-exec
  openrosde-test-check "runs the container of '${OPENROSDE_TEST_PLATFORM_NAME}' with its overlay" \
    "docker compose -p test -f ./docker/docker-compose.yaml -f ${OPENROSDE_TEST_PLATFORM_ROOT}/docker/docker-compose-${OPENROSDE_TEST_PLATFORM_NAME}.yaml -f ./docker/docker-compose-user.yaml up -d openrosde" \
    "$(openrosde-test-print-calls | grep '^docker compose')"

  # The images are pulled, the user overlay is built on the platform image, and no layer is built.
  openrosde-test-run bash ./BUILD-DOCKER-IMAGE.bash test
  openrosde-test-check "builds the images of '${OPENROSDE_TEST_PLATFORM_NAME}' without layers" \
    "$(printf '%s\n' \
      "docker compose -p test -f ./docker/docker-compose.yaml pull openrosde-base" \
      "docker compose -p test -f ./docker/docker-compose.yaml pull openrosde-mesh2glb" \
      "docker compose -p test -f ./docker/docker-compose.yaml pull openrosde-platform" \
      "docker compose -p test -f ./docker/docker-compose.yaml build openrosde" \
      "layers: " \
      "user-parent: ${OPENROSDE_TEST_REGISTRY}/${OPENROSDE_TEST_PLATFORM_NAME}-devel:dev" \
      "platform-dockerfile: docker/${OPENROSDE_TEST_PLATFORM_NAME}-devel/Dockerfile")" \
    "$(openrosde-test-print-calls | grep -E '^docker (compose|build)'; openrosde-test-print-paths | grep -E '^(user-parent|platform-dockerfile|layers):')"

  # The scripts and layouts of the platform come from the folder that holds it, where they exist.
  OPENROSDE_TEST_EXPECTED_FILES=""
  for OPENROSDE_TEST_SETUP_FILE in "scripts/%s/bringup-ros-robot.bash" "scripts/%s/restart-chrony-service.bash" "scripts/%s/initialize-bash-shell.bash" "terminator/%s.config" "tmux/%s.panes"; do
    OPENROSDE_TEST_RELATIVE_PATH="$(printf "${OPENROSDE_TEST_SETUP_FILE}" "${OPENROSDE_TEST_PLATFORM_NAME}")"
    if [ -e "${OPENROSDE_TEST_ROOT_DIR}/${OPENROSDE_TEST_PLATFORM_ROOT}/${OPENROSDE_TEST_RELATIVE_PATH}" ]; then
      OPENROSDE_TEST_EXPECTED_FILES="${OPENROSDE_TEST_EXPECTED_FILES}setup-file ${OPENROSDE_TEST_SETUP_FILE}: ${OPENROSDE_TEST_PLATFORM_ROOT}/${OPENROSDE_TEST_RELATIVE_PATH}"$'\n'
    else
      OPENROSDE_TEST_EXPECTED_FILES="${OPENROSDE_TEST_EXPECTED_FILES}setup-file ${OPENROSDE_TEST_SETUP_FILE}: "$'\n'
    fi
  done
  openrosde-test-check "resolves the scripts and layouts of '${OPENROSDE_TEST_PLATFORM_NAME}' in '${OPENROSDE_TEST_PLATFORM_ROOT}'" \
    "${OPENROSDE_TEST_EXPECTED_FILES%$'\n'}" \
    "$(openrosde-test-print-paths | grep '^setup-file ')"
done

################################################################################

# Check that the bringup and the Chrony restart run the scripts of a platform outside the core, with 'ssh' and 'sudo' stubbed.
echo "Platform scripts:"
openrosde-test-create-extension openrosde-platform-rover
openrosde-test-write-platform-template extensions/openrosde-platform-rover rover
openrosde-test-write-file extensions/openrosde-platform-rover/scripts/rover/bringup-ros-robot.bash 'ssh -f -t -l rover rover.local "export ROS_MASTER_URI=http://$1:11311"'
openrosde-test-write-file extensions/openrosde-platform-rover/scripts/rover/restart-chrony-service.bash 'ssh -t -l rover rover.local "sudo service chrony restart"'
openrosde-test-select-template extensions/openrosde-platform-rover/env/rover.env
openrosde-test-run bash ./BRINGUP-ROS-ROBOT.bash rosmaster-host test
OPENROSDE_TEST_BRINGUP_CALL="$(openrosde-test-print-calls | grep -m 1 '^ssh ')"
openrosde-test-run bash ./RESTART-CHRONY-SERVICE.bash test
openrosde-test-check "runs the bringup and the Chrony restart of a platform outside the core" \
  "$(printf '%s\n' "ssh -f -t -l rover rover.local export ROS_MASTER_URI=http://rosmaster-host:11311" "sudo service chrony restart" "sudo systemctl status --no-pager chrony" "chronyc sources" "ssh -t -l rover rover.local sudo service chrony restart")" \
  "$(printf '%s\n' "${OPENROSDE_TEST_BRINGUP_CALL}"; openrosde-test-print-calls | grep -E '^(sudo|chronyc|ssh) [^;]*$')"

################################################################################

# Check that the entry scripts stop with a hint when the selected platform is cloned nowhere, as in a fresh clone of the core whose '.env' selects a platform of its own repository.
openrosde-test-write-file .env.custom "OPENROSDE_ROBOT_PLATFORM=missingbot" "OPENROSDE_ROBOT_SETUP=missingbot"
openrosde-test-run bash ./RUN-DOCKER-CONTAINER.bash test --no-exec
openrosde-test-check "stops before Docker with the clone of the platform when it is cloned nowhere" \
  "$(printf '%s\n' "status 1" \
    "Error: The platform 'missingbot' that '.env' or '.env.custom' selects is found neither in the core nor in a repository cloned into 'extensions/'." \
    "  git clone https://gitlab.com/coarobo/openrosde/openrosde-platform-missingbot.git extensions/openrosde-platform-missingbot" \
    "  bash ./SWITCH-ROBOT-PLATFORM.bash missingbot" \
    "docker calls: 0")" \
  "$(echo "status ${OPENROSDE_TEST_EXIT_CODE}"; echo "${OPENROSDE_TEST_OUTPUT}" | grep -E "^(Error|  git clone|  bash)"; echo "docker calls: $(openrosde-test-print-calls | grep -c '^docker ')")"

################################################################################

# Remove the scratch copy and report the result.
openrosde-test-remove-copy
openrosde-test-finish-suite
