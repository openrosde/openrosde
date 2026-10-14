#!/bin/bash

# This script checks, inside the container of a setup, every launch entry point of its 'tmux' sessions, as part of the CI.
# The entry points are the panes of the pane files that 'RUN-TMUX-SESSION.bash' opens for the setup, as 'scripts/load-extension-paths.bash' lists them in 'OPENROSDE_TMUX_PANES_FILES': the panes of the setup or else of its platform, of the active extensions, and of the core, in every layout, each with its own arguments.
# 'roslaunch --files' resolves a launch file, its includes, packages, arguments, and conditions, and 'roslaunch --nodes' lists the nodes it would start, both without starting any node, so the check moves nothing.
# A pane that names no package runs the launch package of the platform, 'OPENROSDE_LAUNCH_PACKAGE', which the shell configuration of the setup or of its platform may change, as in a shell of the container.
# The check fails when neither the setup nor its platform has a pane file, since its sessions would then open the panes of the core alone.
# It also fails when two panes of one layout start a node of the same name, since the second one would shut the first one down, unless an allowlist names that node for that layout.
# The allowlists are 'gitlab-ci/allowed-duplicate-nodes.txt' of the core and 'ci/allowed-duplicate-nodes.txt' of every active extension, with one '<layout> <node-name> [<launch-file> ...]' per line, where '<layout>' is '*' for every layout.
# A line that names launch files, as written in the panes, allows the node only when every pane that starts it runs one of them, such as two panes that a session runs one at a time.
#
# Usage: bash ./gitlab-ci/check-launch-files.bash <robot-setup>
#
# <robot-setup>: The setup whose entry points to check, selected in '.env.custom', such as 'ur5e', whose Catkin workspaces are already built, or 'openrosde' for the panes of the core alone, with no platform.

################################################################################

# Load the environment that a shell of the container has: the settings of the setup, the launch package of the platform, the shell configuration of the setup or of its platform, ROS, and the workspaces.
source ${OPENROSDE_CONTAINER_ROOT_DIR}/scripts/load-openrosde-settings.bash ${OPENROSDE_CONTAINER_ROOT_DIR}
OPENROSDE_LAUNCH_PACKAGE=openrosde_${OPENROSDE_ROBOT_PLATFORM}_launch
OPENROSDE_SHELL_SCRIPT_PATH="$(openrosde-find-setup-file "scripts/%s/initialize-bash-shell.bash")"
if [ -n "${OPENROSDE_SHELL_SCRIPT_PATH}" ]; then
  source ${OPENROSDE_SHELL_SCRIPT_PATH}
fi
source /opt/ros/noetic/setup.bash
source ${OPENROSDE_CONTAINER_ROOT_DIR}/docker/openrosde-base/scripts/source-catkin-workspaces.bash > /dev/null

################################################################################

# Stop when the settings select another setup than the one to check, or when neither the setup nor its platform has a pane file.
if [ "$1" = "openrosde" ]; then
  if [ -n "${OPENROSDE_ROBOT_PLATFORM}" ]; then
    echo "Error: The panes of the core alone are checked with no platform, but '.env.custom' selects the platform '${OPENROSDE_ROBOT_PLATFORM}'."
    exit 1
  fi
else
  if [ "${OPENROSDE_ROBOT_SETUP}" != "$1" ]; then
    echo "Error: The settings select the setup '${OPENROSDE_ROBOT_SETUP}', not '$1', so check '$1' after selecting it."
    exit 1
  fi
  if [ -z "$(openrosde-find-setup-file "tmux/%s.panes")" ]; then
    echo "Error: Neither the setup '${OPENROSDE_ROBOT_SETUP}' nor its platform '${OPENROSDE_ROBOT_PLATFORM}' has a pane file 'tmux/<name>.panes', so its sessions would open the panes of the core alone."
    exit 1
  fi
fi

# Read the panes of every pane file, as '<layouts> <launch-file> [<arg:=value> ...]', leaving out the comments, the blank lines, and the shells.
OPENROSDE_PANE_RECORDS=""
for OPENROSDE_PANES_FILE in "${OPENROSDE_TMUX_PANES_FILES[@]}"; do
  if [ ! -r "${OPENROSDE_PANES_FILE}" ]; then
    echo "Error: The pane file '${OPENROSDE_PANES_FILE}' cannot be read."
    exit 1
  fi
  OPENROSDE_PANE_RECORDS="${OPENROSDE_PANE_RECORDS}$(grep -v -e '^#' -e '^ *$' "${OPENROSDE_PANES_FILE}" \
    | awk '{ $2 = ""; print }' \
    | awk '$2 != "shell" && $2 != "host"')"$'\n'
done

################################################################################

# Check every launch entry point once, whatever layouts list it, with the launch package of the platform when the pane names none, and list the nodes it starts.
declare -A OPENROSDE_LAUNCH_NODE_NAMES
OPENROSDE_FAILED_LAUNCH_FILES=""
OPENROSDE_CHECKED_LAUNCH_COUNT=0
while read -r OPENROSDE_PANE_FILE OPENROSDE_PANE_ARGS; do
  OPENROSDE_PANE_ENTRY="${OPENROSDE_PANE_FILE}${OPENROSDE_PANE_ARGS:+ ${OPENROSDE_PANE_ARGS}}"
  # Split the package from the launch file only in the first word, since the arguments hold ':=' too.
  if [[ "${OPENROSDE_PANE_FILE}" == *":"* ]]; then
    OPENROSDE_PANE_PACKAGE="${OPENROSDE_PANE_FILE%%:*}"
    OPENROSDE_PANE_FILE="${OPENROSDE_PANE_FILE#*:}"
  else
    OPENROSDE_PANE_PACKAGE="${OPENROSDE_LAUNCH_PACKAGE}"
  fi
  OPENROSDE_PANE_LAUNCH="${OPENROSDE_PANE_FILE}${OPENROSDE_PANE_ARGS:+ ${OPENROSDE_PANE_ARGS}}"
  OPENROSDE_CHECKED_LAUNCH_COUNT=$((OPENROSDE_CHECKED_LAUNCH_COUNT + 1))
  if ! roslaunch --files ${OPENROSDE_PANE_PACKAGE} ${OPENROSDE_PANE_LAUNCH} < /dev/null > /dev/null; then
    echo "Failed to resolve '${OPENROSDE_PANE_PACKAGE} ${OPENROSDE_PANE_LAUNCH}'."
    OPENROSDE_FAILED_LAUNCH_FILES="${OPENROSDE_FAILED_LAUNCH_FILES}"$'\n'"  - ${OPENROSDE_PANE_PACKAGE} ${OPENROSDE_PANE_LAUNCH}"
  elif ! OPENROSDE_PANE_NODE_NAMES="$(roslaunch --nodes ${OPENROSDE_PANE_PACKAGE} ${OPENROSDE_PANE_LAUNCH} < /dev/null)" \
    || ! OPENROSDE_PANE_NODE_NAMES_AGAIN="$(roslaunch --nodes ${OPENROSDE_PANE_PACKAGE} ${OPENROSDE_PANE_LAUNCH} < /dev/null)"; then
    echo "Failed to list the nodes of '${OPENROSDE_PANE_PACKAGE} ${OPENROSDE_PANE_LAUNCH}', such as two nodes of one name."
    OPENROSDE_FAILED_LAUNCH_FILES="${OPENROSDE_FAILED_LAUNCH_FILES}"$'\n'"  - ${OPENROSDE_PANE_PACKAGE} ${OPENROSDE_PANE_LAUNCH}"
  else
    # Keep the names of the nodes, which start with '/', that both runs list, which leaves out the anonymous ones, '$(anon <name>)', whose names differ in every run and never clash.
    OPENROSDE_LAUNCH_NODE_NAMES["${OPENROSDE_PANE_ENTRY}"]="$(comm -1 -2 <(echo "${OPENROSDE_PANE_NODE_NAMES}" | grep '^/' | sort) <(echo "${OPENROSDE_PANE_NODE_NAMES_AGAIN}" | grep '^/' | sort))"
    echo "Resolved '${OPENROSDE_PANE_PACKAGE} ${OPENROSDE_PANE_LAUNCH}', which starts $(echo "${OPENROSDE_LAUNCH_NODE_NAMES["${OPENROSDE_PANE_ENTRY}"]}" | grep -c '^/') named nodes."
  fi
done < <(echo "${OPENROSDE_PANE_RECORDS}" \
  | awk 'NF > 1 { $1 = ""; sub(/^ +/, ""); print }' \
  | sort -u)

################################################################################

# Read the allowlists of the nodes that two panes of one layout may both start, from the core and from every active extension.
OPENROSDE_ALLOWED_DUPLICATE_NODES=""
for OPENROSDE_ALLOWLIST_FILE in ${OPENROSDE_CONTAINER_ROOT_DIR}/gitlab-ci/allowed-duplicate-nodes.txt "${OPENROSDE_ACTIVE_ROOT_DIRS[@]/%//ci/allowed-duplicate-nodes.txt}"; do
  if [ -f "${OPENROSDE_ALLOWLIST_FILE}" ]; then
    OPENROSDE_ALLOWED_DUPLICATE_NODES="${OPENROSDE_ALLOWED_DUPLICATE_NODES}$(grep -v -e '^#' -e '^ *$' "${OPENROSDE_ALLOWLIST_FILE}" | awk '{ $1 = $1; print }')"$'\n'
  fi
done

# List the layouts that the panes name, or '*' alone when every pane runs in every layout.
OPENROSDE_LAYOUT_NAMES="$(echo "${OPENROSDE_PANE_RECORDS}" | awk 'NF > 1 { print $1 }' | tr ',' '\n' | grep -v -x -e '\*' -e '' | sort -u)"
if [ -z "${OPENROSDE_LAYOUT_NAMES}" ]; then
  OPENROSDE_LAYOUT_NAMES="*"
fi

# Tell whether the allowlists allow a node, given as argument, in several panes of a layout, given as argument, which start it with the launch files given as further arguments.
function openrosde-allow-duplicate-node () {
  local OPENROSDE_ALLOWED_LAYOUT OPENROSDE_ALLOWED_NODE OPENROSDE_ALLOWED_LAUNCH_FILES OPENROSDE_STARTING_LAUNCH_FILE OPENROSDE_ALL_LAUNCH_FILES_ALLOWED
  while read -r OPENROSDE_ALLOWED_LAYOUT OPENROSDE_ALLOWED_NODE OPENROSDE_ALLOWED_LAUNCH_FILES; do
    if [ "${OPENROSDE_ALLOWED_NODE}" != "$2" ] || { [ "${OPENROSDE_ALLOWED_LAYOUT}" != "*" ] && [ "${OPENROSDE_ALLOWED_LAYOUT}" != "$1" ]; }; then
      continue
    fi
    OPENROSDE_ALL_LAUNCH_FILES_ALLOWED=true
    if [ -n "${OPENROSDE_ALLOWED_LAUNCH_FILES}" ]; then
      for OPENROSDE_STARTING_LAUNCH_FILE in "${@:3}"; do
        if [[ " ${OPENROSDE_ALLOWED_LAUNCH_FILES} " != *" ${OPENROSDE_STARTING_LAUNCH_FILE} "* ]]; then
          OPENROSDE_ALL_LAUNCH_FILES_ALLOWED=false
        fi
      done
    fi
    if [ "${OPENROSDE_ALL_LAUNCH_FILES_ALLOWED}" = "true" ]; then
      return 0
    fi
  done <<< "${OPENROSDE_ALLOWED_DUPLICATE_NODES}"
  return 1
}

# Check, in every layout, that no two panes start a node of the same name, unless the allowlists name it for that layout and for those panes.
OPENROSDE_DUPLICATE_NODE_REPORT=""
OPENROSDE_CHECKED_LAYOUT_COUNT=0
while read -r OPENROSDE_LAYOUT_NAME; do
  OPENROSDE_CHECKED_LAYOUT_COUNT=$((OPENROSDE_CHECKED_LAYOUT_COUNT + 1))
  OPENROSDE_LAYOUT_NODE_RECORDS=""
  while read -r OPENROSDE_PANE_LAYOUTS OPENROSDE_PANE_ENTRY; do
    if [ -n "${OPENROSDE_PANE_ENTRY}" ] && { [ "${OPENROSDE_PANE_LAYOUTS}" = "*" ] || [[ ",${OPENROSDE_PANE_LAYOUTS}," == *",${OPENROSDE_LAYOUT_NAME},"* ]]; }; then
      for OPENROSDE_NODE_NAME in ${OPENROSDE_LAUNCH_NODE_NAMES["${OPENROSDE_PANE_ENTRY}"]}; do
        OPENROSDE_LAYOUT_NODE_RECORDS="${OPENROSDE_LAYOUT_NODE_RECORDS}${OPENROSDE_NODE_NAME} ${OPENROSDE_PANE_ENTRY}"$'\n'
      done
    fi
  done <<< "${OPENROSDE_PANE_RECORDS}"
  for OPENROSDE_NODE_NAME in $(printf '%s' "${OPENROSDE_LAYOUT_NODE_RECORDS}" | awk '{ print $1 }' | sort | uniq -d); do
    if openrosde-allow-duplicate-node "${OPENROSDE_LAYOUT_NAME}" "${OPENROSDE_NODE_NAME}" $(printf '%s' "${OPENROSDE_LAYOUT_NODE_RECORDS}" | awk -v name="${OPENROSDE_NODE_NAME}" '$1 == name { print $2 }'); then
      echo "Allowed the node '${OPENROSDE_NODE_NAME}' in several panes of the layout '${OPENROSDE_LAYOUT_NAME}'."
      continue
    fi
    OPENROSDE_DUPLICATE_NODE_REPORT="${OPENROSDE_DUPLICATE_NODE_REPORT}"$'\n'"  - '${OPENROSDE_NODE_NAME}' in the layout '${OPENROSDE_LAYOUT_NAME}', by:$(printf '%s' "${OPENROSDE_LAYOUT_NODE_RECORDS}" | awk -v name="${OPENROSDE_NODE_NAME}" '$1 == name { $1 = ""; printf "\n      -%s", $0 }')"
  done
done <<< "${OPENROSDE_LAYOUT_NAMES}"

################################################################################

# Report the result, and fail if any entry point does not resolve or if two panes of one layout start a node of the same name.
echo "Checked ${OPENROSDE_CHECKED_LAUNCH_COUNT} launch entry points of '$1'."
echo "Checked the node names of ${OPENROSDE_CHECKED_LAYOUT_COUNT} layouts of '$1'."
OPENROSDE_CHECK_EXIT_CODE=0
if [ -n "${OPENROSDE_FAILED_LAUNCH_FILES}" ]; then
  echo "These launch entry points do not resolve:${OPENROSDE_FAILED_LAUNCH_FILES}"
  OPENROSDE_CHECK_EXIT_CODE=1
fi
if [ -n "${OPENROSDE_DUPLICATE_NODE_REPORT}" ]; then
  echo "These nodes are started by several panes of one layout, so the second one would shut the first one down:${OPENROSDE_DUPLICATE_NODE_REPORT}"
  OPENROSDE_CHECK_EXIT_CODE=1
fi
exit ${OPENROSDE_CHECK_EXIT_CODE}
