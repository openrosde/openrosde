#!/bin/bash

# This script runs multiple terminals in a 'tmux' session, with one window per group of panes that the platform, the active extensions, the setup, and the core declare.
# Each part declares its panes in 'tmux/<name>.panes', one per line: '<layouts> <window> <launch-file> [<arg:=value> ...]'.
# '<layouts>' is '*' or a comma-separated list of layouts, the word 'shell' opens a shell inside the Docker container, and the word 'host' opens a shell on the Ubuntu development machine.
# Every other pane runs 'RUN-DOCKER-CONTAINER.bash' with its launch file, which waits for a key before it launches anything.
# If the session already runs, the script attaches to it instead of starting a second one.
#
# Usage: bash ./RUN-TMUX-SESSION.bash [docker-project] [session-layout]
#
# [docker-project]: Used to name the Docker container and the 'tmux' session, and create multiple instances if needed.
#                   Default value is '$USER'.
# [session-layout]: Used to select the panes of a layout, such as 'default-gazebo' or 'default-realworld'.
#                   Default value is 'default-gazebo'.

################################################################################

# Load the OpenRoSDE environment variables.
source ./scripts/load-openrosde-env.bash "$1"

################################################################################

# Name the 'tmux' session after the Docker container, so that one session runs per container.
OPENROSDE_TMUX_SESSION_NAME="openrosde-${OPENROSDE_ROBOT_PLATFORM}-${OPENROSDE_DOCKER_PROJECT}"

# Attach to the session if it already runs, or switch to it from inside another 'tmux' session.
function openrosde-attach-tmux-session () {
  if [ -n "${TMUX}" ]; then
    tmux switch-client -t "=${OPENROSDE_TMUX_SESSION_NAME}"
  else
    tmux attach-session -t "=${OPENROSDE_TMUX_SESSION_NAME}"
  fi
}
if tmux has-session -t "=${OPENROSDE_TMUX_SESSION_NAME}" 2>/dev/null; then
  echo "Attaching to the running 'tmux' session '${OPENROSDE_TMUX_SESSION_NAME}' (close it with 'tmux kill-session -t ${OPENROSDE_TMUX_SESSION_NAME}' to start it again)."
  openrosde-attach-tmux-session
  exit 0
fi

################################################################################

# Resolve the session layout (defaults to 'default-gazebo').
OPENROSDE_TMUX_SESSION_LAYOUT=$2
if [ -z "${OPENROSDE_TMUX_SESSION_LAYOUT}" ]; then
  OPENROSDE_TMUX_SESSION_LAYOUT="default-gazebo"
fi

################################################################################

# Pre-start the Docker container before creating the session.
# This avoids race conditions when multiple panes run 'RUN-DOCKER-CONTAINER.bash' simultaneously.
bash ./RUN-DOCKER-CONTAINER.bash "${OPENROSDE_DOCKER_PROJECT}" --no-exec > /dev/null 2>&1 &
wait $!

################################################################################

# List the pane files in the order their windows appear: the platform, the active extensions and the setup in their order, then the core.
OPENROSDE_TMUX_PANES_FILES=()
OPENROSDE_PLATFORM_PANES_FILE="$(openrosde-find-extension-file "tmux/${OPENROSDE_ROBOT_PLATFORM}.panes")"
if [ -n "${OPENROSDE_PLATFORM_PANES_FILE}" ]; then
  OPENROSDE_TMUX_PANES_FILES+=("${OPENROSDE_PLATFORM_PANES_FILE}")
fi
for OPENROSDE_EXTENSION_ROOT_DIR in "${OPENROSDE_ACTIVE_ROOT_DIRS[@]:1}"; do
  for OPENROSDE_EXTENSION_PANES_FILE in "${OPENROSDE_EXTENSION_ROOT_DIR}"/tmux/*.panes; do
    if [ -f "${OPENROSDE_EXTENSION_PANES_FILE}" ] && [ "${OPENROSDE_EXTENSION_PANES_FILE}" != "${OPENROSDE_PLATFORM_PANES_FILE}" ]; then
      OPENROSDE_TMUX_PANES_FILES+=("${OPENROSDE_EXTENSION_PANES_FILE}")
    fi
  done
done
OPENROSDE_TMUX_PANES_FILES+=("${OPENROSDE_ROOT_DIR}/tmux/openrosde.panes")

################################################################################

# Create the session with the panes of the selected layout: a window on the first pane of each window name, then a split for every further pane.
for OPENROSDE_TMUX_PANES_FILE in "${OPENROSDE_TMUX_PANES_FILES[@]}"; do
  while read -r OPENROSDE_PANE_LAYOUTS OPENROSDE_PANE_WINDOW OPENROSDE_PANE_LAUNCH; do
    # Skip blank lines, comments, and the panes of other layouts.
    if [ -z "${OPENROSDE_PANE_LAYOUTS}" ] || [ "${OPENROSDE_PANE_LAYOUTS:0:1}" = "#" ]; then
      continue
    fi
    if [ "${OPENROSDE_PANE_LAYOUTS}" != "*" ] && [[ ",${OPENROSDE_PANE_LAYOUTS}," != *",${OPENROSDE_TMUX_SESSION_LAYOUT},"* ]]; then
      continue
    fi

    # Derive the command of the pane: the shell of the host, a shell in the container, or a launch file in the container.
    case "${OPENROSDE_PANE_LAUNCH}" in
      host)
        OPENROSDE_PANE_COMMAND=""
        ;;
      shell)
        OPENROSDE_PANE_COMMAND="bash ./RUN-DOCKER-CONTAINER.bash ${OPENROSDE_DOCKER_PROJECT}"
        ;;
      *)
        OPENROSDE_PANE_COMMAND="bash ./RUN-DOCKER-CONTAINER.bash ${OPENROSDE_DOCKER_PROJECT} ${OPENROSDE_PANE_LAUNCH}"
        ;;
    esac

    # Open the pane in a new session, a new window, or a split of its window.
    if ! tmux has-session -t "=${OPENROSDE_TMUX_SESSION_NAME}" 2>/dev/null; then
      # The session starts large enough for the splits, and fits the terminal once attached.
      tmux new-session -d -s "${OPENROSDE_TMUX_SESSION_NAME}" -n "${OPENROSDE_PANE_WINDOW}" -c "${OPENROSDE_ROOT_DIR}" -x 240 -y 64 ${OPENROSDE_PANE_COMMAND:+"${OPENROSDE_PANE_COMMAND}"}
    elif tmux list-windows -t "=${OPENROSDE_TMUX_SESSION_NAME}" -F '#{window_name}' | grep -qxF "${OPENROSDE_PANE_WINDOW}"; then
      tmux split-window -t "=${OPENROSDE_TMUX_SESSION_NAME}:${OPENROSDE_PANE_WINDOW}" -c "${OPENROSDE_ROOT_DIR}" ${OPENROSDE_PANE_COMMAND:+"${OPENROSDE_PANE_COMMAND}"}
      tmux select-layout -t "=${OPENROSDE_TMUX_SESSION_NAME}:${OPENROSDE_PANE_WINDOW}" tiled > /dev/null
    else
      tmux new-window -t "=${OPENROSDE_TMUX_SESSION_NAME}:" -n "${OPENROSDE_PANE_WINDOW}" -c "${OPENROSDE_ROOT_DIR}" ${OPENROSDE_PANE_COMMAND:+"${OPENROSDE_PANE_COMMAND}"}
    fi
  done < "${OPENROSDE_TMUX_PANES_FILE}"
done

################################################################################

# Turn the mouse on, so that a click selects a pane or a window and the wheel scrolls.
tmux set-option -t "=${OPENROSDE_TMUX_SESSION_NAME}:" mouse on > /dev/null

# Title the terminal 'OpenRoSDE (<session>)', which 'maximize-app-window.bash' matches to give the focus back after a GUI opens.
tmux set-option -t "=${OPENROSDE_TMUX_SESSION_NAME}:" set-titles on > /dev/null
tmux set-option -t "=${OPENROSDE_TMUX_SESSION_NAME}:" set-titles-string "OpenRoSDE (#{session_name})" > /dev/null

# Show the first window and attach to the session.
tmux select-window -t "=${OPENROSDE_TMUX_SESSION_NAME}:^"
openrosde-attach-tmux-session
