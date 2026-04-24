#!/bin/bash

# This script maximizes the first X11 window whose title matches the given pattern.
# It retries for up to 30 additional seconds to handle slow application startup.
# After maximizing, it restores focus to Terminator for 3 seconds to outlast startup focus-stealing (e.g. Gazebo world loading).
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

# Retry until the window is found and maximized (up to 30 additional seconds).
for SDE_RETRY_ATTEMPT in $(seq 1 30); do
  if wmctrl -r "${SDE_WINDOW_TITLE}" -b add,maximized_vert,maximized_horz 2>/dev/null; then
    # Restore focus to Terminator a few times to outlast focus-stealing during app startup (e.g. Gazebo world loading).
    for SDE_FOCUS_ATTEMPT in $(seq 1 3); do
      wmctrl -a "SDE (" 2>/dev/null
      sleep 1
    done
    break
  fi
  sleep 1
done
