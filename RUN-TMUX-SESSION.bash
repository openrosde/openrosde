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

# Load the SDE environment variables.
source ./scripts/load-sde-env.bash "$1"

################################################################################

# Name the 'tmux' session after the Docker container, so that one session runs per container.
SDE_TMUX_SESSION_NAME="sde-${SDE_ROBOT_PLATFORM}-${SDE_DOCKER_PROJECT}"

# Attach to the session if it already runs, or switch to it from inside another 'tmux' session.
function sde-attach-tmux-session () {
  if [ -n "${TMUX}" ]; then
    tmux switch-client -t "=${SDE_TMUX_SESSION_NAME}"
  else
    tmux attach-session -t "=${SDE_TMUX_SESSION_NAME}"
  fi
}
if tmux has-session -t "=${SDE_TMUX_SESSION_NAME}" 2>/dev/null; then
  echo "Attaching to the running 'tmux' session '${SDE_TMUX_SESSION_NAME}' (close it with 'tmux kill-session -t ${SDE_TMUX_SESSION_NAME}' to start it again)."
  sde-attach-tmux-session
  exit 0
fi

################################################################################

# Resolve the session layout (defaults to 'default-gazebo').
SDE_TMUX_SESSION_LAYOUT=$2
if [ -z "${SDE_TMUX_SESSION_LAYOUT}" ]; then
  SDE_TMUX_SESSION_LAYOUT="default-gazebo"
fi

################################################################################

# Pre-start the Docker container before creating the session.
# This avoids race conditions when multiple panes run 'RUN-DOCKER-CONTAINER.bash' simultaneously.
bash ./RUN-DOCKER-CONTAINER.bash "${SDE_DOCKER_PROJECT}" --no-exec > /dev/null 2>&1 &
wait $!

################################################################################

# List the pane files in the order their windows appear: the platform, the active extensions and the setup in their order, then the core.
SDE_TMUX_PANES_FILES=()
SDE_PLATFORM_PANES_FILE="$(sde-find-extension-file "tmux/${SDE_ROBOT_PLATFORM}.panes")"
if [ -n "${SDE_PLATFORM_PANES_FILE}" ]; then
  SDE_TMUX_PANES_FILES+=("${SDE_PLATFORM_PANES_FILE}")
fi
for SDE_EXTENSION_ROOT_DIR in "${SDE_ACTIVE_ROOT_DIRS[@]:1}"; do
  for SDE_EXTENSION_PANES_FILE in "${SDE_EXTENSION_ROOT_DIR}"/tmux/*.panes; do
    if [ -f "${SDE_EXTENSION_PANES_FILE}" ] && [ "${SDE_EXTENSION_PANES_FILE}" != "${SDE_PLATFORM_PANES_FILE}" ]; then
      SDE_TMUX_PANES_FILES+=("${SDE_EXTENSION_PANES_FILE}")
    fi
  done
done
SDE_TMUX_PANES_FILES+=("${SDE_ROOT_DIR}/tmux/sde.panes")

################################################################################

# Create the session with the panes of the selected layout: a window on the first pane of each window name, then a split for every further pane.
for SDE_TMUX_PANES_FILE in "${SDE_TMUX_PANES_FILES[@]}"; do
  while read -r SDE_PANE_LAYOUTS SDE_PANE_WINDOW SDE_PANE_LAUNCH; do
    # Skip blank lines, comments, and the panes of other layouts.
    if [ -z "${SDE_PANE_LAYOUTS}" ] || [ "${SDE_PANE_LAYOUTS:0:1}" = "#" ]; then
      continue
    fi
    if [ "${SDE_PANE_LAYOUTS}" != "*" ] && [[ ",${SDE_PANE_LAYOUTS}," != *",${SDE_TMUX_SESSION_LAYOUT},"* ]]; then
      continue
    fi

    # Derive the command of the pane: the shell of the host, a shell in the container, or a launch file in the container.
    case "${SDE_PANE_LAUNCH}" in
      host)
        SDE_PANE_COMMAND=""
        ;;
      shell)
        SDE_PANE_COMMAND="bash ./RUN-DOCKER-CONTAINER.bash ${SDE_DOCKER_PROJECT}"
        ;;
      *)
        SDE_PANE_COMMAND="bash ./RUN-DOCKER-CONTAINER.bash ${SDE_DOCKER_PROJECT} ${SDE_PANE_LAUNCH}"
        ;;
    esac

    # Open the pane in a new session, a new window, or a split of its window.
    if ! tmux has-session -t "=${SDE_TMUX_SESSION_NAME}" 2>/dev/null; then
      # The session starts large enough for the splits, and fits the terminal once attached.
      tmux new-session -d -s "${SDE_TMUX_SESSION_NAME}" -n "${SDE_PANE_WINDOW}" -c "${SDE_ROOT_DIR}" -x 240 -y 64 ${SDE_PANE_COMMAND:+"${SDE_PANE_COMMAND}"}
    elif tmux list-windows -t "=${SDE_TMUX_SESSION_NAME}" -F '#{window_name}' | grep -qxF "${SDE_PANE_WINDOW}"; then
      tmux split-window -t "=${SDE_TMUX_SESSION_NAME}:${SDE_PANE_WINDOW}" -c "${SDE_ROOT_DIR}" ${SDE_PANE_COMMAND:+"${SDE_PANE_COMMAND}"}
      tmux select-layout -t "=${SDE_TMUX_SESSION_NAME}:${SDE_PANE_WINDOW}" tiled > /dev/null
    else
      tmux new-window -t "=${SDE_TMUX_SESSION_NAME}:" -n "${SDE_PANE_WINDOW}" -c "${SDE_ROOT_DIR}" ${SDE_PANE_COMMAND:+"${SDE_PANE_COMMAND}"}
    fi
  done < "${SDE_TMUX_PANES_FILE}"
done

################################################################################

# Turn the mouse on, so that a click selects a pane or a window and the wheel scrolls.
tmux set-option -t "=${SDE_TMUX_SESSION_NAME}:" mouse on > /dev/null

# Title the terminal 'SDE (<session>)', which 'maximize-app-window.bash' matches to give the focus back after a GUI opens.
tmux set-option -t "=${SDE_TMUX_SESSION_NAME}:" set-titles on > /dev/null
tmux set-option -t "=${SDE_TMUX_SESSION_NAME}:" set-titles-string "SDE (#{session_name})" > /dev/null

# Show the first window and attach to the session.
tmux select-window -t "=${SDE_TMUX_SESSION_NAME}:^"
sde-attach-tmux-session
