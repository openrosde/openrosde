#!/bin/bash

# This suite checks the scripts of the CI in 'gitlab-ci/', with every call to Docker and to ROS stubbed, so that no check builds an image, starts a container, or starts a node.
# It covers the variables that the parent pipeline passes to the child pipeline, the child pipeline that the generator prints for platforms and setups of the core and of extensions, with the variables it writes into it, the launch check of a setup, the check that no script moves a robot, the refusals of the clone of the extensions, the source hash of an image, the tags that may be published, and the test of a setup, with its guard of '.env.custom' and the images it reads.
# It uses the extension 'acme-robots', whose part 'acme-rover' holds the platform 'rover' and whose part 'acme-lab' holds the setup 'acme-rover-lab', and the device 'openrosde-device-bar' with a Docker layer.
#
# Usage: bash ./tests/run.bash test-ci-scripts

################################################################################

# Load the helpers and create the scratch copy.
source "${OPENROSDE_TEST_SOURCE_DIR}/tests/load-test-helpers.bash"
openrosde-test-create-copy
# Write the UR5e as a platform of the core of the scratch copy, which the checks below select, since the UR5e lives in a repository of its own.
openrosde-test-write-core-platform ur5e
OPENROSDE_TEST_ACME_DIR="extensions/acme-robots"
OPENROSDE_TEST_ROVER_DIR="${OPENROSDE_TEST_ACME_DIR}/parts/acme-rover"
OPENROSDE_TEST_LAB_DIR="${OPENROSDE_TEST_ACME_DIR}/parts/acme-lab"
OPENROSDE_TEST_BAR_DIR="extensions/openrosde-device-bar"
OPENROSDE_TEST_REGISTRY="registry.example.com/acme/openrosde"
OPENROSDE_TEST_COMMIT="0123456789abcdef0123456789abcdef01234567"

# Create the platform 'rover' with no pane file, the setup 'acme-rover-lab' on it with the device, the device with a Docker layer, and the device 'openrosde-device-qux' that no setup uses.
openrosde-test-create-extension acme-robots
openrosde-test-write-platform-template "${OPENROSDE_TEST_ROVER_DIR}" rover
openrosde-test-write-file "${OPENROSDE_TEST_ROVER_DIR}/docker/rover-devel/Dockerfile" "FROM scratch"
openrosde-test-write-setup-template "${OPENROSDE_TEST_LAB_DIR}" acme-rover-lab rover "openrosde-device-bar"
openrosde-test-create-extension openrosde-device-bar
openrosde-test-write-file "${OPENROSDE_TEST_BAR_DIR}/docker/bar-devel/Dockerfile" "ARG OPENROSDE_PARENT_IMAGE" 'FROM ${OPENROSDE_PARENT_IMAGE}'
openrosde-test-create-extension openrosde-device-qux

# Replace the stub of 'roslaunch': '--nodes' prints the nodes written for the launch file in 'nodes/<launch-file>', and fails when 'nodes/<launch-file>.fail' exists, as for two nodes of one name in one launch file.
OPENROSDE_TEST_NODES_DIR="${OPENROSDE_TEST_WORK_DIR}/nodes"
mkdir -p "${OPENROSDE_TEST_NODES_DIR}"
export OPENROSDE_TEST_NODES_DIR
cat > "${OPENROSDE_TEST_STUB_DIR}/roslaunch" <<'EOF'
#!/bin/bash
echo "roslaunch $*" >> "${OPENROSDE_TEST_COMMAND_LOG}"
if [ "$1" = "--nodes" ]; then
  if [ -f "${OPENROSDE_TEST_NODES_DIR}/$3.fail" ]; then
    echo "roslaunch file contains multiple nodes named [/twice]." >&2
    exit 1
  fi
  cat "${OPENROSDE_TEST_NODES_DIR}/$3" 2>/dev/null
fi
exit 0
EOF

# Replace the stub of 'docker': 'inspect' lists the network 'bridge' of a container, then counts no network once it is disconnected, and any call that contains 'OPENROSDE_TEST_FAILING_CALL' fails.
cat > "${OPENROSDE_TEST_STUB_DIR}/docker" <<'EOF'
#!/bin/bash
echo "docker $*" >> "${OPENROSDE_TEST_COMMAND_LOG}"
case "$*" in
  "inspect --format {{ range "*)
    echo "bridge "
    ;;
  "inspect --format {{ len "*)
    grep -q '^docker network disconnect ' "${OPENROSDE_TEST_COMMAND_LOG}" && echo 0 || echo 1
    ;;
esac
if [ -n "${OPENROSDE_TEST_FAILING_CALL}" ] && [[ "$*" == *"${OPENROSDE_TEST_FAILING_CALL}"* ]]; then
  exit 1
fi
exit 0
EOF

# Print the names of the jobs that the generator printed in the last run, the folders of its platforms that are not the core, and its status.
function openrosde-test-print-generated-jobs () {
  echo "${OPENROSDE_TEST_OUTPUT}" | grep -E '^[a-z0-9-]+-job:$|OPENROSDE_CI_PLATFORM_ROOT_DIR: [^.]|^Error:'
  echo "status ${OPENROSDE_TEST_EXIT_CODE}"
}

# Print the global variables that the generator wrote into the child pipeline in the last run.
function openrosde-test-print-generated-variables () {
  echo "${OPENROSDE_TEST_OUTPUT}" | awk '/^variables:$/ { printing = 1; next } printing && !/^  / { exit } printing'
}

################################################################################

# Check that the parent pipeline passes the child pipeline only the variables that GitLab sets, so that no variable that started it, such as one of a schedule, can make the child pipeline publish.
OPENROSDE_TEST_TRIGGER_JOB="$(awk '/^run-pipeline-job:$/ { printing = 1; next } printing && /^[^[:space:]#]/ { exit } printing' "${OPENROSDE_TEST_ROOT_DIR}/gitlab-ci/gitlab-ci.yml")"
openrosde-test-check "passes the child pipeline no variable of the parent pipeline, apart from those that GitLab sets" \
  "$(printf '%s\n' "0 forwarded kinds" "inherits no global variable" "3 variables, 0 not set by GitLab")" \
  "$(echo "$(echo "${OPENROSDE_TEST_TRIGGER_JOB}" | grep -c 'forward:') forwarded kinds"
    echo "${OPENROSDE_TEST_TRIGGER_JOB}" | grep -A 1 -x '  inherit:' | grep -q -x '    variables: false' && echo "inherits no global variable"
    OPENROSDE_TEST_TRIGGER_VARIABLES="$(echo "${OPENROSDE_TEST_TRIGGER_JOB}" | sed -n '/^  variables:$/,$p' | grep -E '^    [A-Z0-9_]+:')"
    echo "$(echo "${OPENROSDE_TEST_TRIGGER_VARIABLES}" | grep -c .) variables, $(echo "${OPENROSDE_TEST_TRIGGER_VARIABLES}" | grep -c -v -E ': (\$CI_[A-Z_]+)+$') not set by GitLab")"

################################################################################

# Check the jobs that the generator prints for every platform and setup, and for an override of one extension.
# The platforms of the core of the scratch copy, whichever it still holds, come in alphabetical order with 'rover', and their default setups with 'acme-rover-lab'.
# The tag of the runner is the one that 'gitlab-ci/gitlab-ci.yml' sets, which the generator writes into the child pipeline.
export OPENROSDE_CI_RUNNER_TAG="privileged-docker"
OPENROSDE_TEST_CORE_PLATFORM_NAMES="$(openrosde-test-print-core-platforms)"
openrosde-test-run bash ./gitlab-ci/generate-ci-pipeline.bash
openrosde-test-check "prints one image job per platform, from its folder, one test job per setup, and the test job of the core alone" \
  "$( (printf '%s\n' ${OPENROSDE_TEST_CORE_PLATFORM_NAMES} rover | sort | sed 's/.*/build-&-image-job:/' | sed "s#^build-rover-image-job:\$#&\n    OPENROSDE_CI_PLATFORM_ROOT_DIR: ${OPENROSDE_TEST_ROVER_DIR}#"
    printf '%s\n' ${OPENROSDE_TEST_CORE_PLATFORM_NAMES} rover acme-rover-lab | sort | sed 's/.*/test-&-workspaces-job:/'
    printf '%s\n' test-core-workspaces-job: publish-images-job: "status 0"))" \
  "$(openrosde-test-print-generated-jobs)"
openrosde-test-check "makes the test job of a setup need the image job of its platform, and the core alone the base image, and both the converter of robot meshes and the check of the scripts" \
  "$(printf '%s\n' "test-acme-rover-lab-workspaces-job: build-rover-image-job" "test-acme-rover-lab-workspaces-job: build-mesh2glb-image-job" "test-acme-rover-lab-workspaces-job: check-scripts-job" "test-core-workspaces-job: build-base-image-job" "test-core-workspaces-job: build-mesh2glb-image-job" "test-core-workspaces-job: check-scripts-job")" \
  "$(echo "${OPENROSDE_TEST_OUTPUT}" | awk '/^test-(acme-rover-lab|core)-workspaces-job:$/ { name = $1; next } name != "" && /^    - / { print name, $2; next } /^  variables:$/ { name = "" }')"
openrosde-test-check "writes the tag of the runner into the child pipeline, with no override and no extra extension" \
  "$(printf '%s\n' '  OPENROSDE_CI_RUNNER_TAG: "privileged-docker"' '  OPENROSDE_CI_EXTENSION_OVERRIDE: ""' '  OPENROSDE_CI_EXTRA_EXTENSIONS: ""')" \
  "$(openrosde-test-print-generated-variables)"
export OPENROSDE_CI_EXTENSION_OVERRIDE="acme-robots=feat/foo@${OPENROSDE_TEST_COMMIT}"
openrosde-test-run bash ./gitlab-ci/generate-ci-pipeline.bash
openrosde-test-check "keeps only the setups that activate the extension of the override, and their platforms, with no job of the core alone" \
  "$(printf '%s\n' build-rover-image-job: "    OPENROSDE_CI_PLATFORM_ROOT_DIR: ${OPENROSDE_TEST_ROVER_DIR}" test-acme-rover-lab-workspaces-job: test-rover-workspaces-job: publish-images-job: "status 0")" \
  "$(openrosde-test-print-generated-jobs)"
export OPENROSDE_CI_EXTENSION_OVERRIDE="openrosde-device-bar=feat/foo@${OPENROSDE_TEST_COMMIT}"
openrosde-test-run bash ./gitlab-ci/generate-ci-pipeline.bash
openrosde-test-check "keeps only the setup that lists the device of the override, and its platform" \
  "$(printf '%s\n' build-rover-image-job: "    OPENROSDE_CI_PLATFORM_ROOT_DIR: ${OPENROSDE_TEST_ROVER_DIR}" test-acme-rover-lab-workspaces-job: publish-images-job: "status 0")" \
  "$(openrosde-test-print-generated-jobs)"
export OPENROSDE_CI_EXTENSION_OVERRIDE="openrosde-device-qux=feat/foo@${OPENROSDE_TEST_COMMIT}"
openrosde-test-run bash ./gitlab-ci/generate-ci-pipeline.bash
openrosde-test-check "fails when no setup activates the extension of the override" \
  "$(printf '%s\n' "Error: No setup activates the extension 'openrosde-device-qux' of 'OPENROSDE_CI_EXTENSION_OVERRIDE', so nothing would test it: name it in 'OPENROSDE_CI_EXTRA_EXTENSIONS' to add it to every setup." "status 1")" \
  "$(openrosde-test-print-generated-jobs)"
export OPENROSDE_CI_EXTRA_EXTENSIONS="openrosde-device-qux"
openrosde-test-run bash ./gitlab-ci/generate-ci-pipeline.bash
openrosde-test-check "tests every setup with the extension of the override when 'OPENROSDE_CI_EXTRA_EXTENSIONS' adds it to every setup" \
  "$(( $(echo "${OPENROSDE_TEST_CORE_PLATFORM_NAMES}" | grep -c .) + 2 )) setups, $(( $(echo "${OPENROSDE_TEST_CORE_PLATFORM_NAMES}" | grep -c .) + 1 )) platforms, status 0" \
  "$(echo "$(echo "${OPENROSDE_TEST_OUTPUT}" | grep -c '^test-.*-workspaces-job:$') setups, $(echo "${OPENROSDE_TEST_OUTPUT}" | grep -c '^build-.*-image-job:$') platforms, status ${OPENROSDE_TEST_EXIT_CODE}")"
openrosde-test-check "writes the override and the extra extensions into the child pipeline, which receives no variable of the parent pipeline" \
  "$(printf '%s\n' '  OPENROSDE_CI_RUNNER_TAG: "privileged-docker"' "  OPENROSDE_CI_EXTENSION_OVERRIDE: \"openrosde-device-qux=feat/foo@${OPENROSDE_TEST_COMMIT}\"" '  OPENROSDE_CI_EXTRA_EXTENSIONS: "openrosde-device-qux"')" \
  "$(openrosde-test-print-generated-variables)"
unset OPENROSDE_CI_EXTENSION_OVERRIDE OPENROSDE_CI_EXTRA_EXTENSIONS

# Check that the generator refuses a variable of the pipeline that it would write into the child pipeline, or that the scripts would source, in any other format than its own.
OPENROSDE_TEST_FORMAT_REPORT=""
for OPENROSDE_TEST_VARIABLE in \
  'OPENROSDE_CI_EXTRA_EXTENSIONS=openrosde-device-bar" $(touch pwned) "' \
  "OPENROSDE_CI_EXTENSION_OVERRIDE=openrosde-device-bar=feat/foo@0123abc" \
  "OPENROSDE_CI_EXTENSION_OVERRIDE=openrosde-device-bar=feat/foo\"@${OPENROSDE_TEST_COMMIT}" \
  "OPENROSDE_CI_RUNNER_TAG=" \
  "OPENROSDE_CI_RUNNER_TAG=privileged-docker\""; do
  openrosde-test-run env "${OPENROSDE_TEST_VARIABLE}" bash ./gitlab-ci/generate-ci-pipeline.bash
  OPENROSDE_TEST_FORMAT_REPORT="${OPENROSDE_TEST_FORMAT_REPORT}${OPENROSDE_TEST_EXIT_CODE} $(echo "${OPENROSDE_TEST_OUTPUT}" | grep -c -e '-job:$') $(echo "${OPENROSDE_TEST_OUTPUT}" | grep '^Error:')"$'\n'
done
openrosde-test-check "refuses extra extensions, an override, or a tag of the runner in another format, before printing any job" \
  "$(printf '%s\n' \
    "1 0 Error: 'OPENROSDE_CI_EXTRA_EXTENSIONS' may hold only folder names separated by spaces, but it is 'openrosde-device-bar\" \$(touch pwned) \"'." \
    "1 0 Error: 'OPENROSDE_CI_EXTENSION_OVERRIDE' must read '<name>=<branch>@<commit>', with the full hash of the commit, but it is 'openrosde-device-bar=feat/foo@0123abc'." \
    "1 0 Error: 'OPENROSDE_CI_EXTENSION_OVERRIDE' must read '<name>=<branch>@<commit>', with the full hash of the commit, but it is 'openrosde-device-bar=feat/foo\"@${OPENROSDE_TEST_COMMIT}'." \
    "1 0 Error: 'OPENROSDE_CI_RUNNER_TAG' must name the tag of a runner, with letters, digits, and '_.:/-' alone, but it is ''." \
    "1 0 Error: 'OPENROSDE_CI_RUNNER_TAG' must name the tag of a runner, with letters, digits, and '_.:/-' alone, but it is 'privileged-docker\"'.")" \
  "${OPENROSDE_TEST_FORMAT_REPORT%$'\n'}"
openrosde-test-check "creates no file from a value that it refuses" \
  "no file" \
  "$([ -e "${OPENROSDE_TEST_ROOT_DIR}/pwned" ] && echo "a file" || echo "no file")"

# Check that the generator fails when the listing of the platforms or of the setups fails, such as for a template that declares its name with quotes, rather than leaving it out of the pipeline.
openrosde-test-write-file "${OPENROSDE_TEST_ROVER_DIR}/env/rover-quoted.env" 'OPENROSDE_ROBOT_PLATFORM="rover-quoted"'
openrosde-test-run bash ./gitlab-ci/generate-ci-pipeline.bash
openrosde-test-check "fails, with no job, when a template declares its platform with quotes" \
  "$(printf '%s\n' "status 1" "0 jobs" "Error: 'scripts/list-robot-platforms.bash' failed, so the pipeline would leave out a platform.")" \
  "$(echo "status ${OPENROSDE_TEST_EXIT_CODE}"; echo "$(echo "${OPENROSDE_TEST_OUTPUT}" | grep -c -e '-job:$') jobs"; echo "${OPENROSDE_TEST_OUTPUT}" | grep "^Error: 'scripts/")"
rm "${OPENROSDE_TEST_ROOT_DIR}/${OPENROSDE_TEST_ROVER_DIR}/env/rover-quoted.env"
openrosde-test-write-file "${OPENROSDE_TEST_LAB_DIR}/env/acme-qux-lab.env" "OPENROSDE_ROBOT_PLATFORM=rover" 'OPENROSDE_ROBOT_SETUP="acme-qux-lab"'
openrosde-test-run bash ./gitlab-ci/generate-ci-pipeline.bash
openrosde-test-check "fails, with no job, when a template declares its setup with quotes" \
  "$(printf '%s\n' "status 1" "0 jobs" "Error: 'scripts/list-robot-setups.bash' failed, so the pipeline would leave out a setup.")" \
  "$(echo "status ${OPENROSDE_TEST_EXIT_CODE}"; echo "$(echo "${OPENROSDE_TEST_OUTPUT}" | grep -c -e '-job:$') jobs"; echo "${OPENROSDE_TEST_OUTPUT}" | grep "^Error: 'scripts/")"
rm "${OPENROSDE_TEST_ROOT_DIR}/${OPENROSDE_TEST_LAB_DIR}/env/acme-qux-lab.env"

################################################################################

# Check the launch entry points of the platform 'rover', first with no pane file, which the earlier check passed after checking the panes of the core alone.
OPENROSDE_TEST_CHECK_LAUNCH="env OPENROSDE_CONTAINER_ROOT_DIR=${OPENROSDE_TEST_ROOT_DIR} bash ./gitlab-ci/check-launch-files.bash"
openrosde-test-select-template "${OPENROSDE_TEST_ROVER_DIR}/env/rover.env"
openrosde-test-run ${OPENROSDE_TEST_CHECK_LAUNCH} rover
openrosde-test-check "fails for a platform of an extension with no pane file, rather than checking the panes of the core alone" \
  "$(printf '%s\n' "status 1" "Error: Neither the setup 'rover' nor its platform 'rover' has a pane file 'tmux/<name>.panes', so its sessions would open the panes of the core alone.")" \
  "$(echo "status ${OPENROSDE_TEST_EXIT_CODE}"; echo "${OPENROSDE_TEST_OUTPUT}" | grep -E '^(Error|Checked)')"

# Give the platform panes in two layouts, and nodes to its launch files and to one launch file of the core.
openrosde-test-write-file "${OPENROSDE_TEST_ROVER_DIR}/tmux/rover.panes" \
  "# Panes of the platform 'rover' for the tests." \
  "default-gazebo     robot  rover_bringup_default_gazebo.launch" \
  "default-gazebo     robot  rover_rviz_default.launch" \
  "default-realworld  robot  rover_bringup_default_realworld.launch" \
  "default-realworld  robot  rover_rviz_default.launch" \
  "*                  extra  rover_tools:rover_monitor_default.launch rate:=5" \
  "*                  extra  shell"
printf '%s\n' "/gazebo" "/robot_state_publisher" '$(anon spawner)' > "${OPENROSDE_TEST_NODES_DIR}/rover_bringup_default_gazebo.launch"
printf '%s\n' "/rover_driver" "/robot_state_publisher" > "${OPENROSDE_TEST_NODES_DIR}/rover_bringup_default_realworld.launch"
printf '%s\n' "/rviz" "/maximize_rviz" '$(anon spawner)' > "${OPENROSDE_TEST_NODES_DIR}/rover_rviz_default.launch"
printf '%s\n' "/rover_monitor" > "${OPENROSDE_TEST_NODES_DIR}/rover_monitor_default.launch"
printf '%s\n' "/flexbe_app" "/maximize_flexbe" > "${OPENROSDE_TEST_NODES_DIR}/flexbe_app_default.launch"
openrosde-test-run ${OPENROSDE_TEST_CHECK_LAUNCH} rover
openrosde-test-check "checks every entry point of the platform and of the core once, in the launch package of the platform, and the nodes of both layouts" \
  "$(printf '%s\n' "status 0" "Checked 8 launch entry points of 'rover'." "Checked the node names of 2 layouts of 'rover'." \
    "roslaunch --files openrosde_rover_launch rover_bringup_default_gazebo.launch" "roslaunch --files rover_tools rover_monitor_default.launch rate:=5")" \
  "$(echo "status ${OPENROSDE_TEST_EXIT_CODE}"; echo "${OPENROSDE_TEST_OUTPUT}" | grep -E '^(Error|Checked)'; openrosde-test-print-calls | grep -E '^roslaunch --files (openrosde_rover_launch rover_bringup_default_gazebo|rover_tools)')"

# Check that the shell configuration of the platform can name another launch package, as the shell of the container lets it.
openrosde-test-write-file "${OPENROSDE_TEST_ROVER_DIR}/scripts/rover/initialize-bash-shell.bash" "OPENROSDE_LAUNCH_PACKAGE=acme_rover_launch"
openrosde-test-run ${OPENROSDE_TEST_CHECK_LAUNCH} rover
openrosde-test-check "takes the launch package that the shell configuration of the platform names" \
  "$(printf '%s\n' "roslaunch --files acme_rover_launch rover_bringup_default_gazebo.launch" "roslaunch --nodes acme_rover_launch rover_bringup_default_gazebo.launch")" \
  "$(openrosde-test-print-calls | grep -E '^roslaunch --(files|nodes) [a-z_]+ rover_bringup_default_gazebo' | sort -u)"
rm -rf "${OPENROSDE_TEST_ROOT_DIR}/${OPENROSDE_TEST_ROVER_DIR}/scripts"

# Check two panes of one layout that start a node of the same name, then the allowlist of the extension.
printf '%s\n' "/rviz" "/maximize_rviz" "/robot_state_publisher" > "${OPENROSDE_TEST_NODES_DIR}/rover_rviz_default.launch"
openrosde-test-run ${OPENROSDE_TEST_CHECK_LAUNCH} rover
openrosde-test-check "fails when two panes of one layout start a node of the same name, and names the panes" \
  "$(printf '%s\n' "status 1" \
    "  - '/robot_state_publisher' in the layout 'default-gazebo', by:" "      - rover_bringup_default_gazebo.launch" "      - rover_rviz_default.launch" \
    "  - '/robot_state_publisher' in the layout 'default-realworld', by:" "      - rover_bringup_default_realworld.launch" "      - rover_rviz_default.launch")" \
  "$(echo "status ${OPENROSDE_TEST_EXIT_CODE}"; echo "${OPENROSDE_TEST_OUTPUT}" | sed -n '/^These nodes are started/,$p' | tail -n +2)"
openrosde-test-write-file "${OPENROSDE_TEST_ROVER_DIR}/ci/allowed-duplicate-nodes.txt" "# Allowed duplicates of the tests." "default-gazebo /robot_state_publisher"
openrosde-test-run ${OPENROSDE_TEST_CHECK_LAUNCH} rover
openrosde-test-check "allows a node in the layout that the allowlist of the active extension names, and only there" \
  "$(printf '%s\n' "status 1" "Allowed the node '/robot_state_publisher' in several panes of the layout 'default-gazebo'." "  - '/robot_state_publisher' in the layout 'default-realworld', by:")" \
  "$(echo "status ${OPENROSDE_TEST_EXIT_CODE}"; echo "${OPENROSDE_TEST_OUTPUT}" | grep -E "^Allowed|^  - ")"
openrosde-test-write-file "${OPENROSDE_TEST_ROVER_DIR}/ci/allowed-duplicate-nodes.txt" "*  /robot_state_publisher"
openrosde-test-run ${OPENROSDE_TEST_CHECK_LAUNCH} rover
openrosde-test-check "allows a node in every layout with '*'" \
  "status 0" \
  "status ${OPENROSDE_TEST_EXIT_CODE}"
openrosde-test-write-file "${OPENROSDE_TEST_ROVER_DIR}/ci/allowed-duplicate-nodes.txt" \
  "default-gazebo /robot_state_publisher rover_bringup_default_gazebo.launch" \
  "default-realworld /robot_state_publisher rover_bringup_default_realworld.launch rover_rviz_default.launch"
openrosde-test-run ${OPENROSDE_TEST_CHECK_LAUNCH} rover
openrosde-test-check "allows a node only when every pane that starts it runs a launch file that the allowlist names" \
  "$(printf '%s\n' "status 1" "Allowed the node '/robot_state_publisher' in several panes of the layout 'default-realworld'." "  - '/robot_state_publisher' in the layout 'default-gazebo', by:")" \
  "$(echo "status ${OPENROSDE_TEST_EXIT_CODE}"; echo "${OPENROSDE_TEST_OUTPUT}" | grep -E "^Allowed|^  - ")"
rm -rf "${OPENROSDE_TEST_ROOT_DIR}/${OPENROSDE_TEST_ROVER_DIR}/ci"
printf '%s\n' "/rviz" "/maximize_rviz" > "${OPENROSDE_TEST_NODES_DIR}/rover_rviz_default.launch"

# Check a launch file whose nodes cannot be listed, such as one that starts two nodes of one name itself.
touch "${OPENROSDE_TEST_NODES_DIR}/rover_monitor_default.launch.fail"
openrosde-test-run ${OPENROSDE_TEST_CHECK_LAUNCH} rover
openrosde-test-check "fails when 'roslaunch --nodes' fails on an entry point" \
  "$(printf '%s\n' "status 1" "Failed to list the nodes of 'rover_tools rover_monitor_default.launch rate:=5', such as two nodes of one name.")" \
  "$(echo "status ${OPENROSDE_TEST_EXIT_CODE}"; echo "${OPENROSDE_TEST_OUTPUT}" | grep '^Failed')"
rm "${OPENROSDE_TEST_NODES_DIR}/rover_monitor_default.launch.fail"

# Check the core alone, whose panes all run in every layout, and a setup that the settings do not select.
openrosde-test-write-file .env.custom "OPENROSDE_ROBOT_PLATFORM=" "OPENROSDE_ROBOT_SETUP=" "OPENROSDE_ROBOT_EXTENSIONS="
openrosde-test-run ${OPENROSDE_TEST_CHECK_LAUNCH} openrosde
openrosde-test-check "checks the panes of the core alone in one layout, with no platform" \
  "$(printf '%s\n' "status 0" "Checked 4 launch entry points of 'openrosde'." "Checked the node names of 1 layouts of 'openrosde'.")" \
  "$(echo "status ${OPENROSDE_TEST_EXIT_CODE}"; echo "${OPENROSDE_TEST_OUTPUT}" | grep -E '^(Error|Checked)')"
openrosde-test-select-template env/ur5e.env
openrosde-test-run ${OPENROSDE_TEST_CHECK_LAUNCH} rover
openrosde-test-check "fails when the settings select another setup" \
  "$(printf '%s\n' "status 1" "Error: The settings select the setup 'ur5e', not 'rover', so check 'rover' after selecting it.")" \
  "$(echo "status ${OPENROSDE_TEST_EXIT_CODE}"; echo "${OPENROSDE_TEST_OUTPUT}" | grep '^Error')"

################################################################################

# Check the commands that could move a robot in a folder of scripts, with one launch file of a simulation allowed.
openrosde-test-write-file ci-sample/check-in-container.bash \
  "#!/bin/bash" \
  "# A comment may name rosrun and roslaunch freely." \
  "roslaunch --files acme_bringup robot_realworld.launch" \
  "roslaunch acme_bringup robot_realworld.launch --nodes" \
  "roslaunch --dump-params acme_bringup robot_realworld.launch" \
  "roslaunch acme_sim sim_world_gazebo.launch gui:=false" \
  "roslaunch acme_bringup robot_realworld.launch" \
  "cd /tmp && rosrun acme_tools move_arm.py" \
  "rostopic  pub /cmd_vel geometry_msgs/Twist '{}'" \
  "echo done; rosservice call /reset" \
  "bash run-roslaunch-repeatedly.bash robot_realworld.launch" \
  "rostopic echo /joint_states" \
  "/opt/ros/noetic/bin/roslaunch acme_bringup robot_realworld.launch" \
  "roslaunch acme_bringup robot_realworld.launch # see --files" \
  "roslaunch acme_bringup robot_realworld.launch & echo --files" \
  'roslaunch acme_bringup "${ACME_LAUNCH_FILE}" # sim_world_gazebo.launch' \
  "roslaunch --files acme_bringup robot_realworld.launch # resolves the files only"
openrosde-test-write-file ci-sample/allowed-simulation-launches.txt "# Simulations of the tests." "sim_world_gazebo.launch"
openrosde-test-run bash ./gitlab-ci/check-no-motion.bash ci-sample missing-folder
openrosde-test-check "fails on every command that could move a robot, after a path, with an option or a launch file in a comment, or in the background, and allows the rest, a simulation of the allowlist, and a missing folder" \
  "$(printf '%s\n' "status 1" "Skipping 'missing-folder', which is not a folder." "Checked 1 files for commands that could move a robot." \
    "  - ci-sample/check-in-container.bash:7: 'roslaunch' in: roslaunch acme_bringup robot_realworld.launch" \
    "  - ci-sample/check-in-container.bash:8: 'rosrun' in: rosrun acme_tools move_arm.py" \
    "  - ci-sample/check-in-container.bash:9: 'rostopic  pub' in: rostopic  pub /cmd_vel geometry_msgs/Twist '{}'" \
    "  - ci-sample/check-in-container.bash:10: 'rosservice call' in: rosservice call /reset" \
    "  - ci-sample/check-in-container.bash:13: 'roslaunch' in: /opt/ros/noetic/bin/roslaunch acme_bringup robot_realworld.launch" \
    "  - ci-sample/check-in-container.bash:14: 'roslaunch' in: roslaunch acme_bringup robot_realworld.launch # see --files" \
    "  - ci-sample/check-in-container.bash:15: 'roslaunch' in: roslaunch acme_bringup robot_realworld.launch" \
    '  - ci-sample/check-in-container.bash:16: '"'roslaunch'"' in: roslaunch acme_bringup "${ACME_LAUNCH_FILE}" # sim_world_gazebo.launch')" \
  "$(echo "status ${OPENROSDE_TEST_EXIT_CODE}"; echo "${OPENROSDE_TEST_OUTPUT}" | grep -E "^(Skipping|Checked|  - )")"
openrosde-test-run bash ./gitlab-ci/check-no-motion.bash gitlab-ci
openrosde-test-check "finds no command that could move a robot in the scripts of the CI of the core" \
  "status 0" \
  "status ${OPENROSDE_TEST_EXIT_CODE}"

# Check a 'roslaunch' of several launch files, which starts every one of them.
openrosde-test-write-file ci-several/check-in-container.bash \
  "#!/bin/bash" \
  "roslaunch ./launch/sim_world_gazebo.launch ./launch/robot_realworld.launch" \
  "roslaunch ./launch/sim_world_gazebo.launch ./launch/sim_arm_gazebo.launch gui:=false" \
  "roslaunch acme_bringup robot_realworld.launch sim_world_gazebo.launch" \
  "roslaunch ./launch/sim_world_gazebo.launch \"./launch/robot_realworld.launch\""
openrosde-test-write-file ci-several/allowed-simulation-launches.txt "sim_world_gazebo.launch" "sim_arm_gazebo.launch"
openrosde-test-run bash ./gitlab-ci/check-no-motion.bash ci-several
openrosde-test-check "allows a 'roslaunch' of several launch files only when the allowlist names every one, whichever comes first" \
  "$(printf '%s\n' "status 1" \
    "  - ci-several/check-in-container.bash:2: 'roslaunch' in: roslaunch ./launch/sim_world_gazebo.launch ./launch/robot_realworld.launch" \
    "  - ci-several/check-in-container.bash:4: 'roslaunch' in: roslaunch acme_bringup robot_realworld.launch sim_world_gazebo.launch" \
    "  - ci-several/check-in-container.bash:5: 'roslaunch' in: roslaunch ./launch/sim_world_gazebo.launch \"./launch/robot_realworld.launch\"")" \
  "$(echo "status ${OPENROSDE_TEST_EXIT_CODE}"; echo "${OPENROSDE_TEST_OUTPUT}" | grep -E "^  - ")"

################################################################################

# Check the clone of the extensions: nothing to clone, then the overrides and the URLs that it refuses before it installs anything.
OPENROSDE_TEST_REPOS_FILE="${OPENROSDE_TEST_WORK_DIR}/test.repos"
printf '%s\n' "repositories:" "  openrosde-platform-foo:" "    type: git" "    url: https://gitlab.example.com/acme/openrosde-platform-foo.git" "    version: v1.0.0" > "${OPENROSDE_TEST_REPOS_FILE}"
printf '%s\n' "# No extension for the tests, in the layout of 'gitlab-ci/extensions.repos'." "repositories: {}" > "${OPENROSDE_TEST_WORK_DIR}/empty.repos"
openrosde-test-run bash ./gitlab-ci/clone-extensions.bash "${OPENROSDE_TEST_WORK_DIR}/empty.repos"
openrosde-test-check "clones nothing when the file lists no repository" \
  "$(printf '%s\n' "status 0" "No extension to clone: '${OPENROSDE_TEST_WORK_DIR}/empty.repos' lists no repository.")" \
  "$(echo "status ${OPENROSDE_TEST_EXIT_CODE}"; echo "${OPENROSDE_TEST_OUTPUT}")"
sed 's/^ /   /' "${OPENROSDE_TEST_REPOS_FILE}" > "${OPENROSDE_TEST_WORK_DIR}/indented.repos"
openrosde-test-run bash ./gitlab-ci/clone-extensions.bash "${OPENROSDE_TEST_WORK_DIR}/indented.repos"
openrosde-test-check "refuses a file indented by four spaces, rather than reading no name from it and cloning nothing" \
  "$(printf '%s\n' "status 1" "Error: '${OPENROSDE_TEST_WORK_DIR}/indented.repos' holds lines that this script does not read, which wants each name indented by two spaces under 'repositories:', and its 'type', 'url', and 'version' by four:" "  -     openrosde-platform-foo:")" \
  "$(echo "status ${OPENROSDE_TEST_EXIT_CODE}"; echo "${OPENROSDE_TEST_OUTPUT}" | head -n 2)"
grep -v 'url:' "${OPENROSDE_TEST_REPOS_FILE}" > "${OPENROSDE_TEST_WORK_DIR}/no-url.repos"
openrosde-test-run bash ./gitlab-ci/clone-extensions.bash "${OPENROSDE_TEST_WORK_DIR}/no-url.repos"
openrosde-test-check "refuses a name without a URL" \
  "$(printf '%s\n' "status 1" "Error: '${OPENROSDE_TEST_WORK_DIR}/no-url.repos' lists 1 names but 0 URLs, rather than one 'url' per name.")" \
  "$(echo "status ${OPENROSDE_TEST_EXIT_CODE}"; echo "${OPENROSDE_TEST_OUTPUT}")"
OPENROSDE_CI_EXTENSION_OVERRIDE="acme-robots=main@${OPENROSDE_TEST_COMMIT}" openrosde-test-run bash ./gitlab-ci/clone-extensions.bash "${OPENROSDE_TEST_REPOS_FILE}"
openrosde-test-check "refuses an override of an extension that the file does not list" \
  "$(printf '%s\n' "status 1" "Error: 'OPENROSDE_CI_EXTENSION_OVERRIDE' names the extension 'acme-robots', which '${OPENROSDE_TEST_REPOS_FILE}' does not list, and only a listed extension can be tested at another version.")" \
  "$(echo "status ${OPENROSDE_TEST_EXIT_CODE}"; echo "${OPENROSDE_TEST_OUTPUT}")"
OPENROSDE_CI_EXTENSION_OVERRIDE="openrosde-platform-foo=main@0123abc" openrosde-test-run bash ./gitlab-ci/clone-extensions.bash "${OPENROSDE_TEST_REPOS_FILE}"
openrosde-test-check "refuses an override without the full hash of a commit" \
  "$(printf '%s\n' "status 1" "Error: 'OPENROSDE_CI_EXTENSION_OVERRIDE' must read '<name>=<branch>@<commit>', with the full hash of the commit, but it is 'openrosde-platform-foo=main@0123abc'.")" \
  "$(echo "status ${OPENROSDE_TEST_EXIT_CODE}"; echo "${OPENROSDE_TEST_OUTPUT}")"
printf '%s\n' "  openrosde-device-baz:" "    type: git" "    url: https://gitlab-ci-token:example-token@gitlab.example.com/acme/openrosde-device-baz.git" "    version: v1.0.0" >> "${OPENROSDE_TEST_REPOS_FILE}"
openrosde-test-run bash ./gitlab-ci/clone-extensions.bash "${OPENROSDE_TEST_REPOS_FILE}"
openrosde-test-check "refuses a URL that carries a token" \
  "$(printf '%s\n' "status 1" "Error: '${OPENROSDE_TEST_REPOS_FILE}' lists URLs that are not anonymous HTTPS, which the CI does not clone:" "  - https://gitlab-ci-token:example-token@gitlab.example.com/acme/openrosde-device-baz.git")" \
  "$(echo "status ${OPENROSDE_TEST_EXIT_CODE}"; echo "${OPENROSDE_TEST_OUTPUT}")"

################################################################################

# Check the source hash of an image with the real 'git', in a repository of the core and in a repository of an extension.
# A folder of the core must give the hash that the script gave when it hashed every folder in the core, so that every image built before stays reused.
rm "${OPENROSDE_TEST_STUB_DIR}/git"
export CI_REGISTRY_IMAGE="${OPENROSDE_TEST_REGISTRY}" CI_PIPELINE_ID=7 CI_COMMIT_REF_SLUG=feat-foo
function openrosde-test-commit-folder () {
  git -C "$1" -c init.defaultBranch=main init --quiet && git -C "$1" add --all && git -C "$1" -c user.name=Tester -c user.email=tester@example.com commit --quiet --message "Test"
}
openrosde-test-commit-folder "${OPENROSDE_TEST_ROOT_DIR}"
mkdir -p "${OPENROSDE_TEST_ROOT_DIR}/extensions/openrosde-platform-foo/docker/foo-devel"
echo "FROM scratch" > "${OPENROSDE_TEST_ROOT_DIR}/extensions/openrosde-platform-foo/docker/foo-devel/Dockerfile"
openrosde-test-commit-folder "${OPENROSDE_TEST_ROOT_DIR}/extensions/openrosde-platform-foo"
OPENROSDE_TEST_OLD_HASH="$(cd "${OPENROSDE_TEST_ROOT_DIR}" && for OPENROSDE_TEST_SOURCE_DIR in docker/openrosde-base docker/ur5e-devel; do git rev-parse "HEAD:${OPENROSDE_TEST_SOURCE_DIR}"; done | sha256sum | cut -c1-40)"
openrosde-test-run bash ./gitlab-ci/build-ci-image.bash ur5e-devel . docker/ur5e-devel/Dockerfile docker/openrosde-base,docker/ur5e-devel OPENROSDE_ROBOT_PLATFORM=ur5e
openrosde-test-check "gives a folder of the core the same hash as before, and builds from the core" \
  "$(printf '%s\n' "status 0" "Image 'ur5e-devel' from 'docker/openrosde-base,docker/ur5e-devel' has the source hash '${OPENROSDE_TEST_OLD_HASH}'." "--file ./docker/ur5e-devel/Dockerfile" "--push .")" \
  "$(echo "status ${OPENROSDE_TEST_EXIT_CODE}"; echo "${OPENROSDE_TEST_OUTPUT}" | grep '^Image'; openrosde-test-print-calls | grep '^docker buildx build' | grep -o -e '--file [^ ]*' -e '--push .*')"
OPENROSDE_TEST_EXTENSION_HASH="$(printf '%s\n' "$(git -C "${OPENROSDE_TEST_ROOT_DIR}" rev-parse HEAD:docker/openrosde-base)" "$(git -C "${OPENROSDE_TEST_ROOT_DIR}/extensions/openrosde-platform-foo" rev-parse HEAD:docker/foo-devel)" | sha256sum | cut -c1-40)"
openrosde-test-run bash ./gitlab-ci/build-ci-image.bash foo-devel extensions/openrosde-platform-foo docker/foo-devel/Dockerfile docker/openrosde-base,extensions/openrosde-platform-foo/docker/foo-devel
openrosde-test-check "hashes a folder of an extension in its own repository, and builds from the folder of the extension" \
  "$(printf '%s\n' "status 0" "Image 'foo-devel' from 'docker/openrosde-base,extensions/openrosde-platform-foo/docker/foo-devel' has the source hash '${OPENROSDE_TEST_EXTENSION_HASH}'." "--file extensions/openrosde-platform-foo/docker/foo-devel/Dockerfile" "--push extensions/openrosde-platform-foo")" \
  "$(echo "status ${OPENROSDE_TEST_EXIT_CODE}"; echo "${OPENROSDE_TEST_OUTPUT}" | grep '^Image'; openrosde-test-print-calls | grep '^docker buildx build' | grep -o -e '--file [^ ]*' -e '--push .*')"
mkdir -p "${OPENROSDE_TEST_ROOT_DIR}/docker/bar-devel"
echo "FROM scratch" > "${OPENROSDE_TEST_ROOT_DIR}/docker/bar-devel/Dockerfile"
OPENROSDE_TEST_HASH_REPORT=""
for OPENROSDE_TEST_SOURCE_DIR in docker/missing-devel docker/bar-devel; do
  openrosde-test-run bash ./gitlab-ci/build-ci-image.bash bar-devel . "${OPENROSDE_TEST_SOURCE_DIR}/Dockerfile" "docker/openrosde-base,${OPENROSDE_TEST_SOURCE_DIR}"
  OPENROSDE_TEST_HASH_REPORT="${OPENROSDE_TEST_HASH_REPORT}${OPENROSDE_TEST_SOURCE_DIR} ${OPENROSDE_TEST_EXIT_CODE} $(openrosde-test-print-calls | grep -c '^docker ') $(echo "${OPENROSDE_TEST_OUTPUT}" | grep '^Error:')"$'\n'
done
openrosde-test-check "fails before calling Docker when a source folder is missing or not committed" \
  "$(printf '%s\n' "docker/missing-devel 1 0 Error: The source folder 'docker/missing-devel' of image 'bar-devel' is missing or not committed in a Git repository, so it has no hash." "docker/bar-devel 1 0 Error: The source folder 'docker/bar-devel' of image 'bar-devel' is missing or not committed in a Git repository, so it has no hash.")" \
  "${OPENROSDE_TEST_HASH_REPORT%$'\n'}"
rm -rf "${OPENROSDE_TEST_ROOT_DIR}/docker/bar-devel" "${OPENROSDE_TEST_ROOT_DIR}/.git" "${OPENROSDE_TEST_ROOT_DIR}/extensions/openrosde-platform-foo"
openrosde-test-add-stub git

################################################################################

# Check the tags that may be published.
OPENROSDE_TEST_PUBLISH_REPORT=""
for OPENROSDE_TEST_PUBLISHED_TAG in dev main v3.0.0 v3.0 v3.0.0-rc.1 feat-foo; do
  openrosde-test-run bash ./gitlab-ci/publish-ci-images.bash "${OPENROSDE_TEST_PUBLISHED_TAG}" openrosde-base
  OPENROSDE_TEST_PUBLISH_REPORT="${OPENROSDE_TEST_PUBLISH_REPORT}${OPENROSDE_TEST_PUBLISHED_TAG} ${OPENROSDE_TEST_EXIT_CODE} $(openrosde-test-print-calls | grep -c '^docker buildx imagetools create')"$'\n'
done
openrosde-test-check "publishes 'dev', 'main', and a release, and refuses any other tag" \
  "$(printf '%s\n' "dev 0 1" "main 0 1" "v3.0.0 0 1" "v3.0 1 0" "v3.0.0-rc.1 1 0" "feat-foo 1 0")" \
  "${OPENROSDE_TEST_PUBLISH_REPORT%$'\n'}"

################################################################################

# Check that the test of a setup refuses outside the CI to replace the '.env.custom' of a developer, here the template of 'ur5e', before calling Docker.
# 'JOB_CPUS', which the runner of the CI may set for this suite too, stays unset unless a check sets it.
unset JOB_CPUS
export OPENROSDE_CI_IMAGE_REGISTRY="${OPENROSDE_TEST_REGISTRY}" OPENROSDE_CI_IMAGE_TAG=pipeline-7
cp "${OPENROSDE_TEST_ROOT_DIR}/.env.custom" "${OPENROSDE_TEST_WORK_DIR}/env.custom.before"
openrosde-test-run env -u CI bash ./gitlab-ci/test-catkin-workspaces.bash ur5e
openrosde-test-check "refuses outside the CI to replace an existing '.env.custom', and leaves it as it was" \
  "$(printf '%s\n' "status 1" "same settings" "0 Docker calls" "Error: This script replaces '.env.custom' with the settings of the setup 'ur5e', so outside the CI it runs only in a checkout without '.env.custom': move it aside first, such as with 'mv .env.custom .env.custom.bak', and back afterwards.")" \
  "$(echo "status ${OPENROSDE_TEST_EXIT_CODE}"; cmp -s "${OPENROSDE_TEST_ROOT_DIR}/.env.custom" "${OPENROSDE_TEST_WORK_DIR}/env.custom.before" && echo "same settings"; echo "$(openrosde-test-print-calls | grep -c '^docker ') Docker calls"; echo "${OPENROSDE_TEST_OUTPUT}" | grep '^Error')"
export CI=true

# Check the images that the test of a setup reads: none without a tag or a given image, a given image, and a published tag.
openrosde-test-run env -u OPENROSDE_CI_IMAGE_TAG bash ./gitlab-ci/test-catkin-workspaces.bash ur5e
openrosde-test-check "fails before calling Docker when no image is given and no tag names the default one" \
  "$(printf '%s\n' "status 1" "0 Docker calls" "Error: No image was given, and 'OPENROSDE_CI_IMAGE_REGISTRY' and 'OPENROSDE_CI_IMAGE_TAG', which name the default one, are not both set.")" \
  "$(echo "status ${OPENROSDE_TEST_EXIT_CODE}"; echo "$(openrosde-test-print-calls | grep -c '^docker ') Docker calls"; echo "${OPENROSDE_TEST_OUTPUT}" | grep '^Error')"
openrosde-test-run env -u OPENROSDE_CI_IMAGE_TAG bash ./gitlab-ci/test-catkin-workspaces.bash ur5e registry.example.com/acme/other/ur5e-devel:v3.0.0
openrosde-test-check "tests in the image given, with no tag set" \
  "$(printf '%s\n' "status 0" "registry.example.com/acme/other/ur5e-devel:v3.0.0 sleep infinity")" \
  "$(echo "status ${OPENROSDE_TEST_EXIT_CODE}"; openrosde-test-print-calls | grep '^docker create ' | grep -o '[^ ]* sleep infinity$')"
OPENROSDE_CI_IMAGE_TAG=v3.0.0 openrosde-test-run bash ./gitlab-ci/test-catkin-workspaces.bash ur5e
openrosde-test-check "reads the image of the platform with the tag of 'OPENROSDE_CI_IMAGE_TAG', such as a release, rather than with the ID of the pipeline" \
  "$(printf '%s\n' "status 0" "${OPENROSDE_TEST_REGISTRY}/ur5e-devel:v3.0.0 sleep infinity")" \
  "$(echo "status ${OPENROSDE_TEST_EXIT_CODE}"; openrosde-test-print-calls | grep '^docker create ' | grep -o '[^ ]* sleep infinity$')"

# Check the test of a setup, whose calls of Docker the stub logs.
JOB_CPUS=8 openrosde-test-run bash ./gitlab-ci/test-catkin-workspaces.bash ur5e
openrosde-test-check "selects the template of the setup, builds in the image of its platform with the CPUs of the job, cuts the network, then runs the checks" \
  "$(printf '%s\n' "status 0" "same template" \
    "docker rm --force openrosde-ci-ur5e" \
    "docker create --name openrosde-ci-ur5e --env OPENROSDE_ROBOT_PLATFORM=ur5e --env OPENROSDE_ROBOT_SETUP=ur5e --env OPENROSDE_ROBOT_EXTENSIONS= --env OPENROSDE_CONTAINER_ROOT_DIR=/root/OpenRoSDE --env OPENROSDE_BUILD_JOBS=8 ${OPENROSDE_TEST_REGISTRY}/ur5e-devel:pipeline-7 sleep infinity" \
    "docker cp ./. openrosde-ci-ur5e:/root/OpenRoSDE/" \
    "docker start openrosde-ci-ur5e" \
    "docker exec openrosde-ci-ur5e bash -c source /root/OpenRoSDE/scripts/load-openrosde-settings.bash /root/OpenRoSDE && bash /root/OpenRoSDE/docker/openrosde-base/scripts/reset-catkin-workspaces.bash" \
    "docker inspect --format {{ range \$name, \$network := .NetworkSettings.Networks }}{{ \$name }} {{ end }} openrosde-ci-ur5e" \
    "docker network disconnect bridge openrosde-ci-ur5e" \
    "docker inspect --format {{ len .NetworkSettings.Networks }} openrosde-ci-ur5e" \
    "docker exec openrosde-ci-ur5e bash /root/OpenRoSDE/gitlab-ci/check-robot-model.bash" \
    "docker exec openrosde-ci-ur5e bash /root/OpenRoSDE/gitlab-ci/check-launch-files.bash ur5e" \
    "docker exec openrosde-ci-ur5e bash /root/OpenRoSDE/gitlab-ci/run-extension-checks.bash ur5e")" \
  "$(echo "status ${OPENROSDE_TEST_EXIT_CODE}"; head -n "$(grep -c '' "${OPENROSDE_TEST_ROOT_DIR}/env/ur5e.env")" "${OPENROSDE_TEST_ROOT_DIR}/.env.custom" | cmp -s - "${OPENROSDE_TEST_ROOT_DIR}/env/ur5e.env" && echo "same template"; openrosde-test-print-calls | grep '^docker ' | grep -v -e 'mesh2glb' -e '^docker exec openrosde-ci-ur5e bash -c cd / ' -e '^docker exec --interactive openrosde-ci-ur5e tar ')"
openrosde-test-check "gives the meshes of the container their GLBs in a converter of the same tag with no network, then checks the robot model" \
  "$(printf '%s\n' \
    "docker pull --quiet ${OPENROSDE_TEST_REGISTRY}/openrosde-mesh2glb:pipeline-7" \
    "docker rm --force openrosde-ci-ur5e-mesh2glb" \
    "docker run --detach --name openrosde-ci-ur5e-mesh2glb --network none ${OPENROSDE_TEST_REGISTRY}/openrosde-mesh2glb:pipeline-7 sleep infinity" \
    "docker exec openrosde-ci-ur5e-mesh2glb python3 -I /opt/mesh2glb/generate-mesh-glbs.py --jobs 8 --out /out /in" \
    "docker exec --interactive openrosde-ci-ur5e tar --extract --file - --directory /" \
    "docker rm --force openrosde-ci-ur5e-mesh2glb" \
    "docker exec openrosde-ci-ur5e bash /root/OpenRoSDE/gitlab-ci/check-robot-model.bash")" \
  "$(openrosde-test-print-calls | grep -E '^docker (pull|rm --force openrosde-ci-ur5e-mesh2glb|run --detach|exec openrosde-ci-ur5e-mesh2glb python3|exec --interactive openrosde-ci-ur5e tar|exec openrosde-ci-ur5e bash /root/OpenRoSDE/gitlab-ci/check-robot-model)')"
OPENROSDE_TEST_FAILING_CALL="pull --quiet" openrosde-test-run bash ./gitlab-ci/test-catkin-workspaces.bash ur5e
openrosde-test-check "skips the robot model, and passes, when the converter cannot be pulled, as in the pipeline of an extension before the core publishes it" \
  "$(printf '%s\n' "status 0" "Warning: The converter image '${OPENROSDE_TEST_REGISTRY}/openrosde-mesh2glb:pipeline-7' cannot be pulled, so the robot model is not checked." "0 checks of the robot model")" \
  "$(echo "status ${OPENROSDE_TEST_EXIT_CODE}"; echo "${OPENROSDE_TEST_OUTPUT}" | grep '^Warning: The converter'; echo "$(openrosde-test-print-calls | grep -c 'check-robot-model') checks of the robot model")"
OPENROSDE_TEST_FAILING_CALL="reset-catkin-workspaces" openrosde-test-run bash ./gitlab-ci/test-catkin-workspaces.bash ur5e
openrosde-test-check "runs no check when the workspaces fail to build, and keeps the logs of every workspace of the setup" \
  "$(printf '%s\n' "status 1" \
    "docker cp openrosde-ci-ur5e:/root/OpenRoSDE/ros/openrosde_catkin_ws/logs ci-logs/ros/openrosde_catkin_ws/" \
    "docker cp openrosde-ci-ur5e:/root/OpenRoSDE/ros/ur5e_catkin_ws/logs ci-logs/ros/ur5e_catkin_ws/" \
    "docker cp openrosde-ci-ur5e:/root/OpenRoSDE/ros/user_catkin_ws/logs ci-logs/ros/user_catkin_ws/")" \
  "$(echo "status ${OPENROSDE_TEST_EXIT_CODE}"; openrosde-test-print-calls | grep -E '^docker (network|exec openrosde-ci-ur5e bash /)|^docker cp openrosde-ci')"
rm -rf "${OPENROSDE_TEST_ROOT_DIR}/ci-logs"

# Check that the test of a setup refuses extra extensions that would run as code once written into '.env.custom', before writing it or calling Docker.
cp "${OPENROSDE_TEST_ROOT_DIR}/.env.custom" "${OPENROSDE_TEST_WORK_DIR}/env.custom.before"
OPENROSDE_CI_EXTRA_EXTENSIONS='openrosde-device-bar" $(touch pwned) "' openrosde-test-run bash ./gitlab-ci/test-catkin-workspaces.bash rover
openrosde-test-check "refuses extra extensions other than folder names, and leaves '.env.custom' as it was" \
  "$(printf '%s\n' "status 1" "same settings" "0 Docker calls" "no file" "Error: 'OPENROSDE_CI_EXTRA_EXTENSIONS' may hold only folder names separated by spaces, but it is 'openrosde-device-bar\" \$(touch pwned) \"'.")" \
  "$(echo "status ${OPENROSDE_TEST_EXIT_CODE}"; cmp -s "${OPENROSDE_TEST_ROOT_DIR}/.env.custom" "${OPENROSDE_TEST_WORK_DIR}/env.custom.before" && echo "same settings"; echo "$(openrosde-test-print-calls | grep -c '^docker ') Docker calls"; [ -e "${OPENROSDE_TEST_ROOT_DIR}/pwned" ] && echo "a file" || echo "no file"; echo "${OPENROSDE_TEST_OUTPUT}" | grep '^Error')"

# Check a setup of an extension with a Docker layer and an extension that the CI adds to it.
OPENROSDE_CI_EXTRA_EXTENSIONS="openrosde-device-bar" openrosde-test-run bash ./gitlab-ci/test-catkin-workspaces.bash rover
openrosde-test-check "adds the extensions of 'OPENROSDE_CI_EXTRA_EXTENSIONS', builds their layers on the image of the platform, and tests in the last layer" \
  "$(printf '%s\n' "status 0" \
    'OPENROSDE_ROBOT_EXTENSIONS="${OPENROSDE_ROBOT_EXTENSIONS} openrosde-device-bar"' \
    "-t openrosde-local/rover/bar-devel:latest on ${OPENROSDE_TEST_REGISTRY}/rover-devel:pipeline-7" \
    "--env OPENROSDE_ROBOT_EXTENSIONS= openrosde-device-bar --env OPENROSDE_CONTAINER_ROOT_DIR=/root/OpenRoSDE --env OPENROSDE_BUILD_JOBS= openrosde-local/rover/bar-devel:latest sleep infinity")" \
  "$(echo "status ${OPENROSDE_TEST_EXIT_CODE}"; grep '^OPENROSDE_ROBOT_EXTENSIONS=' "${OPENROSDE_TEST_ROOT_DIR}/.env.custom" | tail -n 1; openrosde-test-print-calls | grep '^docker build ' | sed -e 's/.*OPENROSDE_PARENT_IMAGE=\([^ ]*\) .* \(-t [^ ]*\) .*/\2 on \1/'; openrosde-test-print-calls | grep '^docker create ' | grep -o -e '--env OPENROSDE_ROBOT_EXTENSIONS=.*')"
openrosde-test-run bash ./gitlab-ci/test-catkin-workspaces.bash acme-rover-lab
openrosde-test-check "tests a setup of an extension in the image of its platform, with the layer of the extension it lists" \
  "$(printf '%s\n' "status 0" "Testing the setup 'acme-rover-lab' of the platform 'rover' with the extensions 'openrosde-device-bar'." "openrosde-local/acme-rover-lab/bar-devel:latest sleep infinity")" \
  "$(echo "status ${OPENROSDE_TEST_EXIT_CODE}"; echo "${OPENROSDE_TEST_OUTPUT}" | grep '^Testing'; openrosde-test-print-calls | grep '^docker create ' | grep -o '[^ ]* sleep infinity$')"
mv "${OPENROSDE_TEST_ROOT_DIR}/${OPENROSDE_TEST_BAR_DIR}" "${OPENROSDE_TEST_WORK_DIR}/bar"
openrosde-test-run bash ./gitlab-ci/test-catkin-workspaces.bash acme-rover-lab
openrosde-test-check "fails before creating a container when an extension of the setup is missing" \
  "$(printf '%s\n' "status 1" "0 containers" "Error: The setup 'acme-rover-lab' lists extensions that no single folder holds: openrosde-device-bar.")" \
  "$(echo "status ${OPENROSDE_TEST_EXIT_CODE}"; echo "$(openrosde-test-print-calls | grep -c '^docker create') containers"; echo "${OPENROSDE_TEST_OUTPUT}" | grep '^Error: The setup')"
mv "${OPENROSDE_TEST_WORK_DIR}/bar" "${OPENROSDE_TEST_ROOT_DIR}/${OPENROSDE_TEST_BAR_DIR}"
openrosde-test-run bash ./gitlab-ci/test-catkin-workspaces.bash acme-missing-lab
openrosde-test-check "fails when no template declares the setup" \
  "$(printf '%s\n' "status 1" "Error: Neither the core nor a cloned extension holds the template 'env/acme-missing-lab.env' of the setup 'acme-missing-lab'.")" \
  "$(echo "status ${OPENROSDE_TEST_EXIT_CODE}"; echo "${OPENROSDE_TEST_OUTPUT}" | grep '^Error')"

# Check the core alone, in the base image, with no platform.
openrosde-test-run bash ./gitlab-ci/test-catkin-workspaces.bash openrosde
openrosde-test-check "tests the core alone in the base image, with no platform and no extension" \
  "$(printf '%s\n' "status 0" "OPENROSDE_ROBOT_PLATFORM=" "OPENROSDE_ROBOT_SETUP=" "OPENROSDE_ROBOT_EXTENSIONS=" \
    "--env OPENROSDE_ROBOT_PLATFORM= --env OPENROSDE_ROBOT_SETUP= --env OPENROSDE_ROBOT_EXTENSIONS= --env OPENROSDE_CONTAINER_ROOT_DIR=/root/OpenRoSDE --env OPENROSDE_BUILD_JOBS= ${OPENROSDE_TEST_REGISTRY}/openrosde-base:pipeline-7 sleep infinity")" \
  "$(echo "status ${OPENROSDE_TEST_EXIT_CODE}"; grep '^OPENROSDE_ROBOT_' "${OPENROSDE_TEST_ROOT_DIR}/.env.custom"; openrosde-test-print-calls | grep '^docker create ' | grep -o -e '--env OPENROSDE_ROBOT_PLATFORM=.*')"

################################################################################

# Remove the scratch copy and report the result.
openrosde-test-remove-copy
openrosde-test-finish-suite
