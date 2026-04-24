#!/bin/bash

# This script maximizes the first X11 window whose title matches the given pattern,
# then restores focus to Terminator.
# It retries for up to 60 additional seconds to handle slow application startup.
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

# Wait for the window to appear before the first attempt.
sleep "${SDE_STARTUP_DELAY}"

# Retry until the window is found and maximized (up to 60 additional seconds).
for SDE_RETRY_ATTEMPT in $(seq 1 60); do
  if wmctrl -r "${SDE_WINDOW_TITLE}" -b add,maximized_vert,maximized_horz 2>/dev/null; then
    # Restore focus to Terminator by matching its WM_CLASS (reliable regardless of tab title).
    wmctrl -xa terminator 2>/dev/null
    break
  fi
  sleep 1
done
