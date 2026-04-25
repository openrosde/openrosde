#!/bin/bash

# This script maximizes the first X11 window whose title matches the given pattern,
# then restores focus to Terminator.
# A shared lock file ensures only one concurrent instance runs the focus-restore loop at a time,
# preventing focus flickering when multiple maximize scripts run concurrently on startup.
#
# Usage: bash ./maximize-app-window.bash <window-title> [delay-seconds]
#
# <window-title>: Substring to match against window titles (case-insensitive).
# [delay-seconds]: Seconds to wait before the first attempt.
#                  Default value is '1'.

################################################################################

SDE_WINDOW_TITLE="${1}"
SDE_STARTUP_DELAY="1"

# Parse the optional delay argument, ignoring ROS-injected '__*' args (e.g. '__name:=maximize_rviz', '__log:=...') that roslaunch appends after 'args'.
for SDE_LAUNCH_ARG in "${@:2}"; do
  if [[ "${SDE_LAUNCH_ARG}" != __* ]]; then
    SDE_STARTUP_DELAY="${SDE_LAUNCH_ARG}"
    break
  fi
done

################################################################################

# Wait before the first attempt.
sleep "${SDE_STARTUP_DELAY}"

# Phase 1: Wait silently for the window to appear, then maximize it.
# No focus calls here — concurrent instances must not fight for focus before their windows open.
for SDE_ATTEMPT in $(seq 1 60); do
  if wmctrl -r "${SDE_WINDOW_TITLE}" -b add,maximized_vert,maximized_horz 2>/dev/null; then
    break
  fi
  sleep 1
done

# Phase 2: Re-maximize and restore focus to Terminator.
# A non-blocking lock ensures only one concurrent instance runs this loop at a time.
# Scripts that cannot acquire the lock skip focus-restore entirely (their window is already maximized).
# This prevents simultaneous scripts (e.g. RViz, FlexBE, rqt suite) from flickering focus.
# Match Terminator by its window title 'SDE (' which is shared by all platform layouts (set in terminator/*.config).
(
  flock --nonblock 200 || exit 0
  for SDE_FOCUS_ATTEMPT in $(seq 1 5); do
    wmctrl -r "${SDE_WINDOW_TITLE}" -b add,maximized_vert,maximized_horz 2>/dev/null
    wmctrl -a "SDE (" 2>/dev/null
    sleep 1
  done
) 200>/tmp/sde_maximize_focus.lock
