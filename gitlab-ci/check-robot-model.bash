#!/bin/bash

# This script checks the robot model that the file service serves through 'rosbridge', inside the test container of a setup, with no network, after 'gitlab-ci/generate-ci-mesh-glbs.bash' gave its meshes their GLBs.
# It starts a ROS master and 'rosbridge_server_default.launch' of the core, which starts 'rosbridge' and the file service and no robot node, runs 'gitlab-ci/check-robot-model.py', then stops the file service and checks that a client sees it gone.
# Everything it starts stops when it ends.
#
# Usage: bash ./gitlab-ci/check-robot-model.bash

################################################################################

# Load the settings and the workspaces, as a shell of the container does.
source "${OPENROSDE_CONTAINER_ROOT_DIR}/scripts/load-openrosde-settings.bash" "${OPENROSDE_CONTAINER_ROOT_DIR}"
source /opt/ros/noetic/setup.bash
source "${OPENROSDE_CONTAINER_ROOT_DIR}/docker/openrosde-base/scripts/source-catkin-workspaces.bash" > /dev/null
export ROS_MASTER_URI=http://localhost:11311 ROS_HOSTNAME=localhost
unset ROS_IP

# Stop everything this script started when it ends.
trap 'kill $(jobs -p) > /dev/null 2>&1; wait > /dev/null 2>&1' EXIT

# Start the master, then 'rosbridge' with the file service, and wait for both.
roscore > /tmp/openrosde-ci-roscore.log 2>&1 &
for OPENROSDE_CI_WAIT_SECOND in $(seq 1 60); do rosparam list > /dev/null 2>&1 && break; sleep 1; done
roslaunch openrosde_launch rosbridge_server_default.launch > /tmp/openrosde-ci-rosbridge.log 2>&1 &
for OPENROSDE_CI_WAIT_SECOND in $(seq 1 120); do
  (echo > /dev/tcp/127.0.0.1/9090) > /dev/null 2>&1 && rosservice list 2> /dev/null | grep -q -x -F /file_server/get_file && break
  sleep 1
done

# Check the robot model, then stop the file service and check that a client sees it gone.
python3 "${OPENROSDE_CONTAINER_ROOT_DIR}/gitlab-ci/check-robot-model.py" "${OPENROSDE_CONTAINER_ROOT_DIR}/ros" "${OPENROSDE_CONTAINER_ROOT_DIR}/extensions"
OPENROSDE_CI_EXIT_CODE=$?
rosnode kill /file_server > /dev/null 2>&1
for OPENROSDE_CI_WAIT_SECOND in $(seq 1 30); do rosservice list 2> /dev/null | grep -q -x -F /file_server/get_file || break; sleep 1; done
python3 "${OPENROSDE_CONTAINER_ROOT_DIR}/gitlab-ci/check-robot-model.py" --expect-no-service || OPENROSDE_CI_EXIT_CODE=1
if [ "${OPENROSDE_CI_EXIT_CODE}" -ne 0 ]; then
  echo "The log of 'rosbridge_server_default.launch' ends with:"
  tail -n 40 /tmp/openrosde-ci-rosbridge.log
fi
exit ${OPENROSDE_CI_EXIT_CODE}
