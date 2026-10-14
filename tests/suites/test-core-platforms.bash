#!/bin/bash

# This suite checks the six platforms of the core with no extension cloned: the switch, the folders and workspaces, the Docker Compose files, the images, and the platform scripts.
#
# Usage: bash ./tests/run.bash test-core-platforms

################################################################################

# Load the helpers and create the scratch copy.
source "${OPENROSDE_TEST_SOURCE_DIR}/tests/load-test-helpers.bash"
openrosde-test-create-copy
mkdir -p "${OPENROSDE_TEST_ROOT_DIR}/.git"
OPENROSDE_TEST_PLATFORM_NAMES="cobotta fetch hsr sciurus17 turtlebot3 ur5e"
OPENROSDE_TEST_REGISTRY="registry.gitlab.com/coarobo/sde"

################################################################################

# Check the listings of the platforms and the setups, which hold the six platforms and nothing else.
openrosde-test-run bash ./scripts/list-robot-platforms.bash
openrosde-test-check "lists the six platforms of the core" "$(printf '%s\n' ${OPENROSDE_TEST_PLATFORM_NAMES}) 0" "${OPENROSDE_TEST_OUTPUT} ${OPENROSDE_TEST_EXIT_CODE}"
openrosde-test-run bash ./scripts/list-robot-setups.bash
openrosde-test-check "lists the six default setups of the core" "$(printf '%s\n' ${OPENROSDE_TEST_PLATFORM_NAMES}) 0" "${OPENROSDE_TEST_OUTPUT} ${OPENROSDE_TEST_EXIT_CODE}"

################################################################################

# Check each platform after switching to it.
for OPENROSDE_TEST_PLATFORM_NAME in ${OPENROSDE_TEST_PLATFORM_NAMES}; do
  echo "Platform '${OPENROSDE_TEST_PLATFORM_NAME}':"

  # The switch copies the template of the platform to '.env.custom' and updates the Git submodules of the core.
  openrosde-test-run bash ./SWITCH-ROBOT-PLATFORM.bash "${OPENROSDE_TEST_PLATFORM_NAME}"
  openrosde-test-check "switches to '${OPENROSDE_TEST_PLATFORM_NAME}' and updates the submodules" \
    "0 same git -C . submodule update --init --recursive" \
    "${OPENROSDE_TEST_EXIT_CODE} $(cmp -s "${OPENROSDE_TEST_ROOT_DIR}/env/${OPENROSDE_TEST_PLATFORM_NAME}.env" "${OPENROSDE_TEST_ROOT_DIR}/.env.custom" && echo same) $(openrosde-test-print-calls | grep -m 1 '^git ')"

  # The platform, its setup, and its workspaces come from the core.
  openrosde-test-check "resolves the folders and workspaces of '${OPENROSDE_TEST_PLATFORM_NAME}' in the core" \
    "$(printf '%s\n' "platform-root: ." "setup: ${OPENROSDE_TEST_PLATFORM_NAME}" "setup-root: ." "active: ." "workspaces: ./ros/openrosde_catkin_ws ./ros/${OPENROSDE_TEST_PLATFORM_NAME}_catkin_ws ./ros/user_catkin_ws")" \
    "$(openrosde-test-print-paths | grep -E '^(platform-root|setup|setup-root|active|workspaces):')"

  # The container runs with the base file, the overlay of the platform, and the user overlay.
  openrosde-test-run bash ./RUN-DOCKER-CONTAINER.bash test --no-exec
  openrosde-test-check "runs the container of '${OPENROSDE_TEST_PLATFORM_NAME}' with its overlay" \
    "docker compose -p test -f ./docker/docker-compose.yaml -f ./docker/docker-compose-${OPENROSDE_TEST_PLATFORM_NAME}.yaml -f ./docker/docker-compose-user.yaml up -d openrosde" \
    "$(openrosde-test-print-calls | grep '^docker compose')"

  # The images are pulled, the user overlay is built on the platform image, and no layer is built.
  openrosde-test-run bash ./BUILD-DOCKER-IMAGE.bash test
  openrosde-test-check "builds the images of '${OPENROSDE_TEST_PLATFORM_NAME}' without layers" \
    "$(printf '%s\n' \
      "docker compose -p test -f ./docker/docker-compose.yaml pull openrosde-base" \
      "docker compose -p test -f ./docker/docker-compose.yaml pull openrosde-platform" \
      "docker compose -p test -f ./docker/docker-compose.yaml build openrosde" \
      "layers: " \
      "user-parent: ${OPENROSDE_TEST_REGISTRY}/${OPENROSDE_TEST_PLATFORM_NAME}-devel:dev" \
      "platform-dockerfile: docker/${OPENROSDE_TEST_PLATFORM_NAME}-devel/Dockerfile")" \
    "$(openrosde-test-print-calls | grep -E '^docker (compose|build)'; openrosde-test-print-paths | grep -E '^(user-parent|platform-dockerfile|layers):')"

  # The scripts and layouts of the platform come from the core, where they exist.
  OPENROSDE_TEST_EXPECTED_FILES=""
  for OPENROSDE_TEST_SETUP_FILE in "scripts/%s/bringup-ros-robot.bash" "scripts/%s/restart-chrony-service.bash" "scripts/%s/initialize-bash-shell.bash" "terminator/%s.config" "tmux/%s.panes"; do
    OPENROSDE_TEST_RELATIVE_PATH="$(printf "${OPENROSDE_TEST_SETUP_FILE}" "${OPENROSDE_TEST_PLATFORM_NAME}")"
    if [ -e "${OPENROSDE_TEST_ROOT_DIR}/${OPENROSDE_TEST_RELATIVE_PATH}" ]; then
      OPENROSDE_TEST_EXPECTED_FILES="${OPENROSDE_TEST_EXPECTED_FILES}setup-file ${OPENROSDE_TEST_SETUP_FILE}: ./${OPENROSDE_TEST_RELATIVE_PATH}"$'\n'
    else
      OPENROSDE_TEST_EXPECTED_FILES="${OPENROSDE_TEST_EXPECTED_FILES}setup-file ${OPENROSDE_TEST_SETUP_FILE}: "$'\n'
    fi
  done
  openrosde-test-check "resolves the scripts and layouts of '${OPENROSDE_TEST_PLATFORM_NAME}' in the core" \
    "${OPENROSDE_TEST_EXPECTED_FILES%$'\n'}" \
    "$(openrosde-test-print-paths | grep '^setup-file ')"
done

################################################################################

# Check that the bringup and the Chrony restart run the scripts of the platform, with 'ssh' and 'sudo' stubbed.
echo "Platform scripts:"
openrosde-test-select-template env/turtlebot3.env
openrosde-test-run bash ./BRINGUP-ROS-ROBOT.bash rosmaster-host test
OPENROSDE_TEST_BRINGUP_CALL="$(openrosde-test-print-calls | grep -m 1 '^ssh ')"
openrosde-test-select-template env/sciurus17.env
openrosde-test-run bash ./RESTART-CHRONY-SERVICE.bash test
openrosde-test-check "runs the bringup of 'turtlebot3' and the Chrony restart of 'sciurus17'" \
  "$(printf '%s\n' "ssh -f -t -l pi turtlebot3.local bash -c \"" "sudo service chrony restart" "sudo systemctl status --no-pager chrony" "chronyc sources" "ssh -t -l sciurus sciurus-host.local bash -l -c \"")" \
  "$(printf '%s\n' "${OPENROSDE_TEST_BRINGUP_CALL}"; openrosde-test-print-calls | grep -E '^(sudo|chronyc|ssh) [^;]*$')"

################################################################################

# Remove the scratch copy and report the result.
openrosde-test-remove-copy
openrosde-test-finish-suite
