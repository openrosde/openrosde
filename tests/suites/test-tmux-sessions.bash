#!/bin/bash

# This suite checks the 'tmux' sessions of 'RUN-TMUX-SESSION.bash' with the real 'tmux', while 'docker' is stubbed, so every pane exits at once and stays visible.
# It covers the six platforms of the core in both layouts, pane for pane, the second run that attaches, the mouse and the title, and a setup with a layout of its own.
#
# Usage: bash ./tests/run.bash test-tmux-sessions

################################################################################

# Load the helpers and create the scratch copy.
source "${OPENROSDE_TEST_SOURCE_DIR}/tests/load-test-helpers.bash"
openrosde-test-create-copy
OPENROSDE_TEST_PLATFORM_NAMES="cobotta fetch hsr sciurus17 turtlebot3 ur5e"

# Run a 'tmux' server of the suite alone, which keeps the panes whose command has exited.
if ! command -v tmux > /dev/null 2>&1; then
  echo "Error: The 'tmux' suite needs 'tmux', which 'tests/run.bash' installs in its container."
  exit 1
fi
export TMUX_TMPDIR="${OPENROSDE_TEST_WORK_DIR}/tmux"
export TERM=xterm
unset TMUX
mkdir -p "${TMUX_TMPDIR}"
echo "set -g remain-on-exit on" > "${HOME}/.tmux.conf"

# Print the panes of a session, one line '<window>|<command>' per pane, window after window.
function openrosde-test-print-session () {
  tmux list-panes -s -t "=$1" -F '#{window_index} #{pane_index} #{window_name}|#{pane_start_command}' \
    | sort -n -k1,1 -k2,2 \
    | cut -d' ' -f3- \
    | sed 's/|"\(.*\)"$/|\1/'
}

# Print the panes that a layout should open from pane files, read here on their own, in the same form.
function openrosde-test-print-expected-session () {
  local OPENROSDE_TEST_PANES_FILE OPENROSDE_TEST_PANE_LAYOUTS OPENROSDE_TEST_PANE_WINDOW OPENROSDE_TEST_PANE_LAUNCH
  for OPENROSDE_TEST_PANES_FILE in "${@:2}"; do
    while read -r OPENROSDE_TEST_PANE_LAYOUTS OPENROSDE_TEST_PANE_WINDOW OPENROSDE_TEST_PANE_LAUNCH; do
      if [ -z "${OPENROSDE_TEST_PANE_LAYOUTS}" ] || [ "${OPENROSDE_TEST_PANE_LAYOUTS:0:1}" = "#" ]; then
        continue
      fi
      if [ "${OPENROSDE_TEST_PANE_LAYOUTS}" != "*" ] && [[ ",${OPENROSDE_TEST_PANE_LAYOUTS}," != *",$1,"* ]]; then
        continue
      fi
      case "${OPENROSDE_TEST_PANE_LAUNCH}" in
        host) echo "${OPENROSDE_TEST_PANE_WINDOW}|" ;;
        shell) echo "${OPENROSDE_TEST_PANE_WINDOW}|bash ./RUN-DOCKER-CONTAINER.bash test" ;;
        *) echo "${OPENROSDE_TEST_PANE_WINDOW}|bash ./RUN-DOCKER-CONTAINER.bash test ${OPENROSDE_TEST_PANE_LAUNCH}" ;;
      esac
    done < "${OPENROSDE_TEST_ROOT_DIR}/${OPENROSDE_TEST_PANES_FILE}"
  done | awk -F'|' '{ if (!($1 in panes)) { order[++count] = $1 } panes[$1] = panes[$1] $0 "\n" } END { for (i = 1; i <= count; i++) printf "%s", panes[order[i]] }'
}

# Stop the 'tmux' server of the suite, and wait up to five seconds until the server and the commands of its panes have exited, since 'tmux kill-server' returns before they do and they would still write into the scratch copy while it is removed.
# 'command -p' runs the real 'sleep' rather than its stub.
function openrosde-test-stop-tmux-server () {
  local OPENROSDE_TEST_TMUX_PIDS OPENROSDE_TEST_TMUX_PID OPENROSDE_TEST_WAIT_COUNT OPENROSDE_TEST_RUNNING_PIDS
  OPENROSDE_TEST_TMUX_PIDS="$(tmux list-sessions -F '#{pid}' 2>/dev/null; tmux list-panes -a -F '#{pane_pid}' 2>/dev/null)"
  tmux kill-server > /dev/null 2>&1
  OPENROSDE_TEST_WAIT_COUNT=0
  while [ "${OPENROSDE_TEST_WAIT_COUNT}" -lt 50 ]; do
    OPENROSDE_TEST_RUNNING_PIDS=""
    for OPENROSDE_TEST_TMUX_PID in ${OPENROSDE_TEST_TMUX_PIDS}; do
      if kill -0 "${OPENROSDE_TEST_TMUX_PID}" 2>/dev/null; then
        OPENROSDE_TEST_RUNNING_PIDS="${OPENROSDE_TEST_RUNNING_PIDS} ${OPENROSDE_TEST_TMUX_PID}"
      fi
    done
    if [ -z "${OPENROSDE_TEST_RUNNING_PIDS}" ]; then
      return 0
    fi
    command -p sleep 0.1
    OPENROSDE_TEST_WAIT_COUNT=$((OPENROSDE_TEST_WAIT_COUNT + 1))
  done
  echo "Warning: The 'tmux' server or its panes still run after five seconds:${OPENROSDE_TEST_RUNNING_PIDS}."
}

################################################################################

# Check the sessions of the six platforms of the core in both layouts.
for OPENROSDE_TEST_PLATFORM_NAME in ${OPENROSDE_TEST_PLATFORM_NAMES}; do
  for OPENROSDE_TEST_SESSION_LAYOUT in default-gazebo default-realworld; do
    openrosde-test-select-template "env/${OPENROSDE_TEST_PLATFORM_NAME}.env"
    openrosde-test-run bash ./RUN-TMUX-SESSION.bash test "${OPENROSDE_TEST_SESSION_LAYOUT}"
    openrosde-test-check "opens the '${OPENROSDE_TEST_SESSION_LAYOUT}' session of '${OPENROSDE_TEST_PLATFORM_NAME}' pane for pane" \
      "$(openrosde-test-print-expected-session "${OPENROSDE_TEST_SESSION_LAYOUT}" "tmux/${OPENROSDE_TEST_PLATFORM_NAME}.panes" tmux/openrosde.panes)" \
      "$(openrosde-test-print-session "openrosde-${OPENROSDE_TEST_PLATFORM_NAME}-test")"
    if [ "${OPENROSDE_TEST_PLATFORM_NAME}" != "ur5e" ] || [ "${OPENROSDE_TEST_SESSION_LAYOUT}" != "default-realworld" ]; then
      tmux kill-session -t "=openrosde-${OPENROSDE_TEST_PLATFORM_NAME}-test"
    fi
  done
done

################################################################################

# Check the second run, the mouse, and the title on the last session, which still runs.
OPENROSDE_TEST_PANE_COUNT="$(tmux list-panes -s -t "=openrosde-ur5e-test" | wc -l)"
openrosde-test-run bash ./RUN-TMUX-SESSION.bash test default-realworld
openrosde-test-check "attaches to a running session instead of adding panes" \
  "Attaching to the running 'tmux' session 'openrosde-ur5e-test' ${OPENROSDE_TEST_PANE_COUNT}" \
  "$(echo "${OPENROSDE_TEST_OUTPUT}" | grep -o "Attaching to the running 'tmux' session 'openrosde-ur5e-test'") $(tmux list-panes -s -t "=openrosde-ur5e-test" | wc -l)"
openrosde-test-check "turns the mouse on" \
  "mouse on" \
  "$(tmux show-options -t "=openrosde-ur5e-test:" mouse)"
openrosde-test-check "titles the terminal after the session" \
  "$(printf '%s\n' "set-titles on" 'set-titles-string "OpenRoSDE (#{session_name})"')" \
  "$(tmux show-options -t "=openrosde-ur5e-test:" set-titles; tmux show-options -t "=openrosde-ur5e-test:" set-titles-string)"
tmux kill-session -t "=openrosde-ur5e-test"

################################################################################

# Check a setup that runs the platform extension 'foo' with the extension 'my-lab-tools', and declares a layout 'lab-demo' of its own.
openrosde-test-create-extension openrosde-platform-foo
openrosde-test-write-platform-template extensions/openrosde-platform-foo foo
openrosde-test-write-file extensions/openrosde-platform-foo/tmux/foo.panes "*  robot  foo_bringup_default_gazebo.launch"
openrosde-test-create-extension my-lab-tools
openrosde-test-write-file extensions/my-lab-tools/tmux/my-lab-tools.panes "*  lab-tools  my_lab_tools:monitor.launch"
openrosde-test-create-extension my-lab
openrosde-test-write-setup-template extensions/my-lab my-lab-foo-bench foo "my-lab-tools"
openrosde-test-write-file extensions/my-lab/tmux/my-lab-demo.panes "lab-demo  demo  my_lab_launch:demo.launch" "default-gazebo  demo  my_lab_launch:simulation.launch"
openrosde-test-select-template extensions/my-lab/env/my-lab-foo-bench.env
openrosde-test-run bash ./RUN-TMUX-SESSION.bash test lab-demo
openrosde-test-check "opens the windows of the platform, the extension, the setup, then the core, in the layout of the setup" \
  "$(openrosde-test-print-expected-session lab-demo extensions/openrosde-platform-foo/tmux/foo.panes extensions/my-lab-tools/tmux/my-lab-tools.panes extensions/my-lab/tmux/my-lab-demo.panes tmux/openrosde.panes)" \
  "$(openrosde-test-print-session openrosde-foo-test)"
openrosde-test-stop-tmux-server

################################################################################

# Remove the scratch copy and report the result.
openrosde-test-remove-copy
openrosde-test-finish-suite
