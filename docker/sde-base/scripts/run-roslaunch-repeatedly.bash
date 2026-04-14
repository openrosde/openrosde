#!/bin/bash

# This script runs a ROS launch file and prompts the user to select the execution mode (remote, local, or child shell).
# It is used by Terminator sub-terminals to conveniently preload launch files.
#
# Usage: bash run-roslaunch-repeatedly.bash <launch-file>
#
# <launch-file>: The ROS launch file to run (e.g., 'example_roslaunch_file.launch').
#                Optionally, specify the ROS package with the 'package:file.launch' format.
#                If no package is specified, the 'SDE_LAUNCH_PACKAGE' environment variable is used.

################################################################################

# Parse the optional 'package:file.launch' format from the argument.
if [[ "$1" == *":"* ]]; then
  SDE_LAUNCH_PACKAGE="${1%%:*}"
  SDE_LAUNCH_FILE="${1#*:}"
else
  SDE_LAUNCH_FILE=$1
fi

if [ -z "${SDE_LAUNCH_FILE}" ]; then
  echo "No launch file is specified."
  exit 1
fi

################################################################################

SDE_PROMPT_START=$'\e[4m\e[1m'
SDE_PROMPT_END=$'\e[0m'
SDE_KEY_START=$'\e[7m'
SDE_KEY_END=$'\e[0m'${SDE_PROMPT_START}
SDE_PROMPT="${SDE_PROMPT_START}Run '${SDE_LAUNCH_FILE}'? Press:"$'\n'"'${SDE_KEY_START}r${SDE_KEY_END}' to run as remote,"$'\n'"'${SDE_KEY_START}l${SDE_KEY_END}' to run as local,"$'\n'"'${SDE_KEY_START}c${SDE_KEY_END}' to enter a child shell."$'\n'"${SDE_PROMPT_END}"

while true; do
  read -n 1 -s -p "${SDE_PROMPT}" input;
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
  roslaunch ${SDE_LAUNCH_PACKAGE} ${SDE_LAUNCH_FILE};
  echo "" # Display an empty line.
done

cat <<EOF

Starting a new shell process.
Note: The new process does not inherit the mode ('remote_mode' or 'local_mode') from the previously executed 'roslaunch' process.

EOF

exec bash -i
