#!/bin/bash

# This suite checks the 'tmux' sessions of 'RUN-TMUX-SESSION.bash' with the real 'tmux', while 'docker' is stubbed, so every pane exits at once and stays visible.
# It covers the platforms of the core, the canonical platforms cloned into 'extensions/' of the repository under test, the fake platform 'rover' of an extension in both layouts, and the fake platform 'crawler' on ROS 2, pane for pane, with the windows in the standard order whatever order the pane files declare them in.
# It also covers the tabs numbered from 1, the second run that attaches, the mouse, the title, the status bar with and without colors, which sets no global option and no key binding, a setup with a layout and windows of its own, which open after the standard ones with a warning, and the splash, which the first pane alone passes into the shell of the container, where it prints right before the prompt.
#
# Usage: bash ./tests/run.bash test-tmux-sessions

################################################################################

# Load the helpers and create the scratch copy.
source "${OPENROSDE_TEST_SOURCE_DIR}/tests/load-test-helpers.bash"
openrosde-test-create-copy

# List the platforms to check: those of the core, the canonical platforms that the repository under test holds in 'extensions/', 'crawler' on ROS 2, and 'rover', whose session stays open for the checks of the second run, each with the folder that holds it.
OPENROSDE_TEST_PLATFORM_RECORDS="$(openrosde-test-print-core-platforms | sed 's/$/ ./')"
for OPENROSDE_TEST_PLATFORM_NAME in cobotta fetch hsr sciurus17 turtlebot3 ur5e; do
  if openrosde-test-copy-cloned-extension "openrosde-platform-${OPENROSDE_TEST_PLATFORM_NAME}"; then
    OPENROSDE_TEST_PLATFORM_RECORDS="${OPENROSDE_TEST_PLATFORM_RECORDS}"$'\n'"${OPENROSDE_TEST_PLATFORM_NAME} extensions/openrosde-platform-${OPENROSDE_TEST_PLATFORM_NAME}"
  else
    echo "Skipping the platform '${OPENROSDE_TEST_PLATFORM_NAME}', which is not cloned into 'extensions/openrosde-platform-${OPENROSDE_TEST_PLATFORM_NAME}/'."
  fi
done
if [ -f "${OPENROSDE_TEST_ROOT_DIR}/extensions/openrosde-platform-turtlebot3/env/turtlebot3-ros2.env" ]; then
  OPENROSDE_TEST_PLATFORM_RECORDS="${OPENROSDE_TEST_PLATFORM_RECORDS}"$'\n'"turtlebot3-ros2 extensions/openrosde-platform-turtlebot3"
fi

# Create the platform 'crawler' on ROS 2, with a container shell in its window 'robot'.
openrosde-test-create-extension openrosde-platform-crawler
openrosde-test-write-platform-template extensions/openrosde-platform-crawler crawler
printf '%s\n' "OPENROSDE_ROS_VERSION=2" "OPENROSDE_ROS_DISTRO=lyrical" >> "${OPENROSDE_TEST_ROOT_DIR}/extensions/openrosde-platform-crawler/env/crawler.env"
openrosde-test-write-file extensions/openrosde-platform-crawler/tmux/crawler.panes \
  "*  robot  crawler_bringup_default_gazebo.launch.xml" \
  "*  robot  shell"
OPENROSDE_TEST_PLATFORM_RECORDS="${OPENROSDE_TEST_PLATFORM_RECORDS}"$'\n'"crawler extensions/openrosde-platform-crawler"

# Create the platform 'rover', whose pane file declares its window 'extra' before its window 'robot'.
openrosde-test-create-extension openrosde-platform-rover
openrosde-test-write-platform-template extensions/openrosde-platform-rover rover
openrosde-test-write-file extensions/openrosde-platform-rover/tmux/rover.panes \
  "*                  extra  rover_tools:rover_monitor_default.launch rate:=5" \
  "default-gazebo     robot  rover_bringup_default_gazebo.launch" \
  "default-realworld  robot  rover_bringup_default_realworld.launch"
OPENROSDE_TEST_PLATFORM_RECORDS="${OPENROSDE_TEST_PLATFORM_RECORDS}"$'\n'"rover extensions/openrosde-platform-rover"

# Run a 'tmux' server of the suite alone, which keeps the panes whose command has exited.
if ! command -v tmux > /dev/null 2>&1; then
  echo "Error: The 'tmux' suite needs 'tmux', which 'tests/run.bash' installs in its container."
  exit 1
fi
export TMUX_TMPDIR="${OPENROSDE_TEST_WORK_DIR}/tmux"
export TERM=xterm
unset TMUX NO_COLOR
mkdir -p "${TMUX_TMPDIR}"
echo "set -g remain-on-exit on" > "${HOME}/.tmux.conf"

# Start the server with a session of its own, and keep its global options and key bindings, which no session of OpenRoSDE may change, since they would change every other session of the server.
function openrosde-test-print-global-state () {
  tmux show-options -g
  tmux show-options -g -w
  tmux show-options -s
  tmux list-keys
}
tmux new-session -d -s openrosde-test-baseline
OPENROSDE_TEST_GLOBAL_STATE="$(openrosde-test-print-global-state)"

# Print the panes of a session, one line '<window>|<command>' per pane, window after window.
function openrosde-test-print-session () {
  tmux list-panes -s -t "=$1" -F '#{window_index} #{pane_index} #{window_name}|#{pane_start_command}' \
    | sort -n -k1,1 -k2,2 \
    | cut -d' ' -f3- \
    | sed 's/|"\(.*\)"$/|\1/'
}

# Print the panes that a layout should open from pane files, read here on their own, in the same form: the standard windows 'robot', 'extra', 'tools', 'user', and 'host' that hold a pane, in that order, then the other windows in the order the files declare them.
# The first pane that enters the container starts with the variables of the splash of the session given as first argument, with 'NO_COLOR' when the caller sets it.
function openrosde-test-print-expected-session () {
  local OPENROSDE_TEST_PANES_FILE OPENROSDE_TEST_PANE_LAYOUTS OPENROSDE_TEST_PANE_WINDOW OPENROSDE_TEST_PANE_LAUNCH OPENROSDE_TEST_SPLASH_ENV
  OPENROSDE_TEST_SPLASH_ENV="env OPENROSDE_TMUX_SESSION_NAME=$1 OPENROSDE_TMUX_SESSION_LAYOUT=$2"
  if [ -n "${NO_COLOR}" ]; then
    OPENROSDE_TEST_SPLASH_ENV="${OPENROSDE_TEST_SPLASH_ENV} NO_COLOR=1"
  fi
  for OPENROSDE_TEST_PANES_FILE in "${@:3}"; do
    while read -r OPENROSDE_TEST_PANE_LAYOUTS OPENROSDE_TEST_PANE_WINDOW OPENROSDE_TEST_PANE_LAUNCH; do
      if [ -z "${OPENROSDE_TEST_PANE_LAYOUTS}" ] || [ "${OPENROSDE_TEST_PANE_LAYOUTS:0:1}" = "#" ]; then
        continue
      fi
      if [ "${OPENROSDE_TEST_PANE_LAYOUTS}" != "*" ] && [[ ",${OPENROSDE_TEST_PANE_LAYOUTS}," != *",$2,"* ]]; then
        continue
      fi
      case "${OPENROSDE_TEST_PANE_LAUNCH}" in
        host) echo "${OPENROSDE_TEST_PANE_WINDOW}|" ;;
        shell) echo "${OPENROSDE_TEST_PANE_WINDOW}|bash ./RUN-DOCKER-CONTAINER.bash test" ;;
        *) echo "${OPENROSDE_TEST_PANE_WINDOW}|bash ./RUN-DOCKER-CONTAINER.bash test ${OPENROSDE_TEST_PANE_LAUNCH}" ;;
      esac
    done < "${OPENROSDE_TEST_ROOT_DIR}/${OPENROSDE_TEST_PANES_FILE}"
  done | awk -F'|' -v standard="robot extra tools user host" '
    { if (!($1 in panes)) { order[++count] = $1 } panes[$1] = panes[$1] $0 "\n" }
    END {
      standard_count = split(standard, names, " ")
      for (i = 1; i <= standard_count; i++) { if (names[i] in panes) { printf "%s", panes[names[i]]; printed[names[i]] = 1 } }
      for (i = 1; i <= count; i++) { if (!(order[i] in printed)) { printf "%s", panes[order[i]] } }
    }' \
  | awk -F'|' -v splash="${OPENROSDE_TEST_SPLASH_ENV} " '!done && $2 != "" { print $1 "|" splash $2; done = 1; next } { print }'
}

# Print the core pane file of the ROS of a template, 'tmux/openrosde-ros2.panes' on ROS 2 or else 'tmux/openrosde.panes'.
function openrosde-test-print-core-panes-file () {
  if grep -qx "OPENROSDE_ROS_VERSION=2" "${OPENROSDE_TEST_ROOT_DIR}/$1"; then
    echo "tmux/openrosde-ros2.panes"
  else
    echo "tmux/openrosde.panes"
  fi
}

# Wait up to ten seconds until every pane that runs a command has exited, since the panes run in the background and log their calls of the stubs while they run.
# 'command -p' runs the real 'sleep' rather than its stub.
function openrosde-test-wait-for-panes () {
  local OPENROSDE_TEST_WAIT_COUNT=0
  while [ "${OPENROSDE_TEST_WAIT_COUNT}" -lt 100 ]; do
    if ! tmux list-panes -a -F '#{pane_dead} #{pane_start_command}' | grep -q '^0 .'; then
      return 0
    fi
    command -p sleep 0.1
    OPENROSDE_TEST_WAIT_COUNT=$((OPENROSDE_TEST_WAIT_COUNT + 1))
  done
  echo "Warning: Panes of the 'tmux' server still run after ten seconds."
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

# Check the sessions of every platform in both layouts, with the windows in the standard order, and the splash in the first pane alone.
while read -r OPENROSDE_TEST_PLATFORM_NAME OPENROSDE_TEST_PLATFORM_ROOT; do
  if [ -z "${OPENROSDE_TEST_PLATFORM_NAME}" ]; then
    continue
  fi
  for OPENROSDE_TEST_SESSION_LAYOUT in default-gazebo default-realworld; do
    openrosde-test-select-template "${OPENROSDE_TEST_PLATFORM_ROOT}/env/${OPENROSDE_TEST_PLATFORM_NAME}.env"
    openrosde-test-run bash ./RUN-TMUX-SESSION.bash test "${OPENROSDE_TEST_SESSION_LAYOUT}"
    openrosde-test-check "opens the '${OPENROSDE_TEST_SESSION_LAYOUT}' session of '${OPENROSDE_TEST_PLATFORM_NAME}' pane for pane" \
      "$(openrosde-test-print-expected-session "openrosde-${OPENROSDE_TEST_PLATFORM_NAME}-test" "${OPENROSDE_TEST_SESSION_LAYOUT}" "${OPENROSDE_TEST_PLATFORM_ROOT}/tmux/${OPENROSDE_TEST_PLATFORM_NAME}.panes" "$(openrosde-test-print-core-panes-file "${OPENROSDE_TEST_PLATFORM_ROOT}/env/${OPENROSDE_TEST_PLATFORM_NAME}.env")")" \
      "$(openrosde-test-print-session "openrosde-${OPENROSDE_TEST_PLATFORM_NAME}-test")"
    if [ "${OPENROSDE_TEST_PLATFORM_NAME}" != "rover" ] || [ "${OPENROSDE_TEST_SESSION_LAYOUT}" != "default-realworld" ]; then
      tmux kill-session -t "=openrosde-${OPENROSDE_TEST_PLATFORM_NAME}-test"
    fi
  done
done <<< "${OPENROSDE_TEST_PLATFORM_RECORDS}"

################################################################################

# Check the tabs, the second run, the mouse, the title, and the status bar of the last session, which still runs, in a terminal with colors.
openrosde-test-check "numbers the tabs from 1, in the standard order rather than the order of the pane file" \
  "$(printf '%s\n' "1 robot" "2 extra" "3 tools" "4 user" "5 host")" \
  "$(tmux list-windows -t "=openrosde-rover-test" -F '#{window_index} #{window_name}')"
OPENROSDE_TEST_PANE_COUNT="$(tmux list-panes -s -t "=openrosde-rover-test" | wc -l)"
openrosde-test-run bash ./RUN-TMUX-SESSION.bash test default-realworld
openrosde-test-check "attaches to a running session instead of adding panes" \
  "Attaching to the running 'tmux' session 'openrosde-rover-test' ${OPENROSDE_TEST_PANE_COUNT}" \
  "$(echo "${OPENROSDE_TEST_OUTPUT}" | grep -o "Attaching to the running 'tmux' session 'openrosde-rover-test'") $(tmux list-panes -s -t "=openrosde-rover-test" | wc -l)"
openrosde-test-check "turns the mouse on" \
  "mouse on" \
  "$(tmux show-options -t "=openrosde-rover-test:" mouse)"
openrosde-test-check "titles the terminal after the session" \
  "$(printf '%s\n' "set-titles on" 'set-titles-string "OpenRoSDE (#{session_name})"')" \
  "$(tmux show-options -t "=openrosde-rover-test:" set-titles; tmux show-options -t "=openrosde-rover-test:" set-titles-string)"
openrosde-test-check "gives the session a status bar in the purple accent, with OpenRoSDE, the setup, and the layout on the left, the tabs in the middle, and the help on the right" \
  "$(printf '%s\n' "1" "on" "bottom" "centre" "fg=colour250,bg=colour235" \
    "#[fg=colour255,bg=colour98,bold] OpenRoSDE #[fg=colour141,bg=colour235,nobold] rover / default-realworld " \
    "#[fg=colour245] help: #[fg=colour141]openrosde-help ")" \
  "$(for OPENROSDE_TEST_OPTION_NAME in base-index status status-position status-justify status-style status-left status-right; do tmux show-options -v -t "=openrosde-rover-test:" "${OPENROSDE_TEST_OPTION_NAME}"; done)"
openrosde-test-check "draws every tab with its number and the name of its window, the current one in the accent" \
  "$(printf '%s\n' "1 robot 4" "2 extra 4" "3 tools 4" "4 user 4" "5 host 4" \
    " #I #W#{?window_zoomed_flag, Z,} " "fg=colour250,bg=colour235" "fg=colour255,bg=colour98,bold")" \
  "$(for OPENROSDE_TEST_WINDOW_INDEX in 1 2 3 4 5; do echo "${OPENROSDE_TEST_WINDOW_INDEX} $(tmux display-message -p -t "=openrosde-rover-test:${OPENROSDE_TEST_WINDOW_INDEX}" '#{window_name}') $(tmux show-options -w -t "=openrosde-rover-test:${OPENROSDE_TEST_WINDOW_INDEX}" | grep -c '^window-status-')"; done
    tmux show-options -w -v -t "=openrosde-rover-test:1" window-status-format
    tmux show-options -w -v -t "=openrosde-rover-test:1" window-status-style
    tmux show-options -w -v -t "=openrosde-rover-test:1" window-status-current-style)"
tmux kill-session -t "=openrosde-rover-test"

################################################################################

# Check a setup that runs the platform extension 'foo' with the extension 'my-lab-tools', and declares a layout 'lab-demo' of its own, in windows outside the standard ones, with 'NO_COLOR' set.
openrosde-test-create-extension openrosde-platform-foo
openrosde-test-write-platform-template extensions/openrosde-platform-foo foo
openrosde-test-write-file extensions/openrosde-platform-foo/tmux/foo.panes "*  robot  foo_bringup_default_gazebo.launch"
openrosde-test-create-extension my-lab-tools
openrosde-test-write-file extensions/my-lab-tools/tmux/my-lab-tools.panes "*  lab-tools  my_lab_tools:monitor.launch"
openrosde-test-create-extension my-lab
openrosde-test-write-setup-template extensions/my-lab my-lab-foo-bench foo "my-lab-tools"
openrosde-test-write-file extensions/my-lab/tmux/my-lab-demo.panes "lab-demo  demo  my_lab_launch:demo.launch" "default-gazebo  demo  my_lab_launch:simulation.launch"
openrosde-test-select-template extensions/my-lab/env/my-lab-foo-bench.env
openrosde-test-wait-for-panes
openrosde-test-run env NO_COLOR=1 bash ./RUN-TMUX-SESSION.bash test lab-demo
openrosde-test-check "opens the standard windows of the platform and the core in their order, then the windows of the extension and the setup, in the layout of the setup" \
  "$(NO_COLOR=1 openrosde-test-print-expected-session openrosde-foo-test lab-demo extensions/openrosde-platform-foo/tmux/foo.panes extensions/my-lab-tools/tmux/my-lab-tools.panes extensions/my-lab/tmux/my-lab-demo.panes tmux/openrosde.panes)" \
  "$(openrosde-test-print-session openrosde-foo-test)"
openrosde-test-check "warns once about each window outside the standard ones, with the pane file that declares it" \
  "$(printf '%s\n' \
    "Warning: The window 'lab-tools' of 'extensions/my-lab-tools/tmux/my-lab-tools.panes' is none of the standard windows 'robot', 'extra', 'tools', 'user', and 'host', so it opens after them." \
    "Warning: The window 'demo' of 'extensions/my-lab/tmux/my-lab-demo.panes' is none of the standard windows 'robot', 'extra', 'tools', 'user', and 'host', so it opens after them.")" \
  "$(echo "${OPENROSDE_TEST_OUTPUT}" | grep '^Warning')"
openrosde-test-check "numbers the windows outside the standard ones after them" \
  "$(printf '%s\n' "1 robot" "2 tools" "3 user" "4 host" "5 lab-tools" "6 demo")" \
  "$(tmux list-windows -t "=openrosde-foo-test" -F '#{window_index} #{window_name}')"
openrosde-test-check "keeps the status bar plain with 'NO_COLOR', with the current tab in reverse video" \
  "$(printf '%s\n' "default" "#[bold] OpenRoSDE #[nobold] my-lab-foo-bench / lab-demo " " help: openrosde-help " "default" "reverse")" \
  "$(tmux show-options -v -t "=openrosde-foo-test:" status-style; tmux show-options -v -t "=openrosde-foo-test:" status-left; tmux show-options -v -t "=openrosde-foo-test:" status-right
    tmux show-options -w -v -t "=openrosde-foo-test:6" window-status-style; tmux show-options -w -v -t "=openrosde-foo-test:6" window-status-current-style)"

# Check that the first pane alone passes the session into the shell of the container, with 'NO_COLOR', once its command and the commands of the other panes have run.
openrosde-test-wait-for-panes
openrosde-test-check "passes the session and 'NO_COLOR' into the shell of the container from the first pane alone" \
  "$(printf '%s\n' "docker exec -i -t --env OPENROSDE_TMUX_SESSION_NAME=openrosde-foo-test --env OPENROSDE_TMUX_SESSION_LAYOUT=lab-demo --env OPENROSDE_DOCKER_PROJECT=test --env OPENROSDE_DOCKER_CONTAINER=openrosde-foo-test-1 --env NO_COLOR=1 openrosde-foo-test-1 bash -i -c source /root/OpenRoSDE/docker/openrosde-base/scripts/run-roslaunch-repeatedly.bash foo_bringup_default_gazebo.launch" \
    "7 other panes enter the container without it")" \
  "$(openrosde-test-print-calls | grep '^docker exec ' | grep -e '--env'; echo "$(openrosde-test-print-calls | grep '^docker exec ' | grep -c -v -e '--env') other panes enter the container without it")"

# Check that no session changed a global option or a key binding of the server.
openrosde-test-check "sets no global option and no key binding of the 'tmux' server" \
  "" \
  "$(diff <(echo "${OPENROSDE_TEST_GLOBAL_STATE}") <(openrosde-test-print-global-state))"
openrosde-test-stop-tmux-server

################################################################################

# Check that the shell of the container prints the splash right before the prompt of the first pane, with the variables that 'RUN-DOCKER-CONTAINER.bash' passes, clears them once printed, and offers 'openrosde-help' in every shell.
# The settings point the shell to the scratch copy, as the mount of the repository does in the container.
openrosde-test-select-template extensions/openrosde-platform-rover/env/rover.env
echo "OPENROSDE_CONTAINER_ROOT_DIR=${OPENROSDE_TEST_ROOT_DIR}" >> "${OPENROSDE_TEST_ROOT_DIR}/.env.custom"
OPENROSDE_TEST_SHELL_COMMAND='source ./docker/openrosde-base/scripts/initialize-bash-shell.bash 2>/dev/null; echo "Prompt of the pane, with the session: ${OPENROSDE_TMUX_SESSION_NAME}${OPENROSDE_TMUX_SESSION_LAYOUT}${OPENROSDE_DOCKER_PROJECT}${OPENROSDE_DOCKER_CONTAINER}"; openrosde-help'
openrosde-test-run env OPENROSDE_CONTAINER_ROOT_DIR="${OPENROSDE_TEST_ROOT_DIR}" OPENROSDE_DOCKER_IMAGE_VERSION=def5678 \
  OPENROSDE_TMUX_SESSION_NAME=openrosde-rover-test OPENROSDE_TMUX_SESSION_LAYOUT=default-gazebo OPENROSDE_DOCKER_PROJECT=test OPENROSDE_DOCKER_CONTAINER=openrosde-rover-test-1 \
  bash -c "${OPENROSDE_TEST_SHELL_COMMAND}"
openrosde-test-check "prints the large splash of the session right before the prompt of the first pane, and clears the variables of the session" \
  "$(printf '%s\n' \
    "   ▄████▄                          ██████▄           ▄██████ ██████▄  ███████" \
    "  ██    ██                         ██    ██         ██       ██    ██ ██" \
    "  ██    ██ █████▄   ▄███▄  █████▄  ██████▀   ▄███▄   ▀█████▄ ██    ██ ██████" \
    "  ██    ██ ██   ██ ██▄▄▄██ ██   ██ ██  ▀█▄  ██   ██       ██ ██    ██ ██" \
    "   ▀████▀  █████▀  ▀█▄▄▄▄  ██   ██ ██    ██  ▀███▀  ██████▀  ██████▀  ███████" \
    "           ██" \
    "  Open Robotic SDE" \
    "" \
    "  Robot    rover, layout default-gazebo" \
    "  Session  openrosde-rover-test, container openrosde-rover-test-1" \
    "  Tabs     click a tab, or Ctrl+b then its number, n for next, p for previous" \
    "  Panes    click to focus, wheel to scroll, Ctrl+b z to zoom, Ctrl+b [ to copy" \
    "  Launch   every pane waits for a key before it launches anything" \
    "  Detach   Ctrl+b d, and come back on the host with the same command:" \
    "           bash ./RUN-TMUX-SESSION.bash test default-gazebo" \
    "  Close    tmux kill-session -t openrosde-rover-test, on the host" \
    "  More     openrosde-help, docs/, and https://openrosde.org" \
    "" \
    "Prompt of the pane, with the session: ")" \
  "$(echo "${OPENROSDE_TEST_OUTPUT}" | sed -n '/▄████▄/,/^Prompt of the pane/p')"
openrosde-test-check "prints the help with 'openrosde-help', under a one-line wordmark, with the platform of the shell" \
  "$(printf '%s\n' \
    "  OpenRoSDE  Open Robotic SDE" \
    "" \
    "  Robot    rover" \
    "  Tabs     click a tab, or Ctrl+b then its number, n for next, p for previous" \
    "  Panes    click to focus, wheel to scroll, Ctrl+b z to zoom, Ctrl+b [ to copy" \
    "  Launch   every pane waits for a key before it launches anything" \
    "  Detach   Ctrl+b d, and come back on the host with the same command:" \
    "           bash ./RUN-TMUX-SESSION.bash [docker-project] [session-layout]" \
    "  Close    tmux kill-session -t openrosde-rover-<docker-project>, on the host" \
    "  More     openrosde-help, docs/, and https://openrosde.org")" \
  "$(echo "${OPENROSDE_TEST_OUTPUT}" | sed -n '/^Prompt of the pane/,$p' | tail -n +3)"
openrosde-test-run env OPENROSDE_CONTAINER_ROOT_DIR="${OPENROSDE_TEST_ROOT_DIR}" OPENROSDE_DOCKER_IMAGE_VERSION=def5678 bash -c "${OPENROSDE_TEST_SHELL_COMMAND}"
openrosde-test-check "prints no splash in the other panes" \
  "1 wordmark" \
  "$(echo "${OPENROSDE_TEST_OUTPUT}" | grep -c 'Open Robotic SDE') wordmark"

# Check the compact splash in a narrow terminal, and the plain splash in a terminal with colors once 'NO_COLOR' is set.
openrosde-test-run env COLUMNS=60 OPENROSDE_TMUX_SESSION_NAME=openrosde-rover-test bash ./scripts/print-tmux-splash.bash
openrosde-test-check "prints the compact wordmark in a terminal narrower than the large one" \
  "$(printf '%s\n' "" "  OpenRoSDE  Open Robotic SDE" "" "  Session  openrosde-rover-test")" \
  "$(echo "${OPENROSDE_TEST_OUTPUT}" | head -n 4)"
openrosde-test-run env LINES=20 bash ./scripts/print-tmux-splash.bash
openrosde-test-check "prints the compact wordmark in a terminal too short for the large one above the prompt" \
  "  OpenRoSDE  Open Robotic SDE" \
  "$(echo "${OPENROSDE_TEST_OUTPUT}" | sed -n 2p)"
openrosde-test-run script -q -e -c "env TERM=xterm COLUMNS=100 LINES=50 bash ./scripts/print-tmux-splash.bash" /dev/null
openrosde-test-check "draws the wordmark in the purple accent in a terminal with colors" \
  "$(printf '\e[38;5;141m')" \
  "$(echo "${OPENROSDE_TEST_OUTPUT}" | sed -n 2p | grep -o $'\e\\[38;5;141m')"
openrosde-test-run script -q -e -c "env TERM=xterm COLUMNS=100 LINES=50 NO_COLOR=1 bash ./scripts/print-tmux-splash.bash" /dev/null
openrosde-test-check "draws the wordmark plain in a terminal with colors once 'NO_COLOR' is set" \
  "0 escape sequences" \
  "$(echo "${OPENROSDE_TEST_OUTPUT}" | grep -c $'\e') escape sequences"

################################################################################

# Remove the scratch copy and report the result.
openrosde-test-remove-copy
openrosde-test-finish-suite
