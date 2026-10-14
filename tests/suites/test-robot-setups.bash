#!/bin/bash

# This suite checks a setup 'my-lab-foo-bench', held by the extension 'my-lab', which runs the platform extension 'foo' with the device 'bar' and lists both in its '.repos' file.
# It covers the listings, the switch with and without 'vcstool', the active folders and workspaces, the precedence of the files of the setup, the overlays, the switch back to the platform, and an old '.env.custom' of the UR5e that names no setup.
#
# Usage: bash ./tests/run.bash test-robot-setups

################################################################################

# Load the helpers and create the scratch copy.
source "${OPENROSDE_TEST_SOURCE_DIR}/tests/load-test-helpers.bash"
openrosde-test-create-copy
OPENROSDE_TEST_FOO_DIR="extensions/openrosde-platform-foo"
OPENROSDE_TEST_BAR_DIR="extensions/openrosde-device-bar"
OPENROSDE_TEST_LAB_DIR="extensions/my-lab"
OPENROSDE_TEST_SETUP_NAME="my-lab-foo-bench"

# Create the platform extension 'foo', with a bringup and a Chrony script.
openrosde-test-create-extension openrosde-platform-foo
openrosde-test-write-platform-template "${OPENROSDE_TEST_FOO_DIR}" foo
mkdir -p "${OPENROSDE_TEST_ROOT_DIR}/${OPENROSDE_TEST_FOO_DIR}/ros/foo_catkin_ws/src"
openrosde-test-write-file "${OPENROSDE_TEST_FOO_DIR}/docker/docker-compose-foo.yaml" "services: {}"
openrosde-test-write-file "${OPENROSDE_TEST_FOO_DIR}/scripts/foo/bringup-ros-robot.bash" 'ssh foo-robot "roslaunch foo_bringup robot.launch"'
openrosde-test-write-file "${OPENROSDE_TEST_FOO_DIR}/scripts/foo/restart-chrony-service.bash" 'ssh foo-robot "sudo service chrony restart"'
openrosde-test-write-file "${OPENROSDE_TEST_FOO_DIR}/terminator/foo.config" "[layouts]"

# Create the device 'bar'.
openrosde-test-create-extension openrosde-device-bar
mkdir -p "${OPENROSDE_TEST_ROOT_DIR}/${OPENROSDE_TEST_BAR_DIR}/ros/bar_catkin_ws/src"
openrosde-test-write-file "${OPENROSDE_TEST_BAR_DIR}/docker/docker-compose-bar.yaml" "services: {}"

# Create the extension 'my-lab' with the setup, its '.repos' file, workspace, overlay, bringup, and layout.
openrosde-test-create-extension my-lab
openrosde-test-write-setup-template "${OPENROSDE_TEST_LAB_DIR}" "${OPENROSDE_TEST_SETUP_NAME}" foo "openrosde-device-bar"
openrosde-test-write-file "${OPENROSDE_TEST_LAB_DIR}/env/${OPENROSDE_TEST_SETUP_NAME}.repos" \
  "repositories:" \
  "  openrosde-platform-foo:" \
  "    type: git" \
  "    url: https://gitlab.example.com/acme/openrosde-platform-foo.git" \
  "    version: v1.0.0" \
  "  openrosde-device-bar:" \
  "    type: git" \
  "    url: https://gitlab.example.com/acme/openrosde-device-bar.git" \
  "    version: v1.0.0"
mkdir -p "${OPENROSDE_TEST_ROOT_DIR}/${OPENROSDE_TEST_LAB_DIR}/ros/my_lab_catkin_ws/src"
openrosde-test-write-file "${OPENROSDE_TEST_LAB_DIR}/docker/docker-compose-${OPENROSDE_TEST_SETUP_NAME}.yaml" "services: {}"
openrosde-test-write-file "${OPENROSDE_TEST_LAB_DIR}/scripts/${OPENROSDE_TEST_SETUP_NAME}/bringup-ros-robot.bash" 'ssh my-lab-robot "roslaunch my_lab_bringup bench.launch"'
openrosde-test-write-file "${OPENROSDE_TEST_LAB_DIR}/terminator/${OPENROSDE_TEST_SETUP_NAME}.config" "[layouts]"

################################################################################

# Check the listings of the setups and the platforms.
openrosde-test-run bash ./scripts/list-robot-setups.bash
openrosde-test-check "lists the setup beside the default setups" \
  "$(printf '%s\n' cobotta fetch foo hsr "${OPENROSDE_TEST_SETUP_NAME}" sciurus17 turtlebot3 ur5e)" \
  "${OPENROSDE_TEST_OUTPUT}"
openrosde-test-run bash ./scripts/list-robot-platforms.bash
openrosde-test-check "lists the platform of the extension, but not the setup" \
  "$(printf '%s\n' cobotta fetch foo hsr sciurus17 turtlebot3 ur5e)" \
  "${OPENROSDE_TEST_OUTPUT}"

################################################################################

# Check the switch to the setup.
openrosde-test-run bash ./SWITCH-ROBOT-SETUP.bash "${OPENROSDE_TEST_SETUP_NAME}"
openrosde-test-check "refuses the setup without 'vcstool', and leaves '.env.custom' alone" \
  "1 needs 'vcs' from 'vcstool' no-env-custom" \
  "${OPENROSDE_TEST_EXIT_CODE} $(echo "${OPENROSDE_TEST_OUTPUT}" | grep -o "needs 'vcs' from 'vcstool'") $([ -e "${OPENROSDE_TEST_ROOT_DIR}/.env.custom" ] || echo no-env-custom)"
openrosde-test-run bash ./SWITCH-ROBOT-SETUP.bash my-lab-nowhere
openrosde-test-check "refuses a setup that no template declares" \
  "1 Error: Setup 'my-lab-nowhere' not found." \
  "${OPENROSDE_TEST_EXIT_CODE} $(echo "${OPENROSDE_TEST_OUTPUT}" | grep -m 1 '^Error:')"
openrosde-test-add-stub vcs
openrosde-test-run bash ./SWITCH-ROBOT-SETUP.bash "${OPENROSDE_TEST_SETUP_NAME}"
openrosde-test-check "clones the repositories of the setup with 'vcs import'" \
  "vcs import --skip-existing --input ./${OPENROSDE_TEST_LAB_DIR}/env/${OPENROSDE_TEST_SETUP_NAME}.repos ./extensions" \
  "$(openrosde-test-print-calls | grep '^vcs ')"
openrosde-test-check "switches to the setup" \
  "0 same" \
  "${OPENROSDE_TEST_EXIT_CODE} $(cmp -s "${OPENROSDE_TEST_ROOT_DIR}/${OPENROSDE_TEST_LAB_DIR}/env/${OPENROSDE_TEST_SETUP_NAME}.env" "${OPENROSDE_TEST_ROOT_DIR}/.env.custom" && echo same)"

################################################################################

# Check the folders, the workspaces, and the files of the setup.
openrosde-test-check "activates the core, the platform, the device, then the setup" \
  ". ./${OPENROSDE_TEST_FOO_DIR} ./${OPENROSDE_TEST_BAR_DIR} ./${OPENROSDE_TEST_LAB_DIR}" \
  "$(openrosde-test-print-path active)"
openrosde-test-check "builds the workspace of the setup last, before the user" \
  "./ros/openrosde_catkin_ws ./${OPENROSDE_TEST_FOO_DIR}/ros/foo_catkin_ws ./${OPENROSDE_TEST_BAR_DIR}/ros/bar_catkin_ws ./${OPENROSDE_TEST_LAB_DIR}/ros/my_lab_catkin_ws ./ros/user_catkin_ws" \
  "$(openrosde-test-print-path workspaces)"
openrosde-test-run bash ./BRINGUP-ROS-ROBOT.bash rosmaster-host test
openrosde-test-check "runs the bringup of the setup over that of the platform" \
  "ssh my-lab-robot roslaunch my_lab_bringup bench.launch" \
  "$(openrosde-test-print-calls | grep '^ssh ')"
openrosde-test-run bash ./RESTART-CHRONY-SERVICE.bash test
openrosde-test-check "runs the Chrony script of the platform when the setup has none" \
  "ssh foo-robot sudo service chrony restart" \
  "$(openrosde-test-print-calls | grep '^ssh ')"
openrosde-test-run bash ./RUN-TERMINATOR-TERMINAL.bash test
openrosde-test-check "opens the Terminator layout of the setup, named after the platform" \
  "$(printf '%s\n' "setup-file terminator/%s.config: ./${OPENROSDE_TEST_LAB_DIR}/terminator/${OPENROSDE_TEST_SETUP_NAME}.config" "terminator --maximise --config ./terminator/foo.config.tmp --layout openrosde-foo-term-11-default-gazebo")" \
  "$(openrosde-test-print-paths | grep '^setup-file terminator/'; openrosde-test-print-calls | grep '^terminator ')"
openrosde-test-run bash ./RUN-DOCKER-CONTAINER.bash test --no-exec
openrosde-test-check "runs the container with the overlays of the platform, the device, then the setup" \
  "docker compose -p test -f ./docker/docker-compose.yaml -f ./${OPENROSDE_TEST_FOO_DIR}/docker/docker-compose-foo.yaml -f ./${OPENROSDE_TEST_BAR_DIR}/docker/docker-compose-bar.yaml -f ./${OPENROSDE_TEST_LAB_DIR}/docker/docker-compose-${OPENROSDE_TEST_SETUP_NAME}.yaml -f ./docker/docker-compose-user.yaml up -d openrosde" \
  "$(openrosde-test-print-calls | grep '^docker compose')"

################################################################################

# Check the switch back to the default setup of the platform.
openrosde-test-run bash ./SWITCH-ROBOT-PLATFORM.bash foo
openrosde-test-check "switches back to the default setup of the platform" \
  "0 same" \
  "${OPENROSDE_TEST_EXIT_CODE} $(cmp -s "${OPENROSDE_TEST_ROOT_DIR}/${OPENROSDE_TEST_FOO_DIR}/env/foo.env" "${OPENROSDE_TEST_ROOT_DIR}/.env.custom" && echo same)"
openrosde-test-check "leaves the device and the setup inactive on the default setup" \
  "$(printf '%s\n' "active: . ./${OPENROSDE_TEST_FOO_DIR}" "workspaces: ./ros/openrosde_catkin_ws ./${OPENROSDE_TEST_FOO_DIR}/ros/foo_catkin_ws ./ros/user_catkin_ws")" \
  "$(openrosde-test-print-paths | grep -E '^(active|workspaces):')"

################################################################################

# Check an old '.env.custom' of the UR5e, written before setups existed, while '.env' names the TurtleBot3 setup.
openrosde-test-write-file .env.custom "OPENROSDE_ROBOT_PLATFORM=ur5e" "OPENROSDE_ROS_MASTER_HOSTNAME=localhost" "OPENROSDE_ROBOT_HOSTNAME="
openrosde-test-check "uses the platform of an old '.env.custom' as its setup" \
  "$(printf '%s\n' "setup: ur5e" "setup-root: .")" \
  "$(openrosde-test-print-paths | grep -E '^(setup|setup-root):')"
openrosde-test-run bash ./BRINGUP-ROS-ROBOT.bash rosmaster-host test
openrosde-test-check "runs no TurtleBot3 script for an old '.env.custom' of the UR5e" \
  "No robot bringup is configured for the 'ur5e' platform. Please start the robot manually." \
  "$(echo "${OPENROSDE_TEST_OUTPUT}" | grep '^No robot bringup'; openrosde-test-print-calls | grep '^ssh ')"
openrosde-test-run bash ./RUN-TERMINATOR-TERMINAL.bash test
openrosde-test-check "keeps the Terminator layout of the UR5e for an old '.env.custom'" \
  "$(printf '%s\n' "setup-file terminator/%s.config: ./terminator/ur5e.config" "terminator --maximise --config ./terminator/ur5e.config.tmp --layout openrosde-ur5e-term-11-default-gazebo")" \
  "$(openrosde-test-print-paths | grep '^setup-file terminator/'; openrosde-test-print-calls | grep '^terminator ')"

################################################################################

# Remove the scratch copy and report the result.
openrosde-test-remove-copy
openrosde-test-finish-suite
