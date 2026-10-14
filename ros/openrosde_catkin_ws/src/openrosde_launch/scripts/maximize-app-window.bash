#!/bin/bash

# This script maximizes the first X11 window whose title matches the given pattern, then restores focus to Terminator.
# A shared lock file ensures only one concurrent instance runs the focus-restore loop at a time, preventing focus flickering when multiple maximize scripts run concurrently on startup.
#
# Usage: bash ./maximize-app-window.bash <window-title> [delay-seconds]
#
# <window-title>: Substring to match against window titles (case-insensitive).
# [delay-seconds]: Seconds to wait before the first attempt.
#                  Default value is '1'.

################################################################################

OPENROSDE_WINDOW_TITLE="${1}"
OPENROSDE_STARTUP_DELAY="1"

# Parse the optional delay argument, ignoring ROS-injected '__*' args (e.g. '__name:=maximize_rviz', '__log:=...') that roslaunch appends after 'args'.
for OPENROSDE_LAUNCH_ARG in "${@:2}"; do
  if [[ "${OPENROSDE_LAUNCH_ARG}" != __* ]]; then
    OPENROSDE_STARTUP_DELAY="${OPENROSDE_LAUNCH_ARG}"
    break
  fi
done

################################################################################

# Wait before the first attempt.
sleep "${OPENROSDE_STARTUP_DELAY}"

# Phase 1: Wait silently for the window to appear, then maximize it.
# No focus calls here — concurrent instances must not fight for focus before their windows open.
for OPENROSDE_ATTEMPT in $(seq 1 60); do
  if wmctrl -r "${OPENROSDE_WINDOW_TITLE}" -b add,maximized_vert,maximized_horz 2>/dev/null; then
    break
  fi
  sleep 1
done

# Phase 2: Re-maximize and restore focus to Terminator.
# A non-blocking lock ensures only one concurrent instance runs this loop at a time.
# Scripts that cannot acquire the lock skip focus-restore entirely (their window is already maximized).
# This prevents simultaneous scripts (e.g. RViz, FlexBE, rqt suite) from flickering focus.
# Match Terminator by its window title 'OpenRoSDE (' which is shared by all platform layouts (set in terminator/*.config), or the terminal of a 'tmux' session, which 'RUN-TMUX-SESSION.bash' titles 'OpenRoSDE (<session>)'.
(
  flock --nonblock 200 || exit 0
  for OPENROSDE_FOCUS_ATTEMPT in $(seq 1 5); do
    wmctrl -r "${OPENROSDE_WINDOW_TITLE}" -b add,maximized_vert,maximized_horz 2>/dev/null
    wmctrl -a "OpenRoSDE (" 2>/dev/null
    sleep 1
  done
) 200>/tmp/openrosde_maximize_focus.lock
