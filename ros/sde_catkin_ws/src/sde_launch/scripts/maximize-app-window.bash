#!/bin/bash

# This script maximizes the first X11 window whose title matches the given pattern.
# It retries for up to 10 additional seconds to handle slow application startup.
#
# Usage: bash ./maximize-app-window.bash <window-title> [delay-seconds]
#
# <window-title>: Substring to match against window titles (case-insensitive).
# [delay-seconds]: Seconds to wait before the first attempt.
#                  Default value is '3'.

################################################################################

SDE_WINDOW_TITLE="${1}"
SDE_DELAY="3"

# Parse the optional delay argument, ignoring ROS-injected '__*' args (e.g. '__name:=maximize_rviz', '__log:=...') that roslaunch appends after 'args'.
for SDE_ARG in "${@:2}"; do
  if [[ "${SDE_ARG}" != __* ]]; then
    SDE_DELAY="${SDE_ARG}"
    break
  fi
done

################################################################################

# Wait for the window to appear before the first attempt.
sleep "${SDE_DELAY}"

# Retry until the window is found and maximized (up to 10 additional seconds).
for SDE_ATTEMPT in $(seq 1 10); do
  if wmctrl -r "${SDE_WINDOW_TITLE}" -b add,maximized_vert,maximized_horz 2>/dev/null; then
    break
  fi
  sleep 1
done
