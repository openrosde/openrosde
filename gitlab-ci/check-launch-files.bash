#!/bin/bash

# This script checks, inside the container of a platform, that every launch entry point of its 'tmux' sessions resolves, as part of the CI.
# The entry points are the panes of 'tmux/<platform>.panes' and 'tmux/sde.panes' in every layout, each with its own arguments.
# 'roslaunch --files' resolves a launch file, its includes, packages, arguments, and conditions without starting any node, so the check moves nothing.
#
# Usage: bash ./gitlab-ci/check-launch-files.bash <robot-platform>
#
# <robot-platform>: The platform whose entry points to check, such as 'ur5e', whose Catkin workspaces are already built.

################################################################################

# Load the environment that a shell of the container has: the platform template over '.env', the shell configuration of the platform, ROS, and the workspaces.
set -a
source ${SDE_CONTAINER_ROOT_DIR}/.env
source ${SDE_CONTAINER_ROOT_DIR}/env/$1.env
set +a
source ${SDE_CONTAINER_ROOT_DIR}/scripts/load-extension-paths.bash ${SDE_CONTAINER_ROOT_DIR}
SDE_SHELL_SCRIPT_PATH="$(sde-find-setup-file "scripts/%s/initialize-bash-shell.bash")"
if [ -n "${SDE_SHELL_SCRIPT_PATH}" ]; then
  source ${SDE_SHELL_SCRIPT_PATH}
fi
source /opt/ros/noetic/setup.bash
source ${SDE_CONTAINER_ROOT_DIR}/docker/sde-base/scripts/source-catkin-workspaces.bash > /dev/null

################################################################################

# Check every launch entry point once, whatever layouts list it, with the package of the platform when the pane names none.
SDE_FAILED_LAUNCH_FILES=""
SDE_CHECKED_LAUNCH_COUNT=0
while read -r SDE_PANE_FILE SDE_PANE_ARGS; do
  # Split the package from the launch file only in the first word, since the arguments hold ':=' too.
  if [[ "${SDE_PANE_FILE}" == *":"* ]]; then
    SDE_PANE_PACKAGE="${SDE_PANE_FILE%%:*}"
    SDE_PANE_FILE="${SDE_PANE_FILE#*:}"
  else
    SDE_PANE_PACKAGE="sde_$1_launch"
  fi
  SDE_PANE_LAUNCH="${SDE_PANE_FILE}${SDE_PANE_ARGS:+ ${SDE_PANE_ARGS}}"
  SDE_CHECKED_LAUNCH_COUNT=$((SDE_CHECKED_LAUNCH_COUNT + 1))
  if roslaunch --files ${SDE_PANE_PACKAGE} ${SDE_PANE_LAUNCH} > /dev/null; then
    echo "Resolved '${SDE_PANE_PACKAGE} ${SDE_PANE_LAUNCH}'."
  else
    echo "Failed to resolve '${SDE_PANE_PACKAGE} ${SDE_PANE_LAUNCH}'."
    SDE_FAILED_LAUNCH_FILES="${SDE_FAILED_LAUNCH_FILES}"$'\n'"  - ${SDE_PANE_PACKAGE} ${SDE_PANE_LAUNCH}"
  fi
done < <(cat ${SDE_CONTAINER_ROOT_DIR}/tmux/$1.panes ${SDE_CONTAINER_ROOT_DIR}/tmux/sde.panes \
  | grep -v -e '^#' -e '^ *$' \
  | awk '{ $1 = ""; $2 = ""; sub(/^ +/, ""); print }' \
  | grep -v -x -e 'shell' -e 'host' \
  | sort -u)

################################################################################

# Report the result, and fail if any entry point does not resolve.
echo "Checked ${SDE_CHECKED_LAUNCH_COUNT} launch entry points of '$1'."
if [ -n "${SDE_FAILED_LAUNCH_FILES}" ]; then
  echo "These launch entry points do not resolve:${SDE_FAILED_LAUNCH_FILES}"
  exit 1
fi
