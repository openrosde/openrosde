#!/bin/bash

# This script checks that no script that the CI runs can move a robot, as part of the CI.
# It fails on any 'roslaunch' that does more than resolve files, list nodes, or dump parameters, with '--files', '--nodes', or '--dump-params', and on any 'rosrun', 'rostopic pub', or 'rosservice call'.
# A 'roslaunch' may still start a launch file of a simulation that the allowlist of its folder names, 'allowed-simulation-launches.txt', with one launch file name per line.
# It reads every file of the given folders, apart from itself and the allowlists, leaves out the comment lines, and splits every other line into the commands that ';', '&&', '||', and '|' separate.
# It reads text only, so a program that the scripts call, such as a Python node, is left to the review of the folder that holds it, and to the containers of the CI, which have no network when a check runs.
#
# Usage: bash ./gitlab-ci/check-no-motion.bash <dir> [<dir> ...]
#
# <dir>: Folder of scripts that the CI runs, such as 'gitlab-ci' of the core or 'ci' of an extension.
#        A folder that does not exist is skipped, so that a pattern such as 'extensions/*/ci' that matches no folder passes.

################################################################################

# Resolve the path of this script, which names every command it looks for, so that it skips itself.
OPENROSDE_NO_MOTION_SCRIPT_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

# Name the patterns of the commands, as whole words, and of the options of 'roslaunch' that start no node.
OPENROSDE_WORD_START_PATTERN='(^|[^[:alnum:]_./-])'
OPENROSDE_WORD_END_PATTERN='([^[:alnum:]_.-]|$)'
OPENROSDE_MOVING_COMMAND_PATTERN="${OPENROSDE_WORD_START_PATTERN}(rosrun|rostopic[[:space:]]+pub|rosservice[[:space:]]+call)${OPENROSDE_WORD_END_PATTERN}"
OPENROSDE_ROSLAUNCH_PATTERN="${OPENROSDE_WORD_START_PATTERN}roslaunch${OPENROSDE_WORD_END_PATTERN}"
OPENROSDE_SAFE_OPTION_PATTERN='[[:space:]]--(files|nodes|dump-params)([[:space:]=]|$)'
OPENROSDE_LAUNCH_FILE_PATTERN="([^[:space:]\"':/]+\\.launch)([[:space:]\"';)]|$)"

################################################################################

# Check every command of every file of every folder, and report each command that could move a robot.
OPENROSDE_MOTION_REPORT=""
OPENROSDE_CHECKED_FILE_COUNT=0
for OPENROSDE_CHECKED_DIR in "$@"; do
  if [ ! -d "${OPENROSDE_CHECKED_DIR}" ]; then
    echo "Skipping '${OPENROSDE_CHECKED_DIR}', which is not a folder."
    continue
  fi

  # Read the launch files of simulations that the folder allows.
  OPENROSDE_ALLOWED_LAUNCH_FILES=""
  if [ -f "${OPENROSDE_CHECKED_DIR%/}/allowed-simulation-launches.txt" ]; then
    OPENROSDE_ALLOWED_LAUNCH_FILES="$(grep -v -e '^#' -e '^ *$' "${OPENROSDE_CHECKED_DIR%/}/allowed-simulation-launches.txt" | awk '{ print $1 }')"
  fi

  while IFS= read -r -d '' OPENROSDE_CHECKED_FILE; do
    if [ "$(cd "$(dirname "${OPENROSDE_CHECKED_FILE}")" && pwd)/$(basename "${OPENROSDE_CHECKED_FILE}")" = "${OPENROSDE_NO_MOTION_SCRIPT_FILE}" ] || [ "$(basename "${OPENROSDE_CHECKED_FILE}")" = "allowed-simulation-launches.txt" ]; then
      continue
    fi
    OPENROSDE_CHECKED_FILE_COUNT=$((OPENROSDE_CHECKED_FILE_COUNT + 1))
    OPENROSDE_LINE_NUMBER=0
    while IFS= read -r OPENROSDE_CHECKED_LINE || [ -n "${OPENROSDE_CHECKED_LINE}" ]; do
      OPENROSDE_LINE_NUMBER=$((OPENROSDE_LINE_NUMBER + 1))
      if [[ "${OPENROSDE_CHECKED_LINE}" =~ ^[[:space:]]*# ]]; then
        continue
      fi
      # Split the line into its commands, then check each one.
      OPENROSDE_CHECKED_COMMANDS="${OPENROSDE_CHECKED_LINE//&&/$'\n'}"
      OPENROSDE_CHECKED_COMMANDS="${OPENROSDE_CHECKED_COMMANDS//||/$'\n'}"
      OPENROSDE_CHECKED_COMMANDS="${OPENROSDE_CHECKED_COMMANDS//;/$'\n'}"
      OPENROSDE_CHECKED_COMMANDS="${OPENROSDE_CHECKED_COMMANDS//|/$'\n'}"
      while IFS= read -r OPENROSDE_CHECKED_COMMAND; do
        OPENROSDE_MOVING_COMMAND=""
        if [[ "${OPENROSDE_CHECKED_COMMAND}" =~ ${OPENROSDE_MOVING_COMMAND_PATTERN} ]]; then
          OPENROSDE_MOVING_COMMAND="${BASH_REMATCH[2]}"
        elif [[ "${OPENROSDE_CHECKED_COMMAND}" =~ ${OPENROSDE_ROSLAUNCH_PATTERN} ]] && ! [[ "${OPENROSDE_CHECKED_COMMAND}" =~ ${OPENROSDE_SAFE_OPTION_PATTERN} ]]; then
          OPENROSDE_MOVING_COMMAND="roslaunch"
          if [[ "${OPENROSDE_CHECKED_COMMAND}" =~ ${OPENROSDE_LAUNCH_FILE_PATTERN} ]] && [ -n "${OPENROSDE_ALLOWED_LAUNCH_FILES}" ] && printf '%s\n' "${OPENROSDE_ALLOWED_LAUNCH_FILES}" | grep -q -x -F -e "${BASH_REMATCH[1]}"; then
            OPENROSDE_MOVING_COMMAND=""
          fi
        fi
        if [ -n "${OPENROSDE_MOVING_COMMAND}" ]; then
          OPENROSDE_MOTION_REPORT="${OPENROSDE_MOTION_REPORT}"$'\n'"  - ${OPENROSDE_CHECKED_FILE}:${OPENROSDE_LINE_NUMBER}: '${OPENROSDE_MOVING_COMMAND}' in: $(echo "${OPENROSDE_CHECKED_COMMAND}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
        fi
      done <<< "${OPENROSDE_CHECKED_COMMANDS}"
    done < "${OPENROSDE_CHECKED_FILE}"
  done < <(find "${OPENROSDE_CHECKED_DIR}" -type f ! -path '*/.git/*' -print0 | sort -z)
done

################################################################################

# Report the result, and fail if any command could move a robot.
echo "Checked ${OPENROSDE_CHECKED_FILE_COUNT} files for commands that could move a robot."
if [ -n "${OPENROSDE_MOTION_REPORT}" ]; then
  echo "These commands could start a node or move a robot, and only 'roslaunch' of a simulation that 'allowed-simulation-launches.txt' of its folder names may:${OPENROSDE_MOTION_REPORT}"
  exit 1
fi
