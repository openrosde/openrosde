#!/bin/bash

# This suite checks extensions cloned into 'extensions/': a platform extension 'foo', an active device 'bar', and an extension 'baz' that no setting activates.
# It covers the discovery, the switch, the loader, the workspaces, the Docker Compose overlays, the platform scripts and layout, the layers, the reset of the workspaces, the submodules and patches, and a missing extension.
#
# Usage: bash ./tests/run.bash test-extension-folders

################################################################################

# Load the helpers and create the scratch copy.
source "${OPENROSDE_TEST_SOURCE_DIR}/tests/load-test-helpers.bash"
openrosde-test-create-copy
mkdir -p "${OPENROSDE_TEST_ROOT_DIR}/.git"
OPENROSDE_TEST_REGISTRY="registry.gitlab.com/coarobo/sde"
OPENROSDE_TEST_FOO_DIR="extensions/openrosde-platform-foo"
OPENROSDE_TEST_BAR_DIR="extensions/openrosde-device-bar"
OPENROSDE_TEST_BAZ_DIR="extensions/baz"

# Create the platform extension 'foo', with its template, image, overlay, workspace, scripts, layouts, and a patch of one of its submodules.
openrosde-test-create-extension openrosde-platform-foo
openrosde-test-write-platform-template "${OPENROSDE_TEST_FOO_DIR}" foo
openrosde-test-write-file "${OPENROSDE_TEST_FOO_DIR}/docker/foo-devel/Dockerfile" "FROM scratch"
openrosde-test-write-file "${OPENROSDE_TEST_FOO_DIR}/docker/docker-compose-foo.yaml" "services: {}"
openrosde-test-write-file "${OPENROSDE_TEST_FOO_DIR}/scripts/foo/bringup-ros-robot.bash" 'ssh foo-robot "roslaunch foo_bringup robot.launch master:=$1"'
openrosde-test-write-file "${OPENROSDE_TEST_FOO_DIR}/scripts/foo/initialize-bash-shell.bash" "export FOO_MODEL=standard"
openrosde-test-write-file "${OPENROSDE_TEST_FOO_DIR}/terminator/foo.config" "[layouts]"
openrosde-test-write-file "${OPENROSDE_TEST_FOO_DIR}/tmux/foo.panes" "*  robot  foo_bringup_default_gazebo.launch"
openrosde-test-write-file "${OPENROSDE_TEST_FOO_DIR}/patches/ros/foo_catkin_ws/src/foo_driver/0001-fix-foo-driver.patch" "--- a/README" "+++ b/README"
mkdir -p "${OPENROSDE_TEST_ROOT_DIR}/${OPENROSDE_TEST_FOO_DIR}/ros/foo_catkin_ws/src/foo_driver"

# Create the device 'bar', with a workspace, an overlay, and a layer.
openrosde-test-create-extension openrosde-device-bar
mkdir -p "${OPENROSDE_TEST_ROOT_DIR}/${OPENROSDE_TEST_BAR_DIR}/ros/bar_catkin_ws/src"
openrosde-test-write-file "${OPENROSDE_TEST_BAR_DIR}/docker/docker-compose-bar.yaml" "services: {}"
openrosde-test-write-file "${OPENROSDE_TEST_BAR_DIR}/docker/bar-devel/Dockerfile" "ARG OPENROSDE_PARENT_IMAGE" 'FROM ${OPENROSDE_PARENT_IMAGE}'

# Create the extension 'baz', which no setting activates.
openrosde-test-create-extension baz
mkdir -p "${OPENROSDE_TEST_ROOT_DIR}/${OPENROSDE_TEST_BAZ_DIR}/ros/baz_catkin_ws/src"
openrosde-test-write-file "${OPENROSDE_TEST_BAZ_DIR}/docker/docker-compose-baz.yaml" "services: {}"
openrosde-test-write-file "${OPENROSDE_TEST_BAZ_DIR}/tmux/baz.panes" "*  baz  baz_default.launch"

################################################################################

# Check the discovery of the platform and the switch to it.
openrosde-test-run bash ./scripts/list-robot-platforms.bash
openrosde-test-check "finds the platform of the extension" \
  "$( (openrosde-test-print-core-platforms; echo foo) | sort)" \
  "${OPENROSDE_TEST_OUTPUT}"
openrosde-test-run bash ./SWITCH-ROBOT-PLATFORM.bash foo
openrosde-test-check "switches to the platform of the extension" \
  "0 same" \
  "${OPENROSDE_TEST_EXIT_CODE} $(cmp -s "${OPENROSDE_TEST_ROOT_DIR}/${OPENROSDE_TEST_FOO_DIR}/env/foo.env" "${OPENROSDE_TEST_ROOT_DIR}/.env.custom" && echo same)"

# Activate the device beside the platform.
echo 'OPENROSDE_ROBOT_EXTENSIONS="openrosde-device-bar"' >> "${OPENROSDE_TEST_ROOT_DIR}/.env.custom"

################################################################################

# Check what the loader resolves.
openrosde-test-check "finds the platform and its default setup in the extension" \
  "$(printf '%s\n' "platform-root: ./${OPENROSDE_TEST_FOO_DIR}" "setup: foo" "setup-root: ./${OPENROSDE_TEST_FOO_DIR}")" \
  "$(openrosde-test-print-paths | grep -E '^(platform-root|setup|setup-root):')"
openrosde-test-check "activates the core, the platform, and the device, but not 'baz'" \
  ". ./${OPENROSDE_TEST_FOO_DIR} ./${OPENROSDE_TEST_BAR_DIR}" \
  "$(openrosde-test-print-path active)"
openrosde-test-check "builds the workspaces of the core, the platform, the device, then the user" \
  "./ros/openrosde_catkin_ws ./${OPENROSDE_TEST_FOO_DIR}/ros/foo_catkin_ws ./${OPENROSDE_TEST_BAR_DIR}/ros/bar_catkin_ws ./ros/user_catkin_ws" \
  "$(openrosde-test-print-path workspaces)"
openrosde-test-check "finds the Dockerfile of the platform in the extension, relative to the extension" \
  "$(printf '%s\n' "platform-root: ./${OPENROSDE_TEST_FOO_DIR}" "platform-dockerfile: docker/foo-devel/Dockerfile")" \
  "$(openrosde-test-print-paths | grep -E '^(platform-root|platform-dockerfile):')"
openrosde-test-check "finds the shell script of the platform in the extension" \
  "./${OPENROSDE_TEST_FOO_DIR}/scripts/foo/initialize-bash-shell.bash" \
  "$(openrosde-test-print-path 'setup-file scripts/%s/initialize-bash-shell.bash')"

################################################################################

# Check the entry scripts.
openrosde-test-run bash ./RUN-DOCKER-CONTAINER.bash test --no-exec
openrosde-test-check "runs the container with the overlays of the platform and the device, but not of 'baz'" \
  "docker compose -p test -f ./docker/docker-compose.yaml -f ./${OPENROSDE_TEST_FOO_DIR}/docker/docker-compose-foo.yaml -f ./${OPENROSDE_TEST_BAR_DIR}/docker/docker-compose-bar.yaml -f ./docker/docker-compose-user.yaml up -d openrosde" \
  "$(openrosde-test-print-calls | grep '^docker compose')"
openrosde-test-run bash ./BRINGUP-ROS-ROBOT.bash rosmaster-host test
openrosde-test-check "runs the bringup script of the platform" \
  "ssh foo-robot roslaunch foo_bringup robot.launch master:=rosmaster-host" \
  "$(openrosde-test-print-calls | grep '^ssh ')"
openrosde-test-run bash ./RUN-TERMINATOR-TERMINAL.bash test
openrosde-test-check "opens the Terminator layout of the platform" \
  "terminator --maximise --config ./terminator/foo.config.tmp --layout openrosde-foo-term-11-default-gazebo" \
  "$(openrosde-test-print-calls | grep '^terminator ')"
openrosde-test-run bash ./BUILD-DOCKER-IMAGE.bash local
openrosde-test-check "builds the layer of the device on the platform image, and none for the platform" \
  "docker build --build-arg OPENROSDE_PARENT_IMAGE=${OPENROSDE_TEST_REGISTRY}/foo-devel:dev --build-arg OPENROSDE_DOCKERFILE_COMMIT_SHORT_SHA=abc1234 -f ./${OPENROSDE_TEST_BAR_DIR}/docker/bar-devel/Dockerfile -t openrosde-local/foo/bar-devel:latest ./${OPENROSDE_TEST_BAR_DIR}" \
  "$(openrosde-test-print-calls | grep '^docker build')"

# Check the reset of the workspaces, as inside the container.
openrosde-test-run bash -c 'set -a; source ./.env; source ./.env.custom; set +a; OPENROSDE_CONTAINER_ROOT_DIR="${PWD}" bash ./docker/openrosde-base/scripts/reset-catkin-workspaces.bash'
openrosde-test-check "initializes the workspaces in order when it resets them" \
  "$(printf '%s\n' "catkin_init_workspace in ./ros/openrosde_catkin_ws/src" "catkin_init_workspace in ./${OPENROSDE_TEST_FOO_DIR}/ros/foo_catkin_ws/src" "catkin_init_workspace in ./${OPENROSDE_TEST_BAR_DIR}/ros/bar_catkin_ws/src" "catkin_init_workspace in ./ros/user_catkin_ws/src")" \
  "$(openrosde-test-print-calls | grep '^catkin_init_workspace ')"

# Check the parallel jobs of 'catkin build': its defaults, the number that '.env.custom' sets in 'OPENROSDE_BUILD_JOBS', and its defaults with a warning for a value that is not a positive number.
OPENROSDE_TEST_BUILD_JOBS_REPORT="$(openrosde-test-print-calls | grep '^catkin build' | sort | uniq -c)"
cp "${OPENROSDE_TEST_ROOT_DIR}/.env.custom" "${OPENROSDE_TEST_WORK_DIR}/env.custom.before"
for OPENROSDE_TEST_BUILD_JOBS in 8 0; do
  echo "OPENROSDE_BUILD_JOBS=${OPENROSDE_TEST_BUILD_JOBS}" >> "${OPENROSDE_TEST_ROOT_DIR}/.env.custom"
  openrosde-test-run bash -c 'set -a; source ./.env; source ./.env.custom; set +a; OPENROSDE_CONTAINER_ROOT_DIR="${PWD}" bash ./docker/openrosde-base/scripts/reset-catkin-workspaces.bash'
  OPENROSDE_TEST_BUILD_JOBS_REPORT="${OPENROSDE_TEST_BUILD_JOBS_REPORT}"$'\n'"$(openrosde-test-print-calls | grep '^catkin build' | sort | uniq -c; echo "${OPENROSDE_TEST_OUTPUT}" | grep '^Warning: .OPENROSDE_BUILD_JOBS')"
done
cp "${OPENROSDE_TEST_WORK_DIR}/env.custom.before" "${OPENROSDE_TEST_ROOT_DIR}/.env.custom"
openrosde-test-check "builds every workspace with the jobs of 'OPENROSDE_BUILD_JOBS' when it is a positive number, and with every CPU otherwise" \
  "$(printf '%s\n' "      4 catkin build" "      4 catkin build --jobs 8 --parallel-packages 8" "      4 catkin build" "Warning: 'OPENROSDE_BUILD_JOBS' is '0', not a positive number, so 'catkin build' uses every CPU.")" \
  "${OPENROSDE_TEST_BUILD_JOBS_REPORT}"

# Check the submodules of every clone and the patches of the platform extension.
openrosde-test-run bash ./scripts/update-git-submodules.bash
openrosde-test-check "updates the submodules of every clone and applies the patches of each" \
  "$(printf '%s\n' "git -C . submodule update --init --recursive" "git -C ./${OPENROSDE_TEST_BAZ_DIR} submodule update --init --recursive" "git -C ./${OPENROSDE_TEST_BAR_DIR} submodule update --init --recursive" "git -C ./${OPENROSDE_TEST_FOO_DIR} submodule update --init --recursive" "git -C ./${OPENROSDE_TEST_FOO_DIR}/ros/foo_catkin_ws/src/foo_driver apply --check ./${OPENROSDE_TEST_FOO_DIR}/patches/ros/foo_catkin_ws/src/foo_driver/0001-fix-foo-driver.patch")" \
  "$(openrosde-test-print-calls | grep -E '^git -C [^ ]+ (submodule|apply --check)')"

################################################################################

# Check that a missing extension is reported and skipped.
echo 'OPENROSDE_ROBOT_EXTENSIONS="openrosde-device-bar qux"' >> "${OPENROSDE_TEST_ROOT_DIR}/.env.custom"
openrosde-test-run bash ./RUN-DOCKER-CONTAINER.bash test --no-exec
openrosde-test-check "reports and skips an extension that is not cloned" \
  "Extension 'qux' of 'OPENROSDE_ROBOT_EXTENSIONS' . ./${OPENROSDE_TEST_FOO_DIR} ./${OPENROSDE_TEST_BAR_DIR}" \
  "$(echo "${OPENROSDE_TEST_OUTPUT}" | grep -o -m 1 "Extension 'qux' of 'OPENROSDE_ROBOT_EXTENSIONS'") $(openrosde-test-print-path active)"

################################################################################

# Remove the scratch copy and report the result.
openrosde-test-remove-copy
openrosde-test-finish-suite
