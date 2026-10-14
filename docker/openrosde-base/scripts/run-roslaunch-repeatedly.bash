#!/bin/bash

# This script runs a ROS launch file and prompts the user to select the execution mode (remote, local, or child shell).
# It is used by Terminator sub-terminals to conveniently preload launch files.
#
# Usage: bash run-roslaunch-repeatedly.bash <launch-file> [launch-args...]
#
# <launch-file>:    The ROS launch file to run (e.g., 'example_roslaunch_file.launch').
#                   Optionally, specify the ROS package with the 'package:file.launch' format.
#                   If no package is specified, the 'OPENROSDE_LAUNCH_PACKAGE' environment variable is used.
# [launch-args...]: Optional 'arg:=value' tokens forwarded to 'roslaunch' as is.
#                   They override a launch file argument without modifying the launch file itself
#                   (e.g., 'run-roslaunch-repeatedly.bash ur5e_teleop_default_realworld.launch input_source:=sightline').

################################################################################

# Parse the optional 'package:file.launch' format from the first argument.
if [[ "$1" == *":"* ]]; then
  OPENROSDE_LAUNCH_PACKAGE="${1%%:*}"
  OPENROSDE_LAUNCH_FILE="${1#*:}"
else
  OPENROSDE_LAUNCH_FILE=$1
fi

# Forward the remaining arguments to 'roslaunch' (e.g., 'input_source:=sightline').
OPENROSDE_LAUNCH_ARGS="${*:2}"

if [ -z "${OPENROSDE_LAUNCH_FILE}" ]; then
  echo "No launch file is specified."
  exit 1
fi

################################################################################

OPENROSDE_PROMPT_START=$'\e[4m\e[1m'
OPENROSDE_PROMPT_END=$'\e[0m'
OPENROSDE_KEY_START=$'\e[7m'
OPENROSDE_KEY_END=$'\e[0m'${OPENROSDE_PROMPT_START}
OPENROSDE_PROMPT="${OPENROSDE_PROMPT_START}Run '${OPENROSDE_LAUNCH_FILE}${OPENROSDE_LAUNCH_ARGS:+ ${OPENROSDE_LAUNCH_ARGS}}'? Press:"$'\n'"'${OPENROSDE_KEY_START}r${OPENROSDE_KEY_END}' to run as remote,"$'\n'"'${OPENROSDE_KEY_START}l${OPENROSDE_KEY_END}' to run as local,"$'\n'"'${OPENROSDE_KEY_START}c${OPENROSDE_KEY_END}' to enter a child shell."$'\n'"${OPENROSDE_PROMPT_END}"

while true; do
  read -n 1 -s -p "${OPENROSDE_PROMPT}" input;
  if [ "${input}" = "r" ]; then
    remote_mode;
  elif [ "${input}" = "l" ]; then
    local_mode;
  elif [ "${input}" = "c" ]; then
    cat <<EOF

Starting a new shell process.
You will return to the above prompt when you exit from this shell.
Note: The new process does not inherit the mode ('remote_mode' or 'local_mode') from the previously executed 'roslaunch' process.

EOF
    bash -i
    continue;
  else
    continue;
  fi;
  roslaunch ${OPENROSDE_LAUNCH_PACKAGE} ${OPENROSDE_LAUNCH_FILE} ${OPENROSDE_LAUNCH_ARGS};
  echo "" # Display an empty line.
done

cat <<EOF

Starting a new shell process.
Note: The new process does not inherit the mode ('remote_mode' or 'local_mode') from the previously executed 'roslaunch' process.

EOF

exec bash -i
