#!/bin/bash

# This script holds the helpers that every test suite of 'tests/suites/' sources: a scratch copy of the repository, stubs of the outside commands, and the checks.
# A suite never runs on the repository itself, and no stub builds an image, starts a container, or reaches a robot.
#
# Usage: source ./tests/load-test-helpers.bash
#
# The helpers read 'OPENROSDE_TEST_SOURCE_DIR', the root directory of the repository under test, which 'tests/run.bash' sets.

################################################################################

# Count the checks of the suite.
OPENROSDE_TEST_PASSED_COUNT=0
OPENROSDE_TEST_FAILED_COUNT=0

# Name the outside commands that every suite replaces with a stub, which logs its call and succeeds.
# 'vcs' is left out, so that a suite adds it only when it needs 'vcstool', and 'tmux' too, since the 'tmux' suite runs the real one.
OPENROSDE_TEST_STUB_NAMES="docker git ssh sudo xhost avahi-resolve terminator roslaunch catkin catkin_init_workspace rosdep apt-get chronyc sleep clear"

################################################################################

# Create a scratch copy of the repository under test in a new temporary folder, with stubs of the outside commands first in 'PATH'.
# The copy leaves out the Git metadata, the cloned extensions, the local settings, and the content of the Catkin workspaces, whose folders are enough for the scripts.
function openrosde-test-create-copy () {
  local OPENROSDE_TEST_CATKIN_WS OPENROSDE_TEST_STUB_NAME
  OPENROSDE_TEST_WORK_DIR="$(mktemp -d)"
  OPENROSDE_TEST_ROOT_DIR="${OPENROSDE_TEST_WORK_DIR}/OpenRoSDE"
  OPENROSDE_TEST_STUB_DIR="${OPENROSDE_TEST_WORK_DIR}/stubs"
  OPENROSDE_TEST_COMMAND_LOG="${OPENROSDE_TEST_WORK_DIR}/commands.log"
  mkdir -p "${OPENROSDE_TEST_ROOT_DIR}/extensions" "${OPENROSDE_TEST_STUB_DIR}"
  tar -C "${OPENROSDE_TEST_SOURCE_DIR}" --exclude=./.git --exclude=./extensions --exclude=./.env.custom --exclude=./ros -cf - . | tar -C "${OPENROSDE_TEST_ROOT_DIR}" -xf -
  for OPENROSDE_TEST_CATKIN_WS in "${OPENROSDE_TEST_SOURCE_DIR}"/ros/*_catkin_ws; do
    mkdir -p "${OPENROSDE_TEST_ROOT_DIR}/ros/$(basename "${OPENROSDE_TEST_CATKIN_WS}")/src"
  done
  for OPENROSDE_TEST_STUB_NAME in ${OPENROSDE_TEST_STUB_NAMES}; do
    openrosde-test-add-stub "${OPENROSDE_TEST_STUB_NAME}"
  done
  : > "${OPENROSDE_TEST_COMMAND_LOG}"
  export OPENROSDE_TEST_COMMAND_LOG
  export PATH="${OPENROSDE_TEST_STUB_DIR}:${PATH}"
  export HOME="${OPENROSDE_TEST_WORK_DIR}"
  export USER="tester"
}

# Add the stub of one outside command, which logs its call to 'OPENROSDE_TEST_COMMAND_LOG' and succeeds.
# 'git log' prints a fixed commit, 'git remote get-url origin' prints the URL written in '<clone>/.git/test-origin-url', 'catkin_init_workspace' logs its folder, and any call that contains 'OPENROSDE_TEST_FAILING_CALL' fails.
function openrosde-test-add-stub () {
  cat > "${OPENROSDE_TEST_STUB_DIR}/$1" <<'EOF'
#!/bin/bash
OPENROSDE_TEST_STUB_CALL="$(basename "$0") $*"
if [ "$(basename "$0")" = "catkin_init_workspace" ]; then
  OPENROSDE_TEST_STUB_CALL="catkin_init_workspace in ${PWD}"
fi
echo "${OPENROSDE_TEST_STUB_CALL}" >> "${OPENROSDE_TEST_COMMAND_LOG}"
case "${OPENROSDE_TEST_STUB_CALL}" in
  "git -C "*" remote get-url origin")
    cat "$2/.git/test-origin-url" 2>/dev/null
    ;;
  "git "*"log -n 1 "*)
    echo -n "abc1234"
    ;;
esac
if [ -n "${OPENROSDE_TEST_FAILING_CALL}" ] && [[ "${OPENROSDE_TEST_STUB_CALL}" == *"${OPENROSDE_TEST_FAILING_CALL}"* ]]; then
  exit 1
fi
exit 0
EOF
  chmod +x "${OPENROSDE_TEST_STUB_DIR}/$1"
}

# Remove the scratch copy and its stubs.
function openrosde-test-remove-copy () {
  rm -rf "${OPENROSDE_TEST_WORK_DIR}"
}

################################################################################

# Write a file of the scratch copy, creating its folder, from the lines given as arguments.
function openrosde-test-write-file () {
  mkdir -p "$(dirname "${OPENROSDE_TEST_ROOT_DIR}/$1")"
  printf '%s\n' "${@:2}" > "${OPENROSDE_TEST_ROOT_DIR}/$1"
}

# Create a fake extension cloned into 'extensions/<extension>/', a folder with an empty '.git' so that it counts as a clone.
function openrosde-test-create-extension () {
  mkdir -p "${OPENROSDE_TEST_ROOT_DIR}/extensions/$1/.git"
}

# Write the environment template of a platform, which is its own default setup, into a folder of the scratch copy.
function openrosde-test-write-platform-template () {
  openrosde-test-write-file "$1/env/$2.env" \
    "# Template of the platform '$2' for the tests." \
    "OPENROSDE_ROBOT_PLATFORM=$2" \
    "OPENROSDE_ROBOT_SETUP=$2" \
    "OPENROSDE_CONTAINER_ROOT_DIR=/root/OpenRoSDE" \
    "OPENROSDE_ROBOT_EXTENSIONS=" \
    "OPENROSDE_ROS_MASTER_HOSTNAME=localhost" \
    "OPENROSDE_ROBOT_HOSTNAME="
}

# Write the environment template of a setup, with its platform and extensions, into a folder of the scratch copy.
function openrosde-test-write-setup-template () {
  openrosde-test-write-file "$1/env/$2.env" \
    "# Template of the setup '$2' for the tests." \
    "OPENROSDE_ROBOT_PLATFORM=$3" \
    "OPENROSDE_ROBOT_SETUP=$2" \
    "OPENROSDE_CONTAINER_ROOT_DIR=/root/OpenRoSDE" \
    "OPENROSDE_ROBOT_EXTENSIONS=\"$4\"" \
    "OPENROSDE_ROS_MASTER_HOSTNAME=localhost" \
    "OPENROSDE_ROBOT_HOSTNAME="
}

# Select a setup or a platform by copying its template, given from the root directory of the scratch copy, to '.env.custom', as 'SWITCH-ROBOT-SETUP.bash' does.
function openrosde-test-select-template () {
  cp "${OPENROSDE_TEST_ROOT_DIR}/$1" "${OPENROSDE_TEST_ROOT_DIR}/.env.custom"
}

################################################################################

# Run a command in the root directory of the scratch copy, and keep its output in 'OPENROSDE_TEST_OUTPUT' and its status in 'OPENROSDE_TEST_EXIT_CODE'.
# The command log starts empty for every run.
function openrosde-test-run () {
  : > "${OPENROSDE_TEST_COMMAND_LOG}"
  OPENROSDE_TEST_OUTPUT="$(cd "${OPENROSDE_TEST_ROOT_DIR}" && "$@" 2>&1 < /dev/null)"
  OPENROSDE_TEST_EXIT_CODE=$?
}

# Print the calls of the stubs during the last run, with the paths of the scratch copy written from its root directory as '.'.
function openrosde-test-print-calls () {
  sed "s#${OPENROSDE_TEST_ROOT_DIR}#.#g" "${OPENROSDE_TEST_COMMAND_LOG}"
}

# Print what 'scripts/load-openrosde-env.bash' resolves for the selected setup, one line per item, with the paths of the scratch copy written from its root directory as '.'.
# The arrays that a version of the loader does not define print empty.
function openrosde-test-print-paths () {
  (
    cd "${OPENROSDE_TEST_ROOT_DIR}" || exit 1
    source ./scripts/load-openrosde-env.bash test > /dev/null 2>&1
    echo "platform: ${OPENROSDE_ROBOT_PLATFORM}"
    echo "platform-root: ${OPENROSDE_ROBOT_PLATFORM_ROOT_DIR}"
    echo "setup: ${OPENROSDE_ROBOT_SETUP}"
    echo "setup-root: ${OPENROSDE_ROBOT_SETUP_ROOT_DIR}"
    echo "active: ${OPENROSDE_ACTIVE_ROOT_DIRS[*]}"
    echo "workspaces: ${OPENROSDE_CATKIN_WORKSPACE_DIRS[*]}"
    echo "layers: ${OPENROSDE_EXTENSION_DOCKERFILES[*]}"
    echo "overlays: ${OPENROSDE_COMPOSE_OVERLAY_FILES[*]}"
    echo "panes: ${OPENROSDE_TMUX_PANES_FILES[*]}"
    echo "user-parent: ${OPENROSDE_USER_PARENT_IMAGE}"
    echo "platform-dockerfile: ${OPENROSDE_ROBOT_PLATFORM_DOCKERFILE}"
    for OPENROSDE_TEST_SETUP_FILE in "scripts/%s/bringup-ros-robot.bash" "scripts/%s/restart-chrony-service.bash" "scripts/%s/initialize-bash-shell.bash" "terminator/%s.config" "tmux/%s.panes"; do
      echo "setup-file ${OPENROSDE_TEST_SETUP_FILE}: $(openrosde-find-setup-file "${OPENROSDE_TEST_SETUP_FILE}")"
    done
  ) | sed "s#${OPENROSDE_TEST_ROOT_DIR}#.#g"
}

# Print one item of the output of 'openrosde-test-print-paths', such as 'workspaces'.
function openrosde-test-print-path () {
  openrosde-test-print-paths | sed -n "s#^$1: ##p"
}

################################################################################

# Check that a value is the expected one, and count the check.
function openrosde-test-check () {
  if [ "$2" = "$3" ]; then
    OPENROSDE_TEST_PASSED_COUNT=$((OPENROSDE_TEST_PASSED_COUNT + 1))
    echo "  ok    $1"
  else
    OPENROSDE_TEST_FAILED_COUNT=$((OPENROSDE_TEST_FAILED_COUNT + 1))
    echo "  FAIL  $1"
    echo "    expected:"
    printf '%s\n' "$2" | sed 's/^/      /'
    echo "    actual:"
    printf '%s\n' "$3" | sed 's/^/      /'
  fi
}

# Check that a text contains a line or a fragment, and count the check.
function openrosde-test-check-contains () {
  if [[ "$3" == *"$2"* ]]; then
    openrosde-test-check "$1" "$2" "$2"
  else
    openrosde-test-check "$1" "a text that contains: $2" "$3"
  fi
}

# Print the result of the suite, and end it with a failure status if any check failed.
function openrosde-test-finish-suite () {
  echo "Passed ${OPENROSDE_TEST_PASSED_COUNT} of $((OPENROSDE_TEST_PASSED_COUNT + OPENROSDE_TEST_FAILED_COUNT)) checks."
  [ "${OPENROSDE_TEST_FAILED_COUNT}" -eq 0 ]
}
