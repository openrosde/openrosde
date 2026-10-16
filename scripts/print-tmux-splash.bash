#!/bin/bash

# This script prints the splash of a 'tmux' session of OpenRoSDE: a wordmark, the session, and how to use its tabs and panes.
# The shell of the Docker container prints it right before the prompt of the first pane of a session, which 'RUN-TMUX-SESSION.bash' names through 'RUN-DOCKER-CONTAINER.bash', since that shell clears the pane when it starts.
# With '--help', it prints the same help under a one-line wordmark, as 'openrosde-help' does in every shell of the container.
# The wordmark is drawn here in a purple accent, plain when 'NO_COLOR' is set, when the output is not a terminal, or when the terminal has no colors, and compact when the terminal is narrower than the wordmark or too short to show it above the prompt of the pane.
#
# Usage: bash ./scripts/print-tmux-splash.bash [--help]
#
# [--help]: Prints the help under a one-line wordmark.
#
# The script reads the session from the environment, and leaves out what is not set:
# - 'OPENROSDE_TMUX_SESSION_NAME' and 'OPENROSDE_TMUX_SESSION_LAYOUT': the session and its layout, which 'RUN-TMUX-SESSION.bash' names.
# - 'OPENROSDE_DOCKER_PROJECT' and 'OPENROSDE_DOCKER_CONTAINER': the Docker project and the container, which 'scripts/load-openrosde-env.bash' derives.
# - 'OPENROSDE_ROBOT_PLATFORM' and 'OPENROSDE_ROBOT_SETUP': the platform and the setup, which the settings select.
# - 'COLUMNS' and 'LINES': the size of the terminal, which 'tput' reads otherwise.

################################################################################

# Select the large wordmark or the help alone.
if [ "$1" = "--help" ]; then
  OPENROSDE_SPLASH_ART_WANTED=false
elif [ -z "$1" ]; then
  OPENROSDE_SPLASH_ART_WANTED=true
else
  echo "Usage: bash ./scripts/print-tmux-splash.bash [--help]" >&2
  exit 1
fi

################################################################################

# Read the size and the colors of the terminal with 'tput' when the output is a terminal, which 'COLUMNS' and 'LINES' override, such as to preview the splash at a given width.
# The size stays 80 columns, with no known height, when neither tells it.
OPENROSDE_SPLASH_COLUMN_COUNT=80
OPENROSDE_SPLASH_LINE_COUNT=""
OPENROSDE_SPLASH_COLOR_COUNT=0
if [ -t 1 ] && tput longname > /dev/null 2>&1; then
  OPENROSDE_SPLASH_COLUMN_COUNT="$(tput cols)"
  OPENROSDE_SPLASH_LINE_COUNT="$(tput lines)"
  OPENROSDE_SPLASH_COLOR_COUNT="$(tput colors)"
fi
if [[ "${COLUMNS}" =~ ^[0-9]+$ ]]; then
  OPENROSDE_SPLASH_COLUMN_COUNT="${COLUMNS}"
fi
if [[ "${LINES}" =~ ^[0-9]+$ ]]; then
  OPENROSDE_SPLASH_LINE_COUNT="${LINES}"
fi

# Style the splash in the purple accent of OpenRoSDE, with the colors of 256 that 'tmux' maps to those of the terminal, unless 'NO_COLOR' is set, the output is not a terminal, or the terminal has fewer than 8 colors.
# https://no-color.org/
OPENROSDE_SPLASH_ART_STYLES=("" "" "" "" "" "")
OPENROSDE_SPLASH_LABEL_STYLE=""
OPENROSDE_SPLASH_DIM_STYLE=""
OPENROSDE_SPLASH_STYLE_END=""
if [ -z "${NO_COLOR}" ] && [ -t 1 ] && [[ "${OPENROSDE_SPLASH_COLOR_COUNT}" =~ ^[0-9]+$ ]] && [ "${OPENROSDE_SPLASH_COLOR_COUNT}" -ge 8 ]; then
  OPENROSDE_SPLASH_ART_STYLES=($'\e[38;5;141m' $'\e[38;5;135m' $'\e[38;5;99m' $'\e[38;5;98m' $'\e[38;5;92m' $'\e[38;5;91m')
  OPENROSDE_SPLASH_LABEL_STYLE=$'\e[1;38;5;98m'
  OPENROSDE_SPLASH_DIM_STYLE=$'\e[2m'
  OPENROSDE_SPLASH_STYLE_END=$'\e[0m'
fi

################################################################################

# Draw the wordmark 'OpenRoSDE' by hand with the block characters of Unicode, 75 columns wide and 6 lines tall, with a shade of the accent per line.
OPENROSDE_SPLASH_ART_LINES=(
  ' ▄████▄                          ██████▄           ▄██████ ██████▄  ███████'
  '██    ██                         ██    ██         ██       ██    ██ ██'
  '██    ██ █████▄   ▄███▄  █████▄  ██████▀   ▄███▄   ▀█████▄ ██    ██ ██████'
  '██    ██ ██   ██ ██▄▄▄██ ██   ██ ██  ▀█▄  ██   ██       ██ ██    ██ ██'
  ' ▀████▀  █████▀  ▀█▄▄▄▄  ██   ██ ██    ██  ▀███▀  ██████▀  ██████▀  ███████'
  '         ██'
)
OPENROSDE_SPLASH_ART_WIDTH=75

################################################################################

# Write the help, one line per topic, from the session that the environment names.
OPENROSDE_SPLASH_HELP_LABELS=()
OPENROSDE_SPLASH_HELP_TEXTS=()
function openrosde-add-splash-line () {
  OPENROSDE_SPLASH_HELP_LABELS+=("$1")
  OPENROSDE_SPLASH_HELP_TEXTS+=("$2")
}

# Name the robot: the setup and its platform, or the platform alone for its default setup, and the layout.
if [ -n "${OPENROSDE_ROBOT_PLATFORM}" ]; then
  OPENROSDE_SPLASH_ROBOT_TEXT="${OPENROSDE_ROBOT_PLATFORM}"
  if [ -n "${OPENROSDE_ROBOT_SETUP}" ] && [ "${OPENROSDE_ROBOT_SETUP}" != "${OPENROSDE_ROBOT_PLATFORM}" ]; then
    OPENROSDE_SPLASH_ROBOT_TEXT="${OPENROSDE_ROBOT_SETUP} on ${OPENROSDE_ROBOT_PLATFORM}"
  fi
  if [ -n "${OPENROSDE_TMUX_SESSION_LAYOUT}" ]; then
    OPENROSDE_SPLASH_ROBOT_TEXT="${OPENROSDE_SPLASH_ROBOT_TEXT}, layout ${OPENROSDE_TMUX_SESSION_LAYOUT}"
  fi
  openrosde-add-splash-line "Robot" "${OPENROSDE_SPLASH_ROBOT_TEXT}"
fi

# Name the session and its container.
if [ -n "${OPENROSDE_TMUX_SESSION_NAME}" ]; then
  if [ -n "${OPENROSDE_DOCKER_CONTAINER}" ]; then
    openrosde-add-splash-line "Session" "${OPENROSDE_TMUX_SESSION_NAME}, container ${OPENROSDE_DOCKER_CONTAINER}"
  else
    openrosde-add-splash-line "Session" "${OPENROSDE_TMUX_SESSION_NAME}"
  fi
fi

# Tell how the tabs, the panes, and the prompts of the panes work.
openrosde-add-splash-line "Tabs" "click a tab, or Ctrl+b then its number, n for next, p for previous"
openrosde-add-splash-line "Panes" "click to focus, wheel to scroll, Ctrl+b z to zoom, Ctrl+b [ to copy"
openrosde-add-splash-line "Launch" "every pane waits for a key before it launches anything"

# Tell how to detach and come back with the same command, and how to close the session, both on the host, such as in the tab 'host'.
openrosde-add-splash-line "Detach" "Ctrl+b d, and come back on the host with the same command:"
if [ -n "${OPENROSDE_DOCKER_PROJECT}" ] && [ -n "${OPENROSDE_TMUX_SESSION_LAYOUT}" ]; then
  openrosde-add-splash-line "" "bash ./RUN-TMUX-SESSION.bash ${OPENROSDE_DOCKER_PROJECT} ${OPENROSDE_TMUX_SESSION_LAYOUT}"
else
  openrosde-add-splash-line "" "bash ./RUN-TMUX-SESSION.bash [docker-project] [session-layout]"
fi
if [ -n "${OPENROSDE_TMUX_SESSION_NAME}" ]; then
  openrosde-add-splash-line "Close" "tmux kill-session -t ${OPENROSDE_TMUX_SESSION_NAME}, on the host"
elif [ -n "${OPENROSDE_ROBOT_PLATFORM}" ]; then
  openrosde-add-splash-line "Close" "tmux kill-session -t openrosde-${OPENROSDE_ROBOT_PLATFORM}-<docker-project>, on the host"
else
  openrosde-add-splash-line "Close" "tmux kill-session -t openrosde-<platform>-<docker-project>, on the host"
fi

# Tell where to read more.
openrosde-add-splash-line "More" "openrosde-help, docs/, and https://openrosde.org"

################################################################################

# Show the large wordmark only when the terminal is wider than it, and tall enough for the splash and the 4 lines of the prompt of a pane below it.
# The splash takes a blank line, the wordmark, its tagline, a blank line, the help, and a blank line.
OPENROSDE_SPLASH_LINE_TOTAL=$((${#OPENROSDE_SPLASH_ART_LINES[@]} + ${#OPENROSDE_SPLASH_HELP_LABELS[@]} + 4))
if [ "${OPENROSDE_SPLASH_ART_WANTED}" = "true" ]; then
  if [ "${OPENROSDE_SPLASH_COLUMN_COUNT}" -lt $((OPENROSDE_SPLASH_ART_WIDTH + 3)) ]; then
    OPENROSDE_SPLASH_ART_WANTED=false
  elif [ -n "${OPENROSDE_SPLASH_LINE_COUNT}" ] && [ "${OPENROSDE_SPLASH_LINE_COUNT}" -lt $((OPENROSDE_SPLASH_LINE_TOTAL + 4)) ]; then
    OPENROSDE_SPLASH_ART_WANTED=false
  fi
fi

# Print the large wordmark with its tagline, or the compact one, a single line.
echo ""
if [ "${OPENROSDE_SPLASH_ART_WANTED}" = "true" ]; then
  for OPENROSDE_SPLASH_ART_INDEX in "${!OPENROSDE_SPLASH_ART_LINES[@]}"; do
    printf '  %s%s%s\n' "${OPENROSDE_SPLASH_ART_STYLES[${OPENROSDE_SPLASH_ART_INDEX}]}" "${OPENROSDE_SPLASH_ART_LINES[${OPENROSDE_SPLASH_ART_INDEX}]}" "${OPENROSDE_SPLASH_STYLE_END}"
  done
  printf '  %s%s%s\n' "${OPENROSDE_SPLASH_DIM_STYLE}" "Open Robotic SDE" "${OPENROSDE_SPLASH_STYLE_END}"
else
  printf '  %s%s%s  %s%s%s\n' "${OPENROSDE_SPLASH_LABEL_STYLE}" "OpenRoSDE" "${OPENROSDE_SPLASH_STYLE_END}" "${OPENROSDE_SPLASH_DIM_STYLE}" "Open Robotic SDE" "${OPENROSDE_SPLASH_STYLE_END}"
fi
echo ""

# Print the help, with its labels in the accent.
for OPENROSDE_SPLASH_HELP_INDEX in "${!OPENROSDE_SPLASH_HELP_LABELS[@]}"; do
  printf '  %s%-8s%s %s\n' "${OPENROSDE_SPLASH_LABEL_STYLE}" "${OPENROSDE_SPLASH_HELP_LABELS[${OPENROSDE_SPLASH_HELP_INDEX}]}" "${OPENROSDE_SPLASH_STYLE_END}" "${OPENROSDE_SPLASH_HELP_TEXTS[${OPENROSDE_SPLASH_HELP_INDEX}]}"
done
echo ""
