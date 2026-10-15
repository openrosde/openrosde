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
OPENROSDE_TEST_STUB_NAMES="docker git ssh sudo xhost avahi-resolve terminator roslaunch catkin catkin_init_workspace rosdep apt-get chronyc sleep clear ros2 colcon pkill"

################################################################################

# Create a scratch copy of the repository under test in a new temporary folder, with stubs of the outside commands first in 'PATH'.
# The copy leaves out the Git metadata, the cloned extensions, the local settings, and the content of the Catkin and colcon workspaces, whose folders are enough for the scripts.
function openrosde-test-create-copy () {
  local OPENROSDE_TEST_CATKIN_WS OPENROSDE_TEST_STUB_NAME
  OPENROSDE_TEST_WORK_DIR="$(mktemp -d)"
  OPENROSDE_TEST_ROOT_DIR="${OPENROSDE_TEST_WORK_DIR}/OpenRoSDE"
  OPENROSDE_TEST_STUB_DIR="${OPENROSDE_TEST_WORK_DIR}/stubs"
  OPENROSDE_TEST_COMMAND_LOG="${OPENROSDE_TEST_WORK_DIR}/commands.log"
  mkdir -p "${OPENROSDE_TEST_ROOT_DIR}/extensions" "${OPENROSDE_TEST_STUB_DIR}"
  tar -C "${OPENROSDE_TEST_SOURCE_DIR}" --exclude=./.git --exclude=./extensions --exclude=./.env.custom --exclude=./ros --exclude=./ros2 -cf - . | tar -C "${OPENROSDE_TEST_ROOT_DIR}" -xf -
  for OPENROSDE_TEST_CATKIN_WS in "${OPENROSDE_TEST_SOURCE_DIR}"/ros/*_catkin_ws "${OPENROSDE_TEST_SOURCE_DIR}"/ros2/*_colcon_ws; do
    if [ -d "${OPENROSDE_TEST_CATKIN_WS}" ]; then
      mkdir -p "${OPENROSDE_TEST_ROOT_DIR}/$(basename "$(dirname "${OPENROSDE_TEST_CATKIN_WS}")")/$(basename "${OPENROSDE_TEST_CATKIN_WS}")/src"
    fi
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
# 'git rev-parse --abbrev-ref HEAD' prints 'OPENROSDE_TEST_GIT_BRANCH', and 'git describe' and 'git tag --points-at HEAD' print 'OPENROSDE_TEST_GIT_TAG', with 'git describe' failing when it is empty, as on a commit without a tag.
# 'git cat-file -e' fails when 'OPENROSDE_TEST_GIT_COMMIT_MISSING' is 'true', as for a commit that the repository does not hold, and 'git show --no-patch' prints a fixed date.
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
  "git "*"rev-parse --abbrev-ref HEAD")
    [ -n "${OPENROSDE_TEST_GIT_BRANCH}" ] && echo "${OPENROSDE_TEST_GIT_BRANCH}"
    ;;
  "git "*"tag --points-at HEAD")
    [ -n "${OPENROSDE_TEST_GIT_TAG}" ] && echo "${OPENROSDE_TEST_GIT_TAG}"
    ;;
  "git "*" describe "*)
    [ -n "${OPENROSDE_TEST_GIT_TAG}" ] || exit 128
    echo "${OPENROSDE_TEST_GIT_TAG}"
    ;;
  "git "*" cat-file -e "*)
    [ "${OPENROSDE_TEST_GIT_COMMIT_MISSING}" != "true" ] || exit 1
    ;;
  "git "*" show --no-patch "*)
    echo "Mon Oct 12 09:00:00 2026 +0900"
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

# Write a platform held by the core of the scratch copy, as a platform of the core may still be: its template, its workspace, its Docker Compose overlay, its panes in two layouts, its Terminator layouts, and its bringup and shell scripts.
# The suites use it rather than a platform of the repository under test, since the canonical platforms live in repositories of their own.
function openrosde-test-write-core-platform () {
  openrosde-test-write-platform-template . "$1"
  mkdir -p "${OPENROSDE_TEST_ROOT_DIR}/ros/$1_catkin_ws/src"
  openrosde-test-write-file "docker/$1-devel/Dockerfile" "FROM scratch"
  openrosde-test-write-file "docker/docker-compose-$1.yaml" "services: {}"
  openrosde-test-write-file "tmux/$1.panes" \
    "# Panes of the platform '$1' for the tests." \
    "default-gazebo     robot  $1_bringup_default_gazebo.launch" \
    "default-realworld  robot  $1_bringup_default_realworld.launch" \
    "*                  robot  $1_rviz_default.launch"
  openrosde-test-write-file "terminator/$1.config" "[layouts]"
  openrosde-test-write-file "scripts/$1/bringup-ros-robot.bash" "ssh -f -t -l $1 $1.local \"export ROS_MASTER_URI=http://\$1:11311\""
  openrosde-test-write-file "scripts/$1/initialize-bash-shell.bash" "export OPENROSDE_TEST_SHELL_PLATFORM=$1"
}

# Print the platforms that the templates of the core of the scratch copy declare, one per line in alphabetical order, so that a suite does not depend on which platforms the core of the repository under test still holds.
function openrosde-test-print-core-platforms () {
  local OPENROSDE_TEST_ENV_FILE OPENROSDE_TEST_ENV_NAME
  for OPENROSDE_TEST_ENV_FILE in "${OPENROSDE_TEST_ROOT_DIR}"/env/*.env; do
    OPENROSDE_TEST_ENV_NAME="$(basename "${OPENROSDE_TEST_ENV_FILE}" .env)"
    if [ -f "${OPENROSDE_TEST_ENV_FILE}" ] && grep -qxF "OPENROSDE_ROBOT_PLATFORM=${OPENROSDE_TEST_ENV_NAME}" "${OPENROSDE_TEST_ENV_FILE}"; then
      echo "${OPENROSDE_TEST_ENV_NAME}"
    fi
  done | sort
}

# Copy an extension that the repository under test holds in 'extensions/<extension>/', such as a canonical platform that a developer cloned, into the scratch copy, as the copy of the core is made: without its Git metadata, with an empty '.git' so that it counts as a clone, and with the folders of its Catkin and colcon workspaces alone.
# Fail when the repository under test holds no such clone.
function openrosde-test-copy-cloned-extension () {
  local OPENROSDE_TEST_CATKIN_WS
  if [ ! -e "${OPENROSDE_TEST_SOURCE_DIR}/extensions/$1/.git" ]; then
    return 1
  fi
  openrosde-test-create-extension "$1"
  tar -C "${OPENROSDE_TEST_SOURCE_DIR}/extensions/$1" --exclude=./.git --exclude=./ros --exclude=./ros2 -cf - . | tar -C "${OPENROSDE_TEST_ROOT_DIR}/extensions/$1" -xf -
  for OPENROSDE_TEST_CATKIN_WS in "${OPENROSDE_TEST_SOURCE_DIR}/extensions/$1"/ros/*_catkin_ws "${OPENROSDE_TEST_SOURCE_DIR}/extensions/$1"/ros2/*_colcon_ws; do
    if [ -d "${OPENROSDE_TEST_CATKIN_WS}" ]; then
      mkdir -p "${OPENROSDE_TEST_ROOT_DIR}/extensions/$1/$(basename "$(dirname "${OPENROSDE_TEST_CATKIN_WS}")")/$(basename "${OPENROSDE_TEST_CATKIN_WS}")/src"
    fi
  done
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
    echo "image-tag: ${OPENROSDE_DOCKER_IMAGE_TAG}"
    echo "local-prefix: ${OPENROSDE_LOCAL_IMAGE_PREFIX}"
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
