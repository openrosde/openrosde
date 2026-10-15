#!/bin/bash

# This script checks the robot model that the file service serves through 'rosbridge', inside the test container of a setup, with no network, after 'gitlab-ci/generate-ci-mesh-glbs.bash' gave its meshes their GLBs.
# It starts 'rosbridge_server_default.launch' of the core on ROS 1, after a ROS master, or 'rosbridge_server_default.launch.xml' on ROS 2, which start 'rosbridge' and the file service and no robot node, runs 'gitlab-ci/check-robot-model.py', then stops the file service and checks that a client sees it gone.
# With '--fragments', on ROS 2 only, it starts 'rosbridge' with 'max_message_size:=1000000', as a stock 'rosbridge' may run, adds a package of GLBs of 3,000,000, 11,990,000, and 12,000,001 bytes beside the packages of the container, and checks that a client reassembles the 'fragment' messages of every large GLB into the same bytes.
# Everything it starts stops when it ends.
#
# Usage: bash ./gitlab-ci/check-robot-model.bash [--fragments]

################################################################################

# Load the settings and the workspaces, as a shell of the container does, and keep the nodes on this machine.
source "${OPENROSDE_CONTAINER_ROOT_DIR}/scripts/load-openrosde-settings.bash" "${OPENROSDE_CONTAINER_ROOT_DIR}"
source /opt/ros/${OPENROSDE_ROS_DISTRO}/setup.bash
source "${OPENROSDE_CONTAINER_ROOT_DIR}/docker/openrosde-base/scripts/source-catkin-workspaces.bash" > /dev/null
if [ "${OPENROSDE_ROS_VERSION}" = "2" ]; then
  export ROS_AUTOMATIC_DISCOVERY_RANGE=LOCALHOST ROS_DOMAIN_ID="${OPENROSDE_ROS_DOMAIN_ID}"
  unset ROS_STATIC_PEERS
else
  export ROS_MASTER_URI=http://localhost:11311 ROS_HOSTNAME=localhost
  unset ROS_IP
fi

# Read the mode of the check.
OPENROSDE_CI_MODEL_CHECK_ARGS=()
OPENROSDE_CI_LAUNCH_ARGS=()
if [ "$1" = "--fragments" ]; then
  if [ "${OPENROSDE_ROS_VERSION}" != "2" ]; then
    echo "Error: '--fragments' checks the 'rosbridge' of ROS 2, but the settings select ROS ${OPENROSDE_ROS_VERSION}."
    exit 1
  fi
  OPENROSDE_CI_MODEL_CHECK_ARGS=(--fragments)
  OPENROSDE_CI_LAUNCH_ARGS=(max_message_size:=1000000)

  # Add a package of large GLBs beside those of the container, in a prefix of its own that the index of 'ament' of the file service and of the check reads.
  OPENROSDE_CI_FRAGMENTS_PREFIX=/tmp/openrosde-ci-fragments
  mkdir -p "${OPENROSDE_CI_FRAGMENTS_PREFIX}/share/ament_index/resource_index/packages" "${OPENROSDE_CI_FRAGMENTS_PREFIX}/share/openrosde_ci_fragments/meshes"
  touch "${OPENROSDE_CI_FRAGMENTS_PREFIX}/share/ament_index/resource_index/packages/openrosde_ci_fragments"
  for OPENROSDE_CI_GLB_SIZE in 3000000 11990000 12000001; do
    head -c "${OPENROSDE_CI_GLB_SIZE}" /dev/urandom > "${OPENROSDE_CI_FRAGMENTS_PREFIX}/share/openrosde_ci_fragments/meshes/large-${OPENROSDE_CI_GLB_SIZE}.dae.glb"
  done
  export AMENT_PREFIX_PATH="${OPENROSDE_CI_FRAGMENTS_PREFIX}:${AMENT_PREFIX_PATH}"
fi

# Stop everything this script started when it ends, on ROS 2 the whole process group of 'ros2 launch', whose nodes may outlive it otherwise, interrupted first, then killed.
OPENROSDE_CI_LAUNCH_PID=""
function openrosde-ci-stop-started-processes () {
  if [ -n "${OPENROSDE_CI_LAUNCH_PID}" ]; then
    kill -INT -- "-${OPENROSDE_CI_LAUNCH_PID}" > /dev/null 2>&1
    for OPENROSDE_CI_WAIT_SECOND in $(seq 1 30); do kill -0 -- "-${OPENROSDE_CI_LAUNCH_PID}" > /dev/null 2>&1 || break; sleep 1; done
    kill -KILL -- "-${OPENROSDE_CI_LAUNCH_PID}" > /dev/null 2>&1
  fi
  kill $(jobs -p) > /dev/null 2>&1
  wait > /dev/null 2>&1
}
trap openrosde-ci-stop-started-processes EXIT

# Start 'rosbridge' with the file service, after a master on ROS 1, and wait for both.
if [ "${OPENROSDE_ROS_VERSION}" = "2" ]; then
  setsid ros2 launch openrosde_launch rosbridge_server_default.launch.xml "${OPENROSDE_CI_LAUNCH_ARGS[@]}" < /dev/null > /tmp/openrosde-ci-rosbridge.log 2>&1 &
  OPENROSDE_CI_LAUNCH_PID=$!
  for OPENROSDE_CI_WAIT_SECOND in $(seq 1 120); do
    (echo > /dev/tcp/127.0.0.1/9090) > /dev/null 2>&1 && ros2 service list --no-daemon 2> /dev/null | grep -q -x -F /file_server/get_file && break
    sleep 1
  done
else
  roscore > /tmp/openrosde-ci-roscore.log 2>&1 &
  for OPENROSDE_CI_WAIT_SECOND in $(seq 1 60); do rosparam list > /dev/null 2>&1 && break; sleep 1; done
  roslaunch openrosde_launch rosbridge_server_default.launch > /tmp/openrosde-ci-rosbridge.log 2>&1 &
  for OPENROSDE_CI_WAIT_SECOND in $(seq 1 120); do
    (echo > /dev/tcp/127.0.0.1/9090) > /dev/null 2>&1 && rosservice list 2> /dev/null | grep -q -x -F /file_server/get_file && break
    sleep 1
  done
fi

# Check the robot model, then stop the file service and check that a client sees it gone.
python3 "${OPENROSDE_CONTAINER_ROOT_DIR}/gitlab-ci/check-robot-model.py" "${OPENROSDE_CONTAINER_ROOT_DIR}/ros" "${OPENROSDE_CONTAINER_ROOT_DIR}/ros2" "${OPENROSDE_CONTAINER_ROOT_DIR}/extensions" "${OPENROSDE_CI_MODEL_CHECK_ARGS[@]}"
OPENROSDE_CI_EXIT_CODE=$?
if [ "${OPENROSDE_ROS_VERSION}" = "2" ]; then
  pkill -f "lib/file_server2/file_server2_node" > /dev/null 2>&1
  for OPENROSDE_CI_WAIT_SECOND in $(seq 1 30); do ros2 service list --no-daemon 2> /dev/null | grep -q -x -F /file_server/get_file || break; sleep 1; done
else
  rosnode kill /file_server > /dev/null 2>&1
  for OPENROSDE_CI_WAIT_SECOND in $(seq 1 30); do rosservice list 2> /dev/null | grep -q -x -F /file_server/get_file || break; sleep 1; done
fi
python3 "${OPENROSDE_CONTAINER_ROOT_DIR}/gitlab-ci/check-robot-model.py" --expect-no-service || OPENROSDE_CI_EXIT_CODE=1
if [ "${OPENROSDE_CI_EXIT_CODE}" -ne 0 ]; then
  echo "The log of 'rosbridge_server_default.launch' ends with:"
  tail -n 40 /tmp/openrosde-ci-rosbridge.log
fi
exit ${OPENROSDE_CI_EXIT_CODE}
