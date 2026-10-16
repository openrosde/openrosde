#!/bin/bash

# This script runs multiple terminals in a 'tmux' session, with one window per group of panes that the platform, the active extensions, the setup, and the core declare.
# Each part declares its panes in 'tmux/<name>.panes', one per line: '<layouts> <window> <launch-file> [<arg:=value> ...]'.
# The panes of a setup, 'tmux/<setup>.panes', replace those of its platform, 'tmux/<platform>.panes', as its Terminator layout does.
# '<layouts>' is '*' or a comma-separated list of layouts, the word 'shell' opens a shell inside the Docker container, and the word 'host' opens a shell on the Ubuntu development machine.
# Every other pane runs 'RUN-DOCKER-CONTAINER.bash' with its launch file, which waits for a key before it launches anything.
# The windows open as tabs numbered from 1 in the standard order that 'scripts/load-extension-paths.bash' names in 'OPENROSDE_TMUX_STANDARD_WINDOWS', whatever order the pane files declare them in, and a window outside them opens after them with a warning.
# The first pane that enters the container prints the splash of 'scripts/print-tmux-splash.bash' right before its prompt, and the status bar names the session and points to 'openrosde-help', with options of this session alone.
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

# Read the panes of the selected layout, each as its window and its command, from the pane files of 'scripts/load-extension-paths.bash': the setup or else the platform, the active extensions and the setup, then the core.
# A window outside the standard windows is reported once, with the pane file that declares it first, and opens after them.
OPENROSDE_STANDARD_WINDOW_LIST="$(printf "'%s', " ${OPENROSDE_TMUX_STANDARD_WINDOWS})"
OPENROSDE_STANDARD_WINDOW_LIST="${OPENROSDE_STANDARD_WINDOW_LIST%, }"
OPENROSDE_STANDARD_WINDOW_LIST="${OPENROSDE_STANDARD_WINDOW_LIST%, *}, and ${OPENROSDE_STANDARD_WINDOW_LIST##*, }"
OPENROSDE_PANE_WINDOW_NAMES=()
OPENROSDE_PANE_COMMANDS=()
OPENROSDE_OTHER_WINDOW_NAMES=()
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
    OPENROSDE_PANE_WINDOW_NAMES+=("${OPENROSDE_PANE_WINDOW}")
    OPENROSDE_PANE_COMMANDS+=("${OPENROSDE_PANE_COMMAND}")

    # Report a window outside the standard windows the first time a pane opens in it.
    if [[ " ${OPENROSDE_TMUX_STANDARD_WINDOWS} " != *" ${OPENROSDE_PANE_WINDOW} "* ]] && [[ " ${OPENROSDE_OTHER_WINDOW_NAMES[*]} " != *" ${OPENROSDE_PANE_WINDOW} "* ]]; then
      OPENROSDE_OTHER_WINDOW_NAMES+=("${OPENROSDE_PANE_WINDOW}")
      echo "Warning: The window '${OPENROSDE_PANE_WINDOW}' of '${OPENROSDE_TMUX_PANES_FILE#"${OPENROSDE_ROOT_DIR}"/}' is none of the standard windows ${OPENROSDE_STANDARD_WINDOW_LIST}, so it opens after them." >&2
    fi
  done < "${OPENROSDE_TMUX_PANES_FILE}"
done

# Order the windows: the standard windows that hold a pane of the layout, in the standard order, then the other windows in the order the pane files declare them.
OPENROSDE_SESSION_WINDOW_NAMES=()
for OPENROSDE_STANDARD_WINDOW in ${OPENROSDE_TMUX_STANDARD_WINDOWS}; do
  if [[ " ${OPENROSDE_PANE_WINDOW_NAMES[*]} " == *" ${OPENROSDE_STANDARD_WINDOW} "* ]]; then
    OPENROSDE_SESSION_WINDOW_NAMES+=("${OPENROSDE_STANDARD_WINDOW}")
  fi
done
OPENROSDE_SESSION_WINDOW_NAMES+=("${OPENROSDE_OTHER_WINDOW_NAMES[@]}")

################################################################################

# Create the session with the panes of the selected layout, window after window in that order: a window on the first pane of each window, then a split for every further pane, in the order of the pane files.
# The first pane that enters the container gets the name and the layout of the session in its environment, and 'NO_COLOR' when it is set here, which 'RUN-DOCKER-CONTAINER.bash' passes to the shell of the container, so that the shell prints the splash right before the prompt of the pane, after the output that it clears when it starts.
OPENROSDE_SPLASH_PANE_ENV="env OPENROSDE_TMUX_SESSION_NAME=${OPENROSDE_TMUX_SESSION_NAME} OPENROSDE_TMUX_SESSION_LAYOUT=${OPENROSDE_TMUX_SESSION_LAYOUT}"
if [ -n "${NO_COLOR}" ]; then
  OPENROSDE_SPLASH_PANE_ENV="${OPENROSDE_SPLASH_PANE_ENV} NO_COLOR=1"
fi
OPENROSDE_SPLASH_PANE_PENDING=true
for OPENROSDE_SESSION_WINDOW in "${OPENROSDE_SESSION_WINDOW_NAMES[@]}"; do
  for OPENROSDE_PANE_INDEX in "${!OPENROSDE_PANE_WINDOW_NAMES[@]}"; do
    if [ "${OPENROSDE_PANE_WINDOW_NAMES[${OPENROSDE_PANE_INDEX}]}" != "${OPENROSDE_SESSION_WINDOW}" ]; then
      continue
    fi
    OPENROSDE_PANE_WINDOW="${OPENROSDE_SESSION_WINDOW}"
    OPENROSDE_PANE_COMMAND="${OPENROSDE_PANE_COMMANDS[${OPENROSDE_PANE_INDEX}]}"
    if [ "${OPENROSDE_SPLASH_PANE_PENDING}" = "true" ] && [ -n "${OPENROSDE_PANE_COMMAND}" ]; then
      OPENROSDE_PANE_COMMAND="${OPENROSDE_SPLASH_PANE_ENV} ${OPENROSDE_PANE_COMMAND}"
      OPENROSDE_SPLASH_PANE_PENDING=false
    fi

    # Open the pane in a new session, a new window, or a split of its window.
    if ! tmux has-session -t "=${OPENROSDE_TMUX_SESSION_NAME}" 2>/dev/null; then
      # The session starts large enough for the splits, and fits the terminal once attached.
      tmux new-session -d -s "${OPENROSDE_TMUX_SESSION_NAME}" -n "${OPENROSDE_PANE_WINDOW}" -c "${OPENROSDE_ROOT_DIR}" -x 240 -y 64 ${OPENROSDE_PANE_COMMAND:+"${OPENROSDE_PANE_COMMAND}"}
      # Number the windows of this session from 1, so that the tabs read from 1, and renumber its first window, which opened before.
      tmux set-option -t "=${OPENROSDE_TMUX_SESSION_NAME}:" base-index 1 > /dev/null
      tmux move-window -r -t "=${OPENROSDE_TMUX_SESSION_NAME}:"
    elif tmux list-windows -t "=${OPENROSDE_TMUX_SESSION_NAME}" -F '#{window_name}' | grep -qxF "${OPENROSDE_PANE_WINDOW}"; then
      tmux split-window -t "=${OPENROSDE_TMUX_SESSION_NAME}:${OPENROSDE_PANE_WINDOW}" -c "${OPENROSDE_ROOT_DIR}" ${OPENROSDE_PANE_COMMAND:+"${OPENROSDE_PANE_COMMAND}"}
      tmux select-layout -t "=${OPENROSDE_TMUX_SESSION_NAME}:${OPENROSDE_PANE_WINDOW}" tiled > /dev/null
    else
      tmux new-window -t "=${OPENROSDE_TMUX_SESSION_NAME}:" -n "${OPENROSDE_PANE_WINDOW}" -c "${OPENROSDE_ROOT_DIR}" ${OPENROSDE_PANE_COMMAND:+"${OPENROSDE_PANE_COMMAND}"}
    fi
  done
done

################################################################################

# Turn the mouse on, so that a click selects a pane or a window and the wheel scrolls.
tmux set-option -t "=${OPENROSDE_TMUX_SESSION_NAME}:" mouse on > /dev/null

# Title the terminal 'OpenRoSDE (<session>)', which 'maximize-app-window.bash' matches to give the focus back after a GUI opens.
tmux set-option -t "=${OPENROSDE_TMUX_SESSION_NAME}:" set-titles on > /dev/null
tmux set-option -t "=${OPENROSDE_TMUX_SESSION_NAME}:" set-titles-string "OpenRoSDE (#{session_name})" > /dev/null

################################################################################

# Give the session its status bar, with the options of this session and of its windows alone, never a global option or a key binding, which would change the other sessions of the 'tmux' server.
# The left side names OpenRoSDE, the setup, which is the platform for its default setup, and the layout, the middle holds the tabs, named after the windows, and the right side points to 'openrosde-help'.
# The bar takes the purple accent of OpenRoSDE, which 'tmux' maps to the colors of each terminal, unless 'NO_COLOR' is set or the terminal has fewer than 8 colors, where it stays plain, with the current tab in reverse video.
# https://no-color.org/
OPENROSDE_STATUS_ROBOT_TEXT="${OPENROSDE_ROBOT_SETUP//#/##} / ${OPENROSDE_TMUX_SESSION_LAYOUT//#/##}"
OPENROSDE_STATUS_COLOR_COUNT="$(tput colors 2>/dev/null)"
if [ -z "${NO_COLOR}" ] && [[ "${OPENROSDE_STATUS_COLOR_COUNT}" =~ ^[0-9]+$ ]] && [ "${OPENROSDE_STATUS_COLOR_COUNT}" -ge 8 ]; then
  OPENROSDE_STATUS_BAR_STYLE="fg=colour250,bg=colour235"
  OPENROSDE_STATUS_LEFT_TEXT="#[fg=colour255,bg=colour98,bold] OpenRoSDE #[fg=colour141,bg=colour235,nobold] ${OPENROSDE_STATUS_ROBOT_TEXT} "
  OPENROSDE_STATUS_RIGHT_TEXT="#[fg=colour245] help: #[fg=colour141]openrosde-help "
  OPENROSDE_STATUS_TAB_STYLE="fg=colour250,bg=colour235"
  OPENROSDE_STATUS_CURRENT_TAB_STYLE="fg=colour255,bg=colour98,bold"
else
  OPENROSDE_STATUS_BAR_STYLE="default"
  OPENROSDE_STATUS_LEFT_TEXT="#[bold] OpenRoSDE #[nobold] ${OPENROSDE_STATUS_ROBOT_TEXT} "
  OPENROSDE_STATUS_RIGHT_TEXT=" help: openrosde-help "
  OPENROSDE_STATUS_TAB_STYLE="default"
  OPENROSDE_STATUS_CURRENT_TAB_STYLE="reverse"
fi

# Set the options of the session: the bar at the bottom, its sides, and the tabs in the middle.
tmux set-option -t "=${OPENROSDE_TMUX_SESSION_NAME}:" status on > /dev/null
tmux set-option -t "=${OPENROSDE_TMUX_SESSION_NAME}:" status-position bottom > /dev/null
tmux set-option -t "=${OPENROSDE_TMUX_SESSION_NAME}:" status-justify centre > /dev/null
tmux set-option -t "=${OPENROSDE_TMUX_SESSION_NAME}:" status-style "${OPENROSDE_STATUS_BAR_STYLE}" > /dev/null
tmux set-option -t "=${OPENROSDE_TMUX_SESSION_NAME}:" status-left "${OPENROSDE_STATUS_LEFT_TEXT}" > /dev/null
tmux set-option -t "=${OPENROSDE_TMUX_SESSION_NAME}:" status-left-length 80 > /dev/null
tmux set-option -t "=${OPENROSDE_TMUX_SESSION_NAME}:" status-right "${OPENROSDE_STATUS_RIGHT_TEXT}" > /dev/null
tmux set-option -t "=${OPENROSDE_TMUX_SESSION_NAME}:" status-right-length 40 > /dev/null

# Set the options of every window of the session, which draw its tab: its number and its name, with a 'Z' while a pane is zoomed.
for OPENROSDE_SESSION_WINDOW_ID in $(tmux list-windows -t "=${OPENROSDE_TMUX_SESSION_NAME}" -F '#{window_id}'); do
  tmux set-option -w -t "${OPENROSDE_SESSION_WINDOW_ID}" window-status-format " #I #W#{?window_zoomed_flag, Z,} " > /dev/null
  tmux set-option -w -t "${OPENROSDE_SESSION_WINDOW_ID}" window-status-current-format " #I #W#{?window_zoomed_flag, Z,} " > /dev/null
  tmux set-option -w -t "${OPENROSDE_SESSION_WINDOW_ID}" window-status-style "${OPENROSDE_STATUS_TAB_STYLE}" > /dev/null
  tmux set-option -w -t "${OPENROSDE_SESSION_WINDOW_ID}" window-status-current-style "${OPENROSDE_STATUS_CURRENT_TAB_STYLE}" > /dev/null
done

################################################################################

# Show the first window and attach to the session.
tmux select-window -t "=${OPENROSDE_TMUX_SESSION_NAME}:^"
openrosde-attach-tmux-session
