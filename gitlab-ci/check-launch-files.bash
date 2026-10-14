#!/bin/bash

# This script checks, inside the container of a platform, that every launch entry point of its 'tmux' sessions resolves, as part of the CI.
# The entry points are the panes of 'tmux/<platform>.panes' and 'tmux/openrosde.panes' in every layout, each with its own arguments.
# 'roslaunch --files' resolves a launch file, its includes, packages, arguments, and conditions without starting any node, so the check moves nothing.
#
# Usage: bash ./gitlab-ci/check-launch-files.bash <robot-platform>
#
# <robot-platform>: The platform whose entry points to check, such as 'ur5e', whose Catkin workspaces are already built.

################################################################################

# Load the environment that a shell of the container has: the platform template over '.env', the shell configuration of the platform, ROS, and the workspaces.
set -a
source ${OPENROSDE_CONTAINER_ROOT_DIR}/.env
source ${OPENROSDE_CONTAINER_ROOT_DIR}/env/$1.env
set +a
source ${OPENROSDE_CONTAINER_ROOT_DIR}/scripts/load-extension-paths.bash ${OPENROSDE_CONTAINER_ROOT_DIR}
OPENROSDE_SHELL_SCRIPT_PATH="$(openrosde-find-setup-file "scripts/%s/initialize-bash-shell.bash")"
if [ -n "${OPENROSDE_SHELL_SCRIPT_PATH}" ]; then
  source ${OPENROSDE_SHELL_SCRIPT_PATH}
fi
source /opt/ros/noetic/setup.bash
source ${OPENROSDE_CONTAINER_ROOT_DIR}/docker/openrosde-base/scripts/source-catkin-workspaces.bash > /dev/null

################################################################################

# Check every launch entry point once, whatever layouts list it, with the package of the platform when the pane names none.
OPENROSDE_FAILED_LAUNCH_FILES=""
OPENROSDE_CHECKED_LAUNCH_COUNT=0
while read -r OPENROSDE_PANE_FILE OPENROSDE_PANE_ARGS; do
  # Split the package from the launch file only in the first word, since the arguments hold ':=' too.
  if [[ "${OPENROSDE_PANE_FILE}" == *":"* ]]; then
    OPENROSDE_PANE_PACKAGE="${OPENROSDE_PANE_FILE%%:*}"
    OPENROSDE_PANE_FILE="${OPENROSDE_PANE_FILE#*:}"
  else
    OPENROSDE_PANE_PACKAGE="openrosde_$1_launch"
  fi
  OPENROSDE_PANE_LAUNCH="${OPENROSDE_PANE_FILE}${OPENROSDE_PANE_ARGS:+ ${OPENROSDE_PANE_ARGS}}"
  OPENROSDE_CHECKED_LAUNCH_COUNT=$((OPENROSDE_CHECKED_LAUNCH_COUNT + 1))
  if roslaunch --files ${OPENROSDE_PANE_PACKAGE} ${OPENROSDE_PANE_LAUNCH} > /dev/null; then
    echo "Resolved '${OPENROSDE_PANE_PACKAGE} ${OPENROSDE_PANE_LAUNCH}'."
  else
    echo "Failed to resolve '${OPENROSDE_PANE_PACKAGE} ${OPENROSDE_PANE_LAUNCH}'."
    OPENROSDE_FAILED_LAUNCH_FILES="${OPENROSDE_FAILED_LAUNCH_FILES}"$'\n'"  - ${OPENROSDE_PANE_PACKAGE} ${OPENROSDE_PANE_LAUNCH}"
  fi
done < <(cat ${OPENROSDE_CONTAINER_ROOT_DIR}/tmux/$1.panes ${OPENROSDE_CONTAINER_ROOT_DIR}/tmux/openrosde.panes \
  | grep -v -e '^#' -e '^ *$' \
  | awk '{ $1 = ""; $2 = ""; sub(/^ +/, ""); print }' \
  | grep -v -x -e 'shell' -e 'host' \
  | sort -u)

################################################################################

# Report the result, and fail if any entry point does not resolve.
echo "Checked ${OPENROSDE_CHECKED_LAUNCH_COUNT} launch entry points of '$1'."
if [ -n "${OPENROSDE_FAILED_LAUNCH_FILES}" ]; then
  echo "These launch entry points do not resolve:${OPENROSDE_FAILED_LAUNCH_FILES}"
  exit 1
fi
