#!/bin/bash

# This suite checks the parts of an extension, the lookups scoped to the active folders, and the panes of a setup that replace those of its platform.
# A fake company extension 'acme' holds three parts: 'acme-bench' with the setup 'acme-ur5e-lab' of a UR5e, 'acme-binding' with packages beside a platform, and 'client-robot' with the private platform 'crobot' and its setup 'client-crobot-sim'.
# A device 'openrosde-device-gripper' is cloned beside it, and so is an inactive clone 'aaa-stale-clone', which holds files named after the platforms and the setups but which no setting activates.
#
# Usage: bash ./tests/run.bash test-extension-parts

################################################################################

# Load the helpers and create the scratch copy.
source "${OPENROSDE_TEST_SOURCE_DIR}/tests/load-test-helpers.bash"
openrosde-test-create-copy
OPENROSDE_TEST_ACME_DIR="extensions/acme"
OPENROSDE_TEST_BENCH_DIR="extensions/acme/parts/acme-bench"
OPENROSDE_TEST_BINDING_DIR="extensions/acme/parts/acme-binding"
OPENROSDE_TEST_ROBOT_DIR="extensions/acme/parts/client-robot"
OPENROSDE_TEST_GRIPPER_DIR="extensions/openrosde-device-gripper"
OPENROSDE_TEST_STALE_DIR="extensions/aaa-stale-clone"

# Create the company extension, whose own folder holds no unit.
openrosde-test-create-extension acme
openrosde-test-write-file "${OPENROSDE_TEST_ACME_DIR}/README.md" "# Acme"

# Create the part 'acme-bench' with the setup of a UR5e, which lists the device and the part 'acme-binding', and a patch of one of its submodules.
openrosde-test-write-setup-template "${OPENROSDE_TEST_BENCH_DIR}" acme-ur5e-lab ur5e "openrosde-device-gripper acme-binding"
openrosde-test-write-file "${OPENROSDE_TEST_BENCH_DIR}/env/acme-ur5e-lab.repos" \
  "repositories:" \
  "  openrosde-device-gripper:" \
  "    type: git" \
  "    url: https://gitlab.example.com/acme/openrosde-device-gripper.git" \
  "    version: v1.0.0"
mkdir -p "${OPENROSDE_TEST_ROOT_DIR}/${OPENROSDE_TEST_BENCH_DIR}/ros/acme_bench_catkin_ws/src/acme_driver"
openrosde-test-write-file "${OPENROSDE_TEST_BENCH_DIR}/docker/acme-ur5e-lab-devel/Dockerfile" "ARG OPENROSDE_PARENT_IMAGE" 'FROM ${OPENROSDE_PARENT_IMAGE}'
openrosde-test-write-file "${OPENROSDE_TEST_BENCH_DIR}/docker/docker-compose-acme-ur5e-lab.yaml" "services: {}"
openrosde-test-write-file "${OPENROSDE_TEST_BENCH_DIR}/tmux/acme-ur5e-lab.panes" "*  robot  ur5e_bringup_default_gazebo.launch" "lab-demo  lab  acme_bench_launch:demo.launch"
openrosde-test-write-file "${OPENROSDE_TEST_BENCH_DIR}/scripts/acme-ur5e-lab/bringup-ros-robot.bash" 'ssh acme-ur5e "roslaunch ur_robot_driver ur5e_bringup.launch"'
openrosde-test-write-file "${OPENROSDE_TEST_BENCH_DIR}/terminator/acme-ur5e-lab.config" "[layouts]"
openrosde-test-write-file "${OPENROSDE_TEST_BENCH_DIR}/patches/ros/acme_bench_catkin_ws/src/acme_driver/0001-fix-acme-driver.patch" "--- a/README" "+++ b/README"

# Create the part 'acme-binding' with packages, a layer, an overlay, panes, and panes for the UR5e.
mkdir -p "${OPENROSDE_TEST_ROOT_DIR}/${OPENROSDE_TEST_BINDING_DIR}/ros/acme_binding_catkin_ws/src"
openrosde-test-write-file "${OPENROSDE_TEST_BINDING_DIR}/docker/acme-binding-devel/Dockerfile" "ARG OPENROSDE_PARENT_IMAGE" 'FROM ${OPENROSDE_PARENT_IMAGE}'
openrosde-test-write-file "${OPENROSDE_TEST_BINDING_DIR}/docker/docker-compose-acme-binding.yaml" "services: {}"
openrosde-test-write-file "${OPENROSDE_TEST_BINDING_DIR}/tmux/acme-binding.panes" "*  binding  acme_binding_launch:bridge.launch"
openrosde-test-write-file "${OPENROSDE_TEST_BINDING_DIR}/tmux/ur5e.panes" "*  binding  acme_binding_launch:ur5e_bridge.launch"

# Create the part 'client-robot' with the private platform 'crobot', its setup 'client-crobot-sim', two workspaces, and a layer.
openrosde-test-write-platform-template "${OPENROSDE_TEST_ROBOT_DIR}" crobot
openrosde-test-write-setup-template "${OPENROSDE_TEST_ROBOT_DIR}" client-crobot-sim crobot ""
mkdir -p "${OPENROSDE_TEST_ROOT_DIR}/${OPENROSDE_TEST_ROBOT_DIR}/ros/crobot_catkin_ws/src" "${OPENROSDE_TEST_ROOT_DIR}/${OPENROSDE_TEST_ROBOT_DIR}/ros/client_sim_catkin_ws/src"
openrosde-test-write-file "${OPENROSDE_TEST_ROBOT_DIR}/docker/crobot-devel/Dockerfile" "FROM scratch"
openrosde-test-write-file "${OPENROSDE_TEST_ROBOT_DIR}/docker/client-sim-devel/Dockerfile" "ARG OPENROSDE_PARENT_IMAGE" 'FROM ${OPENROSDE_PARENT_IMAGE}'
openrosde-test-write-file "${OPENROSDE_TEST_ROBOT_DIR}/docker/docker-compose-crobot.yaml" "services: {}"
openrosde-test-write-file "${OPENROSDE_TEST_ROBOT_DIR}/docker/docker-compose-client-crobot-sim.yaml" "services: {}"
openrosde-test-write-file "${OPENROSDE_TEST_ROBOT_DIR}/tmux/crobot.panes" "*  robot  crobot_bringup_default_gazebo.launch"
openrosde-test-write-file "${OPENROSDE_TEST_ROBOT_DIR}/tmux/client-crobot-sim.panes" "*  robot  crobot_bringup_default_gazebo.launch world:=warehouse"
openrosde-test-write-file "${OPENROSDE_TEST_ROBOT_DIR}/scripts/crobot/bringup-ros-robot.bash" 'ssh crobot "roslaunch crobot_bringup robot.launch"'
openrosde-test-write-file "${OPENROSDE_TEST_ROBOT_DIR}/terminator/crobot.config" "[layouts]"

# Create the device, cloned from another URL than the one the setup lists, with a workspace, an overlay for the UR5e, and no pane file.
openrosde-test-create-extension openrosde-device-gripper
echo "https://gitlab.example.com/old-group/openrosde-device-gripper.git" > "${OPENROSDE_TEST_ROOT_DIR}/${OPENROSDE_TEST_GRIPPER_DIR}/.git/test-origin-url"
mkdir -p "${OPENROSDE_TEST_ROOT_DIR}/${OPENROSDE_TEST_GRIPPER_DIR}/ros/gripper_catkin_ws/src"
openrosde-test-write-file "${OPENROSDE_TEST_GRIPPER_DIR}/docker/docker-compose-ur5e.yaml" "services: {}"

# Create the inactive clone, sorted before 'acme', with files named after the platforms and the setups.
openrosde-test-create-extension aaa-stale-clone
mkdir -p "${OPENROSDE_TEST_ROOT_DIR}/${OPENROSDE_TEST_STALE_DIR}/ros/stale_catkin_ws/src"
openrosde-test-write-file "${OPENROSDE_TEST_STALE_DIR}/docker/stale-devel/Dockerfile" "FROM scratch"
for OPENROSDE_TEST_STALE_NAME in ur5e crobot acme-ur5e-lab client-crobot-sim turtlebot3; do
  openrosde-test-write-file "${OPENROSDE_TEST_STALE_DIR}/tmux/${OPENROSDE_TEST_STALE_NAME}.panes" "*  stale  stale.launch"
  openrosde-test-write-file "${OPENROSDE_TEST_STALE_DIR}/docker/docker-compose-${OPENROSDE_TEST_STALE_NAME}.yaml" "services: {}"
  openrosde-test-write-file "${OPENROSDE_TEST_STALE_DIR}/scripts/${OPENROSDE_TEST_STALE_NAME}/bringup-ros-robot.bash" 'ssh stale-robot "killall -9 roscore"'
  openrosde-test-write-file "${OPENROSDE_TEST_STALE_DIR}/scripts/${OPENROSDE_TEST_STALE_NAME}/restart-chrony-service.bash" 'ssh stale-robot "sudo service chrony restart"'
  openrosde-test-write-file "${OPENROSDE_TEST_STALE_DIR}/terminator/${OPENROSDE_TEST_STALE_NAME}.config" "[layouts]"
done

# Print the scripts and layouts that a setup resolves, in the form of 'openrosde-test-print-paths', from the five paths given in its order.
function openrosde-test-print-setup-files () {
  printf 'setup-file scripts/%%s/bringup-ros-robot.bash: %s\n' "$1"
  printf 'setup-file scripts/%%s/restart-chrony-service.bash: %s\n' "$2"
  printf 'setup-file scripts/%%s/initialize-bash-shell.bash: %s\n' "$3"
  printf 'setup-file terminator/%%s.config: %s\n' "$4"
  printf 'setup-file tmux/%%s.panes: %s\n' "$5"
}

# Check the folders, workspaces, layers, overlays, panes, and scripts that the selected setup resolves, from the expected values given in that order.
function openrosde-test-check-setup () {
  local OPENROSDE_TEST_REPORT
  OPENROSDE_TEST_REPORT="$(openrosde-test-print-paths)"
  openrosde-test-check "finds the folders of '$1'" "$2" "$(echo "${OPENROSDE_TEST_REPORT}" | grep -E '^(platform-root|setup|setup-root|active):')"
  openrosde-test-check "lists the workspaces of '$1'" "$3" "$(echo "${OPENROSDE_TEST_REPORT}" | sed -n 's/^workspaces: //p')"
  openrosde-test-check "lists the layers of '$1'" "$4" "$(echo "${OPENROSDE_TEST_REPORT}" | sed -n 's/^layers: //p')"
  openrosde-test-check "lists the overlays of '$1'" "$5" "$(echo "${OPENROSDE_TEST_REPORT}" | sed -n 's/^overlays: //p')"
  openrosde-test-check "lists the pane files of '$1'" "$6" "$(echo "${OPENROSDE_TEST_REPORT}" | sed -n 's/^panes: //p')"
  openrosde-test-check "finds the scripts and layouts of '$1'" "$7" "$(echo "${OPENROSDE_TEST_REPORT}" | grep '^setup-file ')"
  OPENROSDE_TEST_STALE_LINES="${OPENROSDE_TEST_STALE_LINES}$(echo "${OPENROSDE_TEST_REPORT}" | grep 'aaa-stale-clone')"
}
OPENROSDE_TEST_STALE_LINES=""

################################################################################

# Check the listings, which find the platform and the setups of the parts.
openrosde-test-run bash ./scripts/list-robot-platforms.bash
openrosde-test-check "lists the platform of a part" \
  "$(printf '%s\n' cobotta crobot fetch hsr sciurus17 turtlebot3 ur5e) 0" \
  "${OPENROSDE_TEST_OUTPUT} ${OPENROSDE_TEST_EXIT_CODE}"
openrosde-test-run bash ./scripts/list-robot-setups.bash
openrosde-test-check "lists the setups of the parts" \
  "$(printf '%s\n' acme-ur5e-lab client-crobot-sim cobotta crobot fetch hsr sciurus17 turtlebot3 ur5e) 0" \
  "${OPENROSDE_TEST_OUTPUT} ${OPENROSDE_TEST_EXIT_CODE}"

################################################################################

# Check the switch to the setup of the part 'acme-bench', which warns about the device cloned from another URL.
openrosde-test-add-stub vcs
openrosde-test-run bash ./SWITCH-ROBOT-SETUP.bash acme-ur5e-lab
openrosde-test-check "switches to the setup of a part" \
  "0 same vcs import --skip-existing --input ./${OPENROSDE_TEST_BENCH_DIR}/env/acme-ur5e-lab.repos ./extensions" \
  "${OPENROSDE_TEST_EXIT_CODE} $(cmp -s "${OPENROSDE_TEST_ROOT_DIR}/${OPENROSDE_TEST_BENCH_DIR}/env/acme-ur5e-lab.env" "${OPENROSDE_TEST_ROOT_DIR}/.env.custom" && echo same) $(openrosde-test-print-calls | grep '^vcs ')"
openrosde-test-check "warns about a clone whose origin differs from the URL of the '.repos' file" \
  "$(printf '%s\n' \
    "Warning: 'extensions/openrosde-device-gripper/' is cloned from 'https://gitlab.example.com/old-group/openrosde-device-gripper.git' rather than from 'https://gitlab.example.com/acme/openrosde-device-gripper.git', which '${OPENROSDE_TEST_BENCH_DIR}/env/acme-ur5e-lab.repos' lists, so 'vcs import' leaves it as it is." \
    "Point it to the URL of the file with: git -C './${OPENROSDE_TEST_GRIPPER_DIR}' remote set-url origin 'https://gitlab.example.com/acme/openrosde-device-gripper.git'")" \
  "$(echo "${OPENROSDE_TEST_OUTPUT}" | grep -E '^(Warning: .extensions/openrosde-device-gripper|Point it to)' | sed "s#${OPENROSDE_TEST_ROOT_DIR}#.#g")"

################################################################################

# Check the setup 'acme-ur5e-lab', which runs the UR5e of the core with the device and the part 'acme-binding'.
# Their files named after the active platform come after those of the platform, while the panes of the setup replace those of the platform.
openrosde-test-check-setup acme-ur5e-lab \
  "$(printf '%s\n' "platform-root: ." "setup: acme-ur5e-lab" "setup-root: ./${OPENROSDE_TEST_BENCH_DIR}" "active: . ./${OPENROSDE_TEST_GRIPPER_DIR} ./${OPENROSDE_TEST_BINDING_DIR} ./${OPENROSDE_TEST_BENCH_DIR}")" \
  "./ros/openrosde_catkin_ws ./ros/ur5e_catkin_ws ./${OPENROSDE_TEST_GRIPPER_DIR}/ros/gripper_catkin_ws ./${OPENROSDE_TEST_BINDING_DIR}/ros/acme_binding_catkin_ws ./${OPENROSDE_TEST_BENCH_DIR}/ros/acme_bench_catkin_ws ./ros/user_catkin_ws" \
  "./${OPENROSDE_TEST_BINDING_DIR}/docker/acme-binding-devel/Dockerfile ./${OPENROSDE_TEST_BENCH_DIR}/docker/acme-ur5e-lab-devel/Dockerfile" \
  "./docker/docker-compose-ur5e.yaml ./${OPENROSDE_TEST_GRIPPER_DIR}/docker/docker-compose-ur5e.yaml ./${OPENROSDE_TEST_BINDING_DIR}/docker/docker-compose-acme-binding.yaml ./${OPENROSDE_TEST_BENCH_DIR}/docker/docker-compose-acme-ur5e-lab.yaml" \
  "./${OPENROSDE_TEST_BENCH_DIR}/tmux/acme-ur5e-lab.panes ./${OPENROSDE_TEST_BINDING_DIR}/tmux/acme-binding.panes ./${OPENROSDE_TEST_BINDING_DIR}/tmux/ur5e.panes ./tmux/openrosde.panes" \
  "$(openrosde-test-print-setup-files "./${OPENROSDE_TEST_BENCH_DIR}/scripts/acme-ur5e-lab/bringup-ros-robot.bash" "" "" "./${OPENROSDE_TEST_BENCH_DIR}/terminator/acme-ur5e-lab.config" "./${OPENROSDE_TEST_BENCH_DIR}/tmux/acme-ur5e-lab.panes")"
openrosde-test-run bash ./RUN-DOCKER-CONTAINER.bash test --no-exec
openrosde-test-check "runs the container of 'acme-ur5e-lab' with the overlays of its folders" \
  "docker compose -p test -f ./docker/docker-compose.yaml -f ./docker/docker-compose-ur5e.yaml -f ./${OPENROSDE_TEST_GRIPPER_DIR}/docker/docker-compose-ur5e.yaml -f ./${OPENROSDE_TEST_BINDING_DIR}/docker/docker-compose-acme-binding.yaml -f ./${OPENROSDE_TEST_BENCH_DIR}/docker/docker-compose-acme-ur5e-lab.yaml -f ./docker/docker-compose-user.yaml up -d openrosde" \
  "$(openrosde-test-print-calls | grep '^docker compose')"
openrosde-test-run bash ./RESTART-CHRONY-SERVICE.bash test
openrosde-test-check "runs no Chrony script of the inactive clone for 'acme-ur5e-lab'" \
  "No robot Chrony restart is configured for the 'ur5e' platform." \
  "$(echo "${OPENROSDE_TEST_OUTPUT}" | grep '^No robot Chrony'; openrosde-test-print-calls | grep '^ssh ')"

# Check the setup 'client-crobot-sim', whose panes replace those of its platform, and the default setup 'crobot', which skips the overlay and the panes of 'client-crobot-sim'.
openrosde-test-select-template "${OPENROSDE_TEST_ROBOT_DIR}/env/client-crobot-sim.env"
openrosde-test-check-setup client-crobot-sim \
  "$(printf '%s\n' "platform-root: ./${OPENROSDE_TEST_ROBOT_DIR}" "setup: client-crobot-sim" "setup-root: ./${OPENROSDE_TEST_ROBOT_DIR}" "active: . ./${OPENROSDE_TEST_ROBOT_DIR}")" \
  "./ros/openrosde_catkin_ws ./${OPENROSDE_TEST_ROBOT_DIR}/ros/crobot_catkin_ws ./${OPENROSDE_TEST_ROBOT_DIR}/ros/client_sim_catkin_ws ./ros/user_catkin_ws" \
  "./${OPENROSDE_TEST_ROBOT_DIR}/docker/client-sim-devel/Dockerfile" \
  "./${OPENROSDE_TEST_ROBOT_DIR}/docker/docker-compose-crobot.yaml ./${OPENROSDE_TEST_ROBOT_DIR}/docker/docker-compose-client-crobot-sim.yaml" \
  "./${OPENROSDE_TEST_ROBOT_DIR}/tmux/client-crobot-sim.panes ./tmux/openrosde.panes" \
  "$(openrosde-test-print-setup-files "./${OPENROSDE_TEST_ROBOT_DIR}/scripts/crobot/bringup-ros-robot.bash" "" "" "./${OPENROSDE_TEST_ROBOT_DIR}/terminator/crobot.config" "./${OPENROSDE_TEST_ROBOT_DIR}/tmux/client-crobot-sim.panes")"
openrosde-test-select-template "${OPENROSDE_TEST_ROBOT_DIR}/env/crobot.env"
openrosde-test-check-setup crobot \
  "$(printf '%s\n' "platform-root: ./${OPENROSDE_TEST_ROBOT_DIR}" "setup: crobot" "setup-root: ./${OPENROSDE_TEST_ROBOT_DIR}" "active: . ./${OPENROSDE_TEST_ROBOT_DIR}")" \
  "./ros/openrosde_catkin_ws ./${OPENROSDE_TEST_ROBOT_DIR}/ros/crobot_catkin_ws ./${OPENROSDE_TEST_ROBOT_DIR}/ros/client_sim_catkin_ws ./ros/user_catkin_ws" \
  "./${OPENROSDE_TEST_ROBOT_DIR}/docker/client-sim-devel/Dockerfile" \
  "./${OPENROSDE_TEST_ROBOT_DIR}/docker/docker-compose-crobot.yaml" \
  "./${OPENROSDE_TEST_ROBOT_DIR}/tmux/crobot.panes ./tmux/openrosde.panes" \
  "$(openrosde-test-print-setup-files "./${OPENROSDE_TEST_ROBOT_DIR}/scripts/crobot/bringup-ros-robot.bash" "" "" "./${OPENROSDE_TEST_ROBOT_DIR}/terminator/crobot.config" "./${OPENROSDE_TEST_ROBOT_DIR}/tmux/crobot.panes")"

# Check the default setups 'turtlebot3' and 'ur5e' of the core, which no part changes.
openrosde-test-select-template env/turtlebot3.env
openrosde-test-check-setup turtlebot3 \
  "$(printf '%s\n' "platform-root: ." "setup: turtlebot3" "setup-root: ." "active: .")" \
  "./ros/openrosde_catkin_ws ./ros/turtlebot3_catkin_ws ./ros/user_catkin_ws" \
  "" \
  "./docker/docker-compose-turtlebot3.yaml" \
  "./tmux/turtlebot3.panes ./tmux/openrosde.panes" \
  "$(openrosde-test-print-setup-files ./scripts/turtlebot3/bringup-ros-robot.bash "" ./scripts/turtlebot3/initialize-bash-shell.bash ./terminator/turtlebot3.config ./tmux/turtlebot3.panes)"
openrosde-test-select-template env/ur5e.env
openrosde-test-check-setup ur5e \
  "$(printf '%s\n' "platform-root: ." "setup: ur5e" "setup-root: ." "active: .")" \
  "./ros/openrosde_catkin_ws ./ros/ur5e_catkin_ws ./ros/user_catkin_ws" \
  "" \
  "./docker/docker-compose-ur5e.yaml" \
  "./tmux/ur5e.panes ./tmux/openrosde.panes" \
  "$(openrosde-test-print-setup-files "" "" "" ./terminator/ur5e.config ./tmux/ur5e.panes)"

# Check that the device, once listed in the '.env.custom' of the platform 'turtlebot3', leaves out its overlay for the UR5e, which is not active.
openrosde-test-select-template env/turtlebot3.env
echo 'OPENROSDE_ROBOT_EXTENSIONS="openrosde-device-gripper"' >> "${OPENROSDE_TEST_ROOT_DIR}/.env.custom"
openrosde-test-check "leaves out the overlay of an active device named after a platform that is not active" \
  "$(printf '%s\n' "./docker/docker-compose-turtlebot3.yaml" "./tmux/turtlebot3.panes ./tmux/openrosde.panes")" \
  "$(openrosde-test-print-path overlays; openrosde-test-print-path panes)"

# Check that the inactive clone supplied nothing to any of the five setups.
openrosde-test-check "takes nothing from the inactive clone" "" "${OPENROSDE_TEST_STALE_LINES}"

################################################################################

# Check how a name of 'OPENROSDE_ROBOT_EXTENSIONS' resolves to a folder.
function openrosde-test-find-extension-root () {
  openrosde-test-run bash -c "source ./scripts/load-extension-paths.bash \"\${PWD}\"; openrosde-find-extension-root $1"
  echo "${OPENROSDE_TEST_EXIT_CODE} ${OPENROSDE_TEST_OUTPUT}" | sed "s#${OPENROSDE_TEST_ROOT_DIR}#.#g"
}
openrosde-test-check "resolves a part and an extension by name" \
  "$(printf '%s\n' "0 ./${OPENROSDE_TEST_BINDING_DIR}" "0 ./${OPENROSDE_TEST_GRIPPER_DIR}")" \
  "$(openrosde-test-find-extension-root acme-binding; openrosde-test-find-extension-root openrosde-device-gripper)"
openrosde-test-check "fails on a name that no folder holds" \
  "1 Error: Extension 'acme-nowhere' of 'OPENROSDE_ROBOT_EXTENSIONS' is cloned neither in 'extensions/acme-nowhere/' nor as a part in 'extensions/<extension>/parts/acme-nowhere/'." \
  "$(openrosde-test-find-extension-root acme-nowhere)"
openrosde-test-create-extension other-company
mkdir -p "${OPENROSDE_TEST_ROOT_DIR}/extensions/other-company/parts/acme-binding"
openrosde-test-check "fails on a name that several parts hold" \
  "1 Error: Extension 'acme-binding' of 'OPENROSDE_ROBOT_EXTENSIONS' is ambiguous, since several folders hold it: 'extensions/acme/parts/acme-binding/' 'extensions/other-company/parts/acme-binding/'." \
  "$(openrosde-test-find-extension-root acme-binding)"
rm -rf "${OPENROSDE_TEST_ROOT_DIR}/extensions/other-company"

################################################################################

# Check that the switch fails, and leaves the setup unchanged, when a part or the platform of the setup is missing once the repositories are cloned.
openrosde-test-write-setup-template "${OPENROSDE_TEST_BENCH_DIR}" acme-ur5e-broken ur5e "acme-binding acme-missing"
openrosde-test-write-setup-template "${OPENROSDE_TEST_BENCH_DIR}" acme-nobot-lab nobot ""
openrosde-test-select-template env/ur5e.env
openrosde-test-run bash ./SWITCH-ROBOT-SETUP.bash acme-ur5e-broken
openrosde-test-check "refuses a setup whose part is missing" \
  "1 Error: Extensions 'acme-missing' of setup 'acme-ur5e-broken' do not resolve, so the setup stays unchanged. same" \
  "${OPENROSDE_TEST_EXIT_CODE} $(echo "${OPENROSDE_TEST_OUTPUT}" | grep '^Error: Extensions') $(cmp -s "${OPENROSDE_TEST_ROOT_DIR}/env/ur5e.env" "${OPENROSDE_TEST_ROOT_DIR}/.env.custom" && echo same)"
openrosde-test-run bash ./SWITCH-ROBOT-SETUP.bash acme-nobot-lab
openrosde-test-check "refuses a setup whose platform is missing" \
  "1 Error: Platform 'nobot' of setup 'acme-nobot-lab' is not found, so the setup stays unchanged. same" \
  "${OPENROSDE_TEST_EXIT_CODE} $(echo "${OPENROSDE_TEST_OUTPUT}" | grep '^Error: Platform') $(cmp -s "${OPENROSDE_TEST_ROOT_DIR}/env/ur5e.env" "${OPENROSDE_TEST_ROOT_DIR}/.env.custom" && echo same)"
rm -f "${OPENROSDE_TEST_ROOT_DIR}/${OPENROSDE_TEST_BENCH_DIR}/env/acme-ur5e-broken.env" "${OPENROSDE_TEST_ROOT_DIR}/${OPENROSDE_TEST_BENCH_DIR}/env/acme-nobot-lab.env"

################################################################################

# Check the warning on a platform that two templates declare, and the errors on lines that OpenRoSDE does not read.
openrosde-test-create-extension openrosde-platform-ur5e
openrosde-test-write-platform-template extensions/openrosde-platform-ur5e ur5e
openrosde-test-run bash ./scripts/list-robot-platforms.bash
openrosde-test-check "lists a platform declared twice once, with a warning" \
  "Warning: Platform 'ur5e' is declared by 'env/ur5e.env' and by 'extensions/openrosde-platform-ur5e/env/ur5e.env', and OpenRoSDE uses the first. 1" \
  "$(echo "${OPENROSDE_TEST_OUTPUT}" | grep '^Warning:') $(echo "${OPENROSDE_TEST_OUTPUT}" | grep -cx ur5e)"
rm -rf "${OPENROSDE_TEST_ROOT_DIR}/extensions/openrosde-platform-ur5e"
openrosde-test-write-file "${OPENROSDE_TEST_ROBOT_DIR}/env/qbot.env" 'OPENROSDE_ROBOT_PLATFORM="qbot"' "OPENROSDE_ROBOT_SETUP=qbot"
openrosde-test-run bash ./scripts/list-robot-platforms.bash
openrosde-test-check "names a template whose platform line is quoted, and fails" \
  "Error: '${OPENROSDE_TEST_ROBOT_DIR}/env/qbot.env' declares 'OPENROSDE_ROBOT_PLATFORM' on line 1 with quotes, spaces, or a trailing comment, which OpenRoSDE does not read: write it as 'OPENROSDE_ROBOT_PLATFORM=<platform>' alone on its line. 1 0" \
  "$(echo "${OPENROSDE_TEST_OUTPUT}" | grep '^Error:') ${OPENROSDE_TEST_EXIT_CODE} $(echo "${OPENROSDE_TEST_OUTPUT}" | grep -cx qbot)"
openrosde-test-write-file "${OPENROSDE_TEST_ROBOT_DIR}/env/qbot.env" "OPENROSDE_ROBOT_PLATFORM=crobot" "OPENROSDE_ROBOT_SETUP=qbot  # Simulation of the lab."
openrosde-test-run bash ./scripts/list-robot-setups.bash
openrosde-test-check "names a template whose setup line carries a comment, and fails" \
  "Error: '${OPENROSDE_TEST_ROBOT_DIR}/env/qbot.env' declares 'OPENROSDE_ROBOT_SETUP' or 'OPENROSDE_ROBOT_PLATFORM' on line 2 with quotes, spaces, or a trailing comment, which OpenRoSDE does not read: write it as 'OPENROSDE_ROBOT_SETUP=<setup>' or 'OPENROSDE_ROBOT_PLATFORM=<platform>' alone on its line. 1 0" \
  "$(echo "${OPENROSDE_TEST_OUTPUT}" | grep '^Error:') ${OPENROSDE_TEST_EXIT_CODE} $(echo "${OPENROSDE_TEST_OUTPUT}" | grep -cx qbot)"
rm -f "${OPENROSDE_TEST_ROOT_DIR}/${OPENROSDE_TEST_ROBOT_DIR}/env/qbot.env"

################################################################################

# Check that the patches of a part apply to the submodules of that part.
openrosde-test-run bash ./scripts/update-git-submodules.bash
openrosde-test-check "updates the submodules of every clone and applies the patches of each part" \
  "$(printf '%s\n' \
    "git -C ./${OPENROSDE_TEST_STALE_DIR} submodule update --init --recursive" \
    "git -C ./${OPENROSDE_TEST_ACME_DIR} submodule update --init --recursive" \
    "git -C ./${OPENROSDE_TEST_BENCH_DIR}/ros/acme_bench_catkin_ws/src/acme_driver apply --check ./${OPENROSDE_TEST_BENCH_DIR}/patches/ros/acme_bench_catkin_ws/src/acme_driver/0001-fix-acme-driver.patch" \
    "git -C ./${OPENROSDE_TEST_GRIPPER_DIR} submodule update --init --recursive")" \
  "$(openrosde-test-print-calls | grep -E '^git -C [^ ]+ (submodule|apply --check)')"

################################################################################

# Remove the scratch copy and report the result.
openrosde-test-remove-copy
openrosde-test-finish-suite
