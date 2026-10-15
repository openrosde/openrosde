#!/bin/bash

# This suite checks the platforms on ROS 2 beside those on ROS 1, with every call to Docker and to ROS stubbed, so that no check builds an image, starts a container, or starts a node.
# It covers what the loader resolves for a platform that declares 'OPENROSDE_ROS_VERSION=2' and for a platform on ROS 1 of the same extension, the refusal of another version, the base image that the build reads, the scripts of the container on ROS 2, the launch check, the check that no script moves a robot with the commands of ROS 2, the child pipeline, and the test of the core alone and of a setup on ROS 2.
# It uses the extension 'openrosde-platform-foo', which holds the platform 'foo' on ROS 1 and the platform 'foo-ros2' on ROS 2, as a platform repository may hold both.
#
# Usage: bash ./tests/run.bash test-ros2-platforms

################################################################################

# Load the helpers and create the scratch copy.
source "${OPENROSDE_TEST_SOURCE_DIR}/tests/load-test-helpers.bash"
openrosde-test-create-copy
OPENROSDE_TEST_FOO_DIR="extensions/openrosde-platform-foo"
OPENROSDE_TEST_REGISTRY="registry.example.com/acme/openrosde"

# Create the platform 'foo' on ROS 1 and the platform 'foo-ros2' on ROS 2 in one extension, each with its template, image, overlay, workspace, and panes, and a shell configuration that names the launch package of 'foo-ros2'.
openrosde-test-create-extension openrosde-platform-foo
openrosde-test-write-platform-template "${OPENROSDE_TEST_FOO_DIR}" foo
openrosde-test-write-platform-template "${OPENROSDE_TEST_FOO_DIR}" foo-ros2
printf '%s\n' "OPENROSDE_ROS_VERSION=2" "OPENROSDE_ROS_DISTRO=lyrical" >> "${OPENROSDE_TEST_ROOT_DIR}/${OPENROSDE_TEST_FOO_DIR}/env/foo-ros2.env"
for OPENROSDE_TEST_PLATFORM_NAME in foo foo-ros2; do
  openrosde-test-write-file "${OPENROSDE_TEST_FOO_DIR}/docker/${OPENROSDE_TEST_PLATFORM_NAME}-devel/Dockerfile" "FROM scratch"
  openrosde-test-write-file "${OPENROSDE_TEST_FOO_DIR}/docker/docker-compose-${OPENROSDE_TEST_PLATFORM_NAME}.yaml" "services: {}"
done
mkdir -p "${OPENROSDE_TEST_ROOT_DIR}/${OPENROSDE_TEST_FOO_DIR}/ros/foo_catkin_ws/src" "${OPENROSDE_TEST_ROOT_DIR}/${OPENROSDE_TEST_FOO_DIR}/ros2/foo_colcon_ws/src"
openrosde-test-write-file "${OPENROSDE_TEST_FOO_DIR}/tmux/foo.panes" "default-gazebo  robot  foo_bringup_default_gazebo.launch"
openrosde-test-write-file "${OPENROSDE_TEST_FOO_DIR}/tmux/foo-ros2.panes" \
  "default-gazebo     robot  foo_bringup_default_gazebo.launch.xml" \
  "default-realworld  robot  foo_rviz_default.launch.py use_sim_time:=false" \
  "*                  extra  shell"
openrosde-test-write-file "${OPENROSDE_TEST_FOO_DIR}/scripts/foo-ros2/initialize-bash-shell.bash" "OPENROSDE_LAUNCH_PACKAGE=openrosde_foo_launch"

# Replace the stub of 'colcon', which logs its call with the folder it runs in.
cat > "${OPENROSDE_TEST_STUB_DIR}/colcon" <<'EOF'
#!/bin/bash
echo "colcon $* in ${PWD} with MAKEFLAGS=${MAKEFLAGS}" >> "${OPENROSDE_TEST_COMMAND_LOG}"
if [ -n "${OPENROSDE_TEST_FAILING_CALL}" ] && [[ "colcon $*" == *"${OPENROSDE_TEST_FAILING_CALL}"* ]]; then
  exit 1
fi
exit 0
EOF

# Replace the stub of 'docker', which logs the base image and the distribution that a call of Docker Compose reads, and lists the network 'bridge' of a container until it is disconnected.
cat > "${OPENROSDE_TEST_STUB_DIR}/docker" <<'EOF'
#!/bin/bash
echo "docker $*" >> "${OPENROSDE_TEST_COMMAND_LOG}"
case "$*" in
  "compose "*)
    echo "compose reads ${OPENROSDE_BASE_IMAGE_NAME} ${OPENROSDE_ROS_DISTRO}" >> "${OPENROSDE_TEST_COMMAND_LOG}"
    ;;
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

# Print the base image and the workspace folders that the loader names for the selected setup.
function openrosde-test-print-ros-names () {
  (
    cd "${OPENROSDE_TEST_ROOT_DIR}" || exit 1
    source ./scripts/load-openrosde-env.bash test > /dev/null 2>&1
    echo "ros: ${OPENROSDE_ROS_VERSION} ${OPENROSDE_ROS_DISTRO} ${OPENROSDE_BASE_IMAGE_NAME} ${OPENROSDE_ROS_WORKSPACE_FOLDER} ${OPENROSDE_ROS_WORKSPACE_SUFFIX}"
  )
}

################################################################################

# Check what the loader resolves for the platform on ROS 2 and for the platform on ROS 1 of the same extension.
openrosde-test-select-template "${OPENROSDE_TEST_FOO_DIR}/env/foo-ros2.env"
openrosde-test-check "resolves the colcon workspaces, the base image of ROS 2, and the panes and the overlay of the platform on ROS 2 alone" \
  "$(printf '%s\n' \
    "ros: 2 lyrical openrosde-base-ros2 ros2 colcon_ws" \
    "workspaces: ./ros2/openrosde_colcon_ws ./${OPENROSDE_TEST_FOO_DIR}/ros2/foo_colcon_ws ./ros2/user_colcon_ws" \
    "overlays: ./${OPENROSDE_TEST_FOO_DIR}/docker/docker-compose-foo-ros2.yaml" \
    "panes: ./${OPENROSDE_TEST_FOO_DIR}/tmux/foo-ros2.panes ./tmux/openrosde-ros2.panes" \
    "platform-dockerfile: docker/foo-ros2-devel/Dockerfile")" \
  "$(openrosde-test-print-ros-names; openrosde-test-print-paths | grep -E '^(workspaces|overlays|panes|platform-dockerfile):')"
openrosde-test-select-template "${OPENROSDE_TEST_FOO_DIR}/env/foo.env"
openrosde-test-check "resolves the Catkin workspaces, the base image of ROS 1, and the panes and the overlay of the platform on ROS 1 of the same extension, as before" \
  "$(printf '%s\n' \
    "ros: 1 noetic openrosde-base ros catkin_ws" \
    "workspaces: ./ros/openrosde_catkin_ws ./${OPENROSDE_TEST_FOO_DIR}/ros/foo_catkin_ws ./ros/user_catkin_ws" \
    "overlays: ./${OPENROSDE_TEST_FOO_DIR}/docker/docker-compose-foo.yaml" \
    "panes: ./${OPENROSDE_TEST_FOO_DIR}/tmux/foo.panes ./tmux/openrosde.panes")" \
  "$(openrosde-test-print-ros-names; openrosde-test-print-paths | grep -E '^(workspaces|overlays|panes):')"

# Check that an entry script refuses a version of ROS other than '1' or '2' before calling Docker.
echo "OPENROSDE_ROS_VERSION=3" >> "${OPENROSDE_TEST_ROOT_DIR}/.env.custom"
openrosde-test-run bash ./BUILD-DOCKER-IMAGE.bash test
openrosde-test-check "refuses another version of ROS before calling Docker" \
  "$(printf '%s\n' "status 1" "0 Docker calls" "Error: 'OPENROSDE_ROS_VERSION' is '3' in '.env' or '.env.custom', but it must be '1' for ROS 1 or '2' for ROS 2.")" \
  "$(echo "status ${OPENROSDE_TEST_EXIT_CODE}"; echo "$(openrosde-test-print-calls | grep -c '^docker ') Docker calls"; echo "${OPENROSDE_TEST_OUTPUT}" | grep '^Error:')"

# Check that the build reads the base image of ROS 2 and its distribution, and names it when its pull fails.
openrosde-test-select-template "${OPENROSDE_TEST_FOO_DIR}/env/foo-ros2.env"
openrosde-test-run bash ./BUILD-DOCKER-IMAGE.bash local
openrosde-test-check "builds the base image of ROS 2 for a platform on ROS 2, with its distribution" \
  "compose reads openrosde-base-ros2 lyrical" \
  "$(openrosde-test-print-calls | grep '^compose reads' | sort -u)"
echo "OPENROSDE_DOCKER_BUILD_FALLBACK=false" >> "${OPENROSDE_TEST_ROOT_DIR}/.env.custom"
OPENROSDE_TEST_FAILING_CALL="pull openrosde-base" openrosde-test-run bash ./BUILD-DOCKER-IMAGE.bash test
openrosde-test-check "names the base image of ROS 2 when its pull fails" \
  "Error: The pull of 'registry.gitlab.com/coarobo/sde/openrosde-base-ros2:dev' failed, and 'OPENROSDE_DOCKER_BUILD_FALLBACK=false' does not build it locally." \
  "$(echo "${OPENROSDE_TEST_OUTPUT}" | grep '^Error:')"
openrosde-test-select-template "${OPENROSDE_TEST_FOO_DIR}/env/foo-ros2.env"

# Check that Terminator, whose layouts the platform on ROS 2 does not have, points to the 'tmux' session before starting any container.
openrosde-test-run bash ./RUN-TERMINATOR-TERMINAL.bash test default-realworld
openrosde-test-check "refuses to open Terminator for a platform with no layout, and names its 'tmux' session, before calling Docker" \
  "$(printf '%s\n' "status 1" "0 Docker calls" "Error: Neither the setup 'foo-ros2' nor its platform 'foo-ros2' has a Terminator layout 'terminator/<name>.config', so open its 'tmux' session instead: bash ./RUN-TMUX-SESSION.bash test default-realworld")" \
  "$(echo "status ${OPENROSDE_TEST_EXIT_CODE}"; echo "$(openrosde-test-print-calls | grep -c '^docker ') Docker calls"; echo "${OPENROSDE_TEST_OUTPUT}" | grep '^Error:')"

################################################################################

# Check the scripts of the container on ROS 2, which run with the settings exported as in a shell of the container.
OPENROSDE_TEST_CONTAINER_SHELL='set -a; source ./.env; source ./.env.custom; set +a; export OPENROSDE_CONTAINER_ROOT_DIR="${PWD}";'
mkdir -p "${OPENROSDE_TEST_ROOT_DIR}/${OPENROSDE_TEST_FOO_DIR}/ros2/foo_colcon_ws/install/old" "${OPENROSDE_TEST_ROOT_DIR}/ros2/openrosde_colcon_ws/log"
echo "OPENROSDE_BUILD_JOBS=4" >> "${OPENROSDE_TEST_ROOT_DIR}/.env.custom"
openrosde-test-run bash -c "${OPENROSDE_TEST_CONTAINER_SHELL} bash ./docker/openrosde-base/scripts/reset-catkin-workspaces.bash"
openrosde-test-check "resets the colcon workspaces of the distribution of ROS 2: updates 'rosdep' for it, removes their spaces, initializes nothing, and builds each in order with the jobs of 'OPENROSDE_BUILD_JOBS'" \
  "$(printf '%s\n' "status 0" "rosdep update --rosdistro lyrical" \
    "colcon build --parallel-workers 4 in ./ros2/openrosde_colcon_ws with MAKEFLAGS=-j4 -l4" \
    "colcon build --parallel-workers 4 in ./${OPENROSDE_TEST_FOO_DIR}/ros2/foo_colcon_ws with MAKEFLAGS=-j4 -l4" \
    "colcon build --parallel-workers 4 in ./ros2/user_colcon_ws with MAKEFLAGS=-j4 -l4" \
    "removed spaces" "0 Catkin calls")" \
  "$(echo "status ${OPENROSDE_TEST_EXIT_CODE}"; openrosde-test-print-calls | grep -E '^(rosdep|colcon) '
    [ ! -e "${OPENROSDE_TEST_ROOT_DIR}/${OPENROSDE_TEST_FOO_DIR}/ros2/foo_colcon_ws/install" ] && [ ! -e "${OPENROSDE_TEST_ROOT_DIR}/ros2/openrosde_colcon_ws/log" ] && echo "removed spaces"
    echo "$(openrosde-test-print-calls | grep -c -E '^catkin') Catkin calls")"
OPENROSDE_TEST_FAILING_CALL="colcon" openrosde-test-run bash -c "${OPENROSDE_TEST_CONTAINER_SHELL} bash ./docker/openrosde-base/scripts/build-catkin-workspaces.bash"
openrosde-test-check "fails and names the workspaces that 'colcon build' fails to build" \
  "$(printf '%s\n' "status 1" "Failed to build the Catkin workspaces: ./ros2/openrosde_colcon_ws ./${OPENROSDE_TEST_FOO_DIR}/ros2/foo_colcon_ws ./ros2/user_colcon_ws")" \
  "$(echo "status ${OPENROSDE_TEST_EXIT_CODE}"; echo "${OPENROSDE_TEST_OUTPUT}" | grep '^Failed to build' | sed "s#${OPENROSDE_TEST_ROOT_DIR}#.#g")"
cat > "${OPENROSDE_TEST_STUB_DIR}/colcon" <<'EOF'
#!/bin/bash
[ -n "${OPENROSDE_TEST_FAILING_CALL}" ] && exit 1
mkdir -p install && echo "echo sourced ${PWD}/install/setup.bash" > install/setup.bash
exit 0
EOF
openrosde-test-run bash -c "${OPENROSDE_TEST_CONTAINER_SHELL} source ./docker/openrosde-base/scripts/source-catkin-workspaces.bash"
openrosde-test-check "sources nothing from a colcon workspace that has not been built" \
  "0 sourced" \
  "$(echo "${OPENROSDE_TEST_OUTPUT}" | grep -c '^sourced') sourced"
openrosde-test-run bash -c "${OPENROSDE_TEST_CONTAINER_SHELL} source ./docker/openrosde-base/scripts/build-catkin-workspaces.bash > /dev/null; source ./docker/openrosde-base/scripts/source-catkin-workspaces.bash"
openrosde-test-check "sources the install space of every colcon workspace in order" \
  "$(printf '%s\n' "sourced ./ros2/openrosde_colcon_ws/install/setup.bash" "sourced ./${OPENROSDE_TEST_FOO_DIR}/ros2/foo_colcon_ws/install/setup.bash" "sourced ./ros2/user_colcon_ws/install/setup.bash")" \
  "$(echo "${OPENROSDE_TEST_OUTPUT}" | grep '^sourced' | sed "s#${OPENROSDE_TEST_ROOT_DIR}#.#g")"
rm -rf "${OPENROSDE_TEST_ROOT_DIR}"/ros2/*/install "${OPENROSDE_TEST_ROOT_DIR}/${OPENROSDE_TEST_FOO_DIR}"/ros2/*/install
openrosde-test-run bash -c "${OPENROSDE_TEST_CONTAINER_SHELL} timeout 3 bash ./docker/openrosde-base/scripts/run-roslaunch-repeatedly.bash openrosde_foo_launch:foo_bringup_default_gazebo.launch.xml gui:=false <<< l"
openrosde-test-check "runs a launch file with 'ros2 launch' on ROS 2" \
  "ros2 launch openrosde_foo_launch foo_bringup_default_gazebo.launch.xml gui:=false" \
  "$(openrosde-test-print-calls | grep -E '^(ros2|roslaunch) ' | sort -u)"
openrosde-test-run bash -c "${OPENROSDE_TEST_CONTAINER_SHELL} bash ./docker/openrosde-base/scripts/kill-ros-nodes.bash"
openrosde-test-check "stops every launch, node, and simulation of ROS 2, and the daemon, with no command of ROS 1" \
  "$(printf '%s\n' "pkill -INT -f ros2 launch" "pkill -f -- --ros-args" "pkill -f gz sim" "ros2 daemon stop")" \
  "$(openrosde-test-print-calls | grep -E '^(pkill|ros2|rosnode|killall) ')"

# Check the network settings of the container shell on ROS 2, local by default, then remote with the robot as a static peer.
OPENROSDE_TEST_SHELL_REPORT=""
for OPENROSDE_TEST_MASTER_HOSTNAME in localhost foo-robot.local; do
  echo "OPENROSDE_ROS_MASTER_HOSTNAME=${OPENROSDE_TEST_MASTER_HOSTNAME}" >> "${OPENROSDE_TEST_ROOT_DIR}/.env.custom"
  openrosde-test-run bash -c 'export OPENROSDE_CONTAINER_ROOT_DIR="${PWD}" OPENROSDE_DOCKER_IMAGE_VERSION=def5678; source ./docker/openrosde-base/scripts/initialize-bash-shell.bash > /dev/null 2>&1; echo "${ROS_DOMAIN_ID} ${ROS_AUTOMATIC_DISCOVERY_RANGE} ${ROS_STATIC_PEERS} ${ROS_MASTER_URI} ${ROS_PACKAGE_PATH} ${OPENROSDE_LAUNCH_PACKAGE}"'
  OPENROSDE_TEST_SHELL_REPORT="${OPENROSDE_TEST_SHELL_REPORT}${OPENROSDE_TEST_MASTER_HOSTNAME}: ${OPENROSDE_TEST_OUTPUT}"$'\n'
done
openrosde-test-check "sets the domain and the discovery of ROS 2, no master and no package path of ROS 1, and the launch package that the platform names" \
  "$(printf '%s\n' "localhost: 0 LOCALHOST    openrosde_foo_launch" "foo-robot.local: 0 SUBNET foo-robot.local   openrosde_foo_launch")" \
  "${OPENROSDE_TEST_SHELL_REPORT%$'\n'}"
openrosde-test-run bash -c 'export OPENROSDE_CONTAINER_ROOT_DIR="${PWD}" OPENROSDE_DOCKER_IMAGE_VERSION=def5678; source ./docker/openrosde-base/scripts/initialize-bash-shell.bash 2>&1 | grep "^Sourcing the ROS distribution"'
openrosde-test-check "sources the distribution of ROS 2 that the platform declares" \
  "Sourcing the ROS distribution from '/opt/ros/lyrical/setup.bash'." \
  "${OPENROSDE_TEST_OUTPUT}"
openrosde-test-select-template "${OPENROSDE_TEST_FOO_DIR}/env/foo.env"
openrosde-test-run bash -c 'export OPENROSDE_CONTAINER_ROOT_DIR="${PWD}" OPENROSDE_DOCKER_IMAGE_VERSION=def5678; source ./docker/openrosde-base/scripts/initialize-bash-shell.bash > /dev/null 2>&1; echo "${ROS_MASTER_URI} ${ROS_AUTOMATIC_DISCOVERY_RANGE}|${ROS_PACKAGE_PATH}"'
openrosde-test-check "keeps the master and the package path of ROS 1 for the platform on ROS 1" \
  "http://localhost:11311 |:${OPENROSDE_TEST_ROOT_DIR}/ros/openrosde_catkin_ws/src/:${OPENROSDE_TEST_ROOT_DIR}/${OPENROSDE_TEST_FOO_DIR}/ros/foo_catkin_ws/src/:${OPENROSDE_TEST_ROOT_DIR}/ros/user_catkin_ws/src/" \
  "${OPENROSDE_TEST_OUTPUT}"
openrosde-test-select-template "${OPENROSDE_TEST_FOO_DIR}/env/foo-ros2.env"

################################################################################

# Check the launch entry points of the platform on ROS 2, which 'ros2 launch --show-args' resolves without starting any node.
openrosde-test-run env OPENROSDE_CONTAINER_ROOT_DIR="${OPENROSDE_TEST_ROOT_DIR}" bash ./gitlab-ci/check-launch-files.bash foo-ros2
openrosde-test-check "resolves every entry point of the platform and of the core on ROS 2 with 'ros2 launch --show-args', in the launch package of the platform, and no 'roslaunch'" \
  "$(printf '%s\n' "status 0" "Checked 5 launch entry points of 'foo-ros2'." "Left out the node names of the 2 layouts of 'foo-ros2', which ROS 2 cannot list without starting the nodes." \
    "ros2 launch --show-args openrosde_foo_launch foo_bringup_default_gazebo.launch.xml" \
    "ros2 launch --show-args openrosde_foo_launch foo_rviz_default.launch.py use_sim_time:=false" \
    "ros2 launch --show-args openrosde_launch rosbridge_server_default.launch.xml" \
    "ros2 launch --show-args openrosde_launch rqt_suite_default.launch.xml" \
    "ros2 launch --show-args openrosde_user_launch user_example_default.launch.xml" \
    "0 roslaunch calls")" \
  "$(echo "status ${OPENROSDE_TEST_EXIT_CODE}"; echo "${OPENROSDE_TEST_OUTPUT}" | grep -E '^(Error|Checked|Left out)'; openrosde-test-print-calls | grep '^ros2 launch' | sort; echo "$(openrosde-test-print-calls | grep -c '^roslaunch') roslaunch calls")"
OPENROSDE_TEST_FAILING_CALL="foo_rviz_default" openrosde-test-run env OPENROSDE_CONTAINER_ROOT_DIR="${OPENROSDE_TEST_ROOT_DIR}" bash ./gitlab-ci/check-launch-files.bash foo-ros2
openrosde-test-check "fails when 'ros2 launch --show-args' cannot load an entry point" \
  "$(printf '%s\n' "status 1" "  - openrosde_foo_launch foo_rviz_default.launch.py use_sim_time:=false")" \
  "$(echo "status ${OPENROSDE_TEST_EXIT_CODE}"; echo "${OPENROSDE_TEST_OUTPUT}" | grep '^  - ')"

################################################################################

# Check the panes of the core alone on ROS 2, which hold no FlexBE App, since no release of it exists for ROS 2 Lyrical.
cp "${OPENROSDE_TEST_ROOT_DIR}/.env.custom" "${OPENROSDE_TEST_WORK_DIR}/env.custom.before"
openrosde-test-write-file .env.custom "OPENROSDE_ROBOT_PLATFORM=" "OPENROSDE_ROBOT_SETUP=" "OPENROSDE_ROBOT_EXTENSIONS="
grep -E '^OPENROSDE_ROS_(VERSION|DISTRO)=' "${OPENROSDE_TEST_ROOT_DIR}/env/openrosde-ros2.env" >> "${OPENROSDE_TEST_ROOT_DIR}/.env.custom"
openrosde-test-run env OPENROSDE_CONTAINER_ROOT_DIR="${OPENROSDE_TEST_ROOT_DIR}" bash ./gitlab-ci/check-launch-files.bash openrosde-ros2
openrosde-test-check "checks the panes of the core alone on ROS 2, with no platform" \
  "$(printf '%s\n' "status 0" "Checked 3 launch entry points of 'openrosde-ros2'." \
    "ros2 launch --show-args openrosde_launch rosbridge_server_default.launch.xml" \
    "ros2 launch --show-args openrosde_launch rqt_suite_default.launch.xml" \
    "ros2 launch --show-args openrosde_user_launch user_example_default.launch.xml")" \
  "$(echo "status ${OPENROSDE_TEST_EXIT_CODE}"; echo "${OPENROSDE_TEST_OUTPUT}" | grep -E '^(Error|Checked)'; openrosde-test-print-calls | grep '^ros2 launch' | sort)"
cp "${OPENROSDE_TEST_WORK_DIR}/env.custom.before" "${OPENROSDE_TEST_ROOT_DIR}/.env.custom"

################################################################################

# Check the commands of ROS 2 that could move a robot in a folder of scripts, with launch files of simulations of ROS 2 allowed.
openrosde-test-write-file ci-ros2/check-in-container.bash \
  "#!/bin/bash" \
  "# A comment may name ros2 run and ros2 launch freely." \
  "ros2 launch --show-args acme_bringup robot.launch.py" \
  "ros2 launch -s acme_bringup robot.launch.py" \
  "ros2 launch acme_bringup robot.launch.xml --print" \
  "ros2 launch acme_sim sim_world_gazebo.launch.xml gui:=false &" \
  "ros2 launch rosbridge_server rosbridge_websocket_launch.xml max_message_size:=1000000" \
  "ros2 launch acme_bringup robot.launch.py" \
  "/opt/ros/lyrical/bin/ros2 launch acme_bringup robot_launch.py" \
  "cd /tmp && ros2 run acme_tools move_arm" \
  "ros2 topic pub /cmd_vel geometry_msgs/msg/Twist '{}'" \
  "echo done; ros2 service call /reset std_srvs/srv/Empty" \
  "ros2 action send_goal /arm/follow_joint_trajectory control_msgs/action/FollowJointTrajectory '{}'" \
  "ros2 bag play moves.mcap" \
  "ros2 lifecycle set /driver activate" \
  "ros2 topic echo /joint_states" \
  "ros2 service list --no-daemon" \
  "roslaunch -p 11312 acme_bringup robot.launch" \
  "ros2 launch acme_bringup robot.launch.py # see --show-args"
openrosde-test-write-file ci-ros2/allowed-simulation-launches.txt "# Simulations of the tests." "sim_world_gazebo.launch.xml" "rosbridge_websocket_launch.xml"
openrosde-test-run bash ./gitlab-ci/check-no-motion.bash ci-ros2
openrosde-test-check "fails on every command of ROS 2 that could move a robot, and on a short option of 'roslaunch', and allows the options that start no node and the simulations of the allowlist" \
  "$(printf '%s\n' "status 1" "Checked 1 files for commands that could move a robot." \
    "  - ci-ros2/check-in-container.bash:8: 'ros2 launch' in: ros2 launch acme_bringup robot.launch.py" \
    "  - ci-ros2/check-in-container.bash:9: 'ros2 launch' in: /opt/ros/lyrical/bin/ros2 launch acme_bringup robot_launch.py" \
    "  - ci-ros2/check-in-container.bash:10: 'ros2 run' in: ros2 run acme_tools move_arm" \
    "  - ci-ros2/check-in-container.bash:11: 'ros2 topic pub' in: ros2 topic pub /cmd_vel geometry_msgs/msg/Twist '{}'" \
    "  - ci-ros2/check-in-container.bash:12: 'ros2 service call' in: ros2 service call /reset std_srvs/srv/Empty" \
    "  - ci-ros2/check-in-container.bash:13: 'ros2 action send_goal' in: ros2 action send_goal /arm/follow_joint_trajectory control_msgs/action/FollowJointTrajectory '{}'" \
    "  - ci-ros2/check-in-container.bash:14: 'ros2 bag play' in: ros2 bag play moves.mcap" \
    "  - ci-ros2/check-in-container.bash:15: 'ros2 lifecycle set' in: ros2 lifecycle set /driver activate" \
    "  - ci-ros2/check-in-container.bash:18: 'roslaunch' in: roslaunch -p 11312 acme_bringup robot.launch" \
    "  - ci-ros2/check-in-container.bash:19: 'ros2 launch' in: ros2 launch acme_bringup robot.launch.py # see --show-args")" \
  "$(echo "status ${OPENROSDE_TEST_EXIT_CODE}"; echo "${OPENROSDE_TEST_OUTPUT}" | grep -E "^(Checked|  - )")"

################################################################################

# Check the child pipeline: the image of a platform on ROS 2 builds on the base image of ROS 2, and the core alone is tested on both.
OPENROSDE_CI_RUNNER_TAG="privileged-docker" openrosde-test-run bash ./gitlab-ci/generate-ci-pipeline.bash
openrosde-test-check "builds the image of the platform on ROS 2 on the base image of ROS 2, with its sources and its job, and the image of the platform on ROS 1 with the defaults" \
  "$(printf '%s\n' "status 0" \
    "build-foo-image-job:" "  extends: .build-platform-image" "  variables:" "    OPENROSDE_ROBOT_PLATFORM: foo" "    OPENROSDE_CI_PLATFORM_ROOT_DIR: ${OPENROSDE_TEST_FOO_DIR}" \
    "build-foo-ros2-image-job:" "  extends: .build-platform-image" "  needs:" "    - build-base-ros2-image-job" "  variables:" "    OPENROSDE_ROBOT_PLATFORM: foo-ros2" "    OPENROSDE_CI_PLATFORM_ROOT_DIR: ${OPENROSDE_TEST_FOO_DIR}" \
    "    OPENROSDE_CI_BASE_IMAGE_NAME: openrosde-base-ros2" "    OPENROSDE_CI_BASE_SOURCE_DIRS: docker/openrosde-base-ros2,docker/openrosde-base/scripts")" \
  "$(echo "status ${OPENROSDE_TEST_EXIT_CODE}"; echo "${OPENROSDE_TEST_OUTPUT}" | awk '/^build-foo(-ros2)?-image-job:$/ { show = 1; print; next } /^[^ ]/ { show = 0 } show && NF')"
openrosde-test-check "tests the core alone on ROS 2 twice, once through a 'rosbridge' that fragments, and publishes the base image of ROS 2 after both" \
  "$(printf '%s\n' \
    "test-core-ros2-workspaces-job: build-base-ros2-image-job build-mesh2glb-image-job check-scripts-job OPENROSDE_CI_ROBOT_SETUP: openrosde-ros2" \
    "robot-model-fragments-job: build-base-ros2-image-job build-mesh2glb-image-job check-scripts-job OPENROSDE_CI_ROBOT_SETUP: openrosde-ros2 OPENROSDE_CI_ROBOT_MODEL_ARGS: --fragments" \
    "publish-images-job: build-base-ros2-image-job test-core-ros2-workspaces-job robot-model-fragments-job")" \
  "$(for OPENROSDE_TEST_JOB_NAME in test-core-ros2-workspaces-job robot-model-fragments-job publish-images-job; do
      echo "${OPENROSDE_TEST_OUTPUT}" | awk -v job="${OPENROSDE_TEST_JOB_NAME}" '
        $0 == job ":" { show = 1; line = job ":"; next }
        /^[^ ]/ { show = 0 }
        show && /^    - / && (job != "publish-images-job" || $2 ~ /^(build-base-ros2-image-job|test-core-ros2-workspaces-job|robot-model-fragments-job)$/) { line = line " " $2 }
        show && /^    OPENROSDE_CI_ROBOT_/ && job != "publish-images-job" { sub(/^ +/, ""); line = line " " $0 }
        END { print line }'
    done)"

################################################################################

# Check the test of the core alone on ROS 2 and of a setup on ROS 2, whose calls of Docker the stub logs.
export CI=true OPENROSDE_CI_IMAGE_REGISTRY="${OPENROSDE_TEST_REGISTRY}" OPENROSDE_CI_IMAGE_TAG=pipeline-7
unset JOB_CPUS
rm -f "${OPENROSDE_TEST_ROOT_DIR}/.env.custom"
OPENROSDE_CI_ROBOT_MODEL_ARGS=--fragments openrosde-test-run bash ./gitlab-ci/test-catkin-workspaces.bash openrosde-ros2
openrosde-test-check "tests the core alone on ROS 2 in the base image of ROS 2, gives the meshes of its distribution their GLBs before building, and passes the arguments of the robot model check" \
  "$(printf '%s\n' "status 0" "OPENROSDE_ROBOT_PLATFORM=" "OPENROSDE_ROBOT_SETUP=" "OPENROSDE_ROBOT_EXTENSIONS=" "OPENROSDE_ROS_VERSION=2" "OPENROSDE_ROS_DISTRO=lyrical" \
    "Testing the core alone on ROS 2, with no platform and no extension." \
    "${OPENROSDE_TEST_REGISTRY}/openrosde-base-ros2:pipeline-7 sleep infinity" \
    "glbs of lyrical" "reset" "check-robot-model.bash --fragments")" \
  "$(echo "status ${OPENROSDE_TEST_EXIT_CODE}"; grep '^OPENROSDE_RO' "${OPENROSDE_TEST_ROOT_DIR}/.env.custom"; echo "${OPENROSDE_TEST_OUTPUT}" | grep '^Testing'
    openrosde-test-print-calls | grep '^docker create ' | grep -o '[^ ]* sleep infinity$'
    openrosde-test-print-calls | sed -n -e "s#^docker exec openrosde-ci-openrosde-ros2 bash -c cd / && find 'opt/ros/\([a-z]*\)/share'.*#glbs of \1#p" -e 's#^docker exec openrosde-ci-openrosde-ros2 bash -c source .*reset-catkin-workspaces.bash$#reset#p' -e 's#^docker exec openrosde-ci-openrosde-ros2 bash /root/OpenRoSDE/gitlab-ci/\(check-robot-model.bash.*\)$#\1#p')"
rm -f "${OPENROSDE_TEST_ROOT_DIR}/.env.custom"
OPENROSDE_TEST_FAILING_CALL="reset-catkin-workspaces" openrosde-test-run bash ./gitlab-ci/test-catkin-workspaces.bash foo-ros2
openrosde-test-check "tests a setup on ROS 2 in the image of its platform, and keeps the logs of 'colcon build' of every workspace when it fails" \
  "$(printf '%s\n' "status 1" "${OPENROSDE_TEST_REGISTRY}/foo-ros2-devel:pipeline-7 sleep infinity" \
    "docker cp openrosde-ci-foo-ros2:/root/OpenRoSDE/ros2/openrosde_colcon_ws/log ci-logs/ros2/openrosde_colcon_ws/" \
    "docker cp openrosde-ci-foo-ros2:/root/OpenRoSDE/${OPENROSDE_TEST_FOO_DIR}/ros2/foo_colcon_ws/log ci-logs/${OPENROSDE_TEST_FOO_DIR}/ros2/foo_colcon_ws/" \
    "docker cp openrosde-ci-foo-ros2:/root/OpenRoSDE/ros2/user_colcon_ws/log ci-logs/ros2/user_colcon_ws/")" \
  "$(echo "status ${OPENROSDE_TEST_EXIT_CODE}"; openrosde-test-print-calls | grep '^docker create ' | grep -o '[^ ]* sleep infinity$'; openrosde-test-print-calls | grep '^docker cp openrosde-ci')"
rm -rf "${OPENROSDE_TEST_ROOT_DIR}/ci-logs"

################################################################################

# Remove the scratch copy and report the result.
openrosde-test-remove-copy
openrosde-test-finish-suite
