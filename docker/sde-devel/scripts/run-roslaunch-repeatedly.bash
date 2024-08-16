#!/bin/bash

################################################################################

LAUNCH_FILE=$1

if [ -z "${LAUNCH_FILE}" ]; then
  echo "No launch file is specified."
  exit 1
fi

################################################################################

PROMPT_START=$'\e[4m\e[1m'
PROMPT_END=$'\e[0m'
KEY_START=$'\e[7m'
KEY_END=$'\e[0m'${PROMPT_START}
PROMPT="${PROMPT_START}Run '${LAUNCH_FILE}'? Press:"$'\n'"'${KEY_START}r${KEY_END}' to run as remote,"$'\n'"'${KEY_START}l${KEY_END}' to run as local,"$'\n'"'${KEY_START}c${KEY_END}' to enter a child shell."$'\n'"${PROMPT_END}"

while true; do
  read -n 1 -s -p "${PROMPT}" input;
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
  echo "ROS_MASTER_URI: ${ROS_MASTER_URI}";
  roslaunch sde_launch ${LAUNCH_FILE};
  echo "" # Display an empty line.
done

cat <<EOF

Starting a new shell process.
Note: The new process does not inherit the mode ('remote_mode' or 'local_mode') from the previously executed 'roslaunch' process.

EOF

exec bash -i
