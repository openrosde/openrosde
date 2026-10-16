#!/bin/bash

# This script lists the robot platforms that OpenRoSDE finds by name, in the core, in every extension cloned into 'extensions/', and in every part of an extension in 'extensions/<extension>/parts/', one per line, in alphabetical order.
# A platform named '<platform>' is found when its environment template 'env/<platform>.env' declares 'OPENROSDE_ROBOT_PLATFORM=<platform>' alone on its line.
# The user overlay template 'env/user.env' declares no platform, so it is never listed.
# A platform that several templates declare is listed once, with a warning that names the template OpenRoSDE uses, the first one in the order of the core, then of every extension followed by its parts.
# A template whose 'OPENROSDE_ROBOT_PLATFORM=' line is quoted, indented, or carries a trailing comment is reported with an error, since OpenRoSDE reads that line as it is, and the script then ends with a failure status.
#
# Usage: bash ./scripts/list-robot-platforms.bash

################################################################################

# Resolve the repository root directory relative to this script.
OPENROSDE_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

################################################################################

# List the environment templates in the order OpenRoSDE looks them up: the core first, then every cloned extension, each followed by its parts.
OPENROSDE_ENV_FILES=("${OPENROSDE_ROOT_DIR}"/env/*.env)
for OPENROSDE_EXTENSION_ROOT_DIR in "${OPENROSDE_ROOT_DIR}"/extensions/*/; do
  OPENROSDE_ENV_FILES+=("${OPENROSDE_EXTENSION_ROOT_DIR}"env/*.env "${OPENROSDE_EXTENSION_ROOT_DIR}"parts/*/env/*.env)
done

# Collect the name and the template of every platform, from the first template that declares it, with a warning for every later one.
# Report every 'OPENROSDE_ROBOT_PLATFORM=' line that is not written as 'OPENROSDE_ROBOT_PLATFORM=<platform>' alone on its line.
OPENROSDE_PLATFORM_ENV_FILES=""
OPENROSDE_LISTING_EXIT_CODE=0
for OPENROSDE_ENV_FILE in "${OPENROSDE_ENV_FILES[@]}"; do
  if [ ! -f "${OPENROSDE_ENV_FILE}" ]; then
    continue
  fi
  OPENROSDE_PLATFORM_NAME="$(basename "${OPENROSDE_ENV_FILE}" .env)"
  OPENROSDE_UNREADABLE_LINE_NUMBERS="$(grep -nE '^[[:space:]]*(export[[:space:]]+)?OPENROSDE_ROBOT_PLATFORM=' "${OPENROSDE_ENV_FILE}" | grep -vE '^[0-9]+:OPENROSDE_ROBOT_PLATFORM=[A-Za-z0-9_.-]*$' | cut -d: -f1 | tr '\n' ' ')"
  if [ -n "${OPENROSDE_UNREADABLE_LINE_NUMBERS}" ]; then
    echo "Error: '${OPENROSDE_ENV_FILE#${OPENROSDE_ROOT_DIR}/}' declares 'OPENROSDE_ROBOT_PLATFORM' on line ${OPENROSDE_UNREADABLE_LINE_NUMBERS% } with quotes, spaces, or a trailing comment, which OpenRoSDE does not read: write it as 'OPENROSDE_ROBOT_PLATFORM=<platform>' alone on its line." >&2
    OPENROSDE_LISTING_EXIT_CODE=1
  fi
  if grep -qxF "OPENROSDE_ROBOT_PLATFORM=${OPENROSDE_PLATFORM_NAME}" "${OPENROSDE_ENV_FILE}"; then
    OPENROSDE_FIRST_ENV_FILE="$(printf '%s' "${OPENROSDE_PLATFORM_ENV_FILES}" | awk -v name="${OPENROSDE_PLATFORM_NAME}" '$1 == name { print substr($0, length(name) + 2); exit }')"
    if [ -n "${OPENROSDE_FIRST_ENV_FILE}" ]; then
      echo "Warning: Platform '${OPENROSDE_PLATFORM_NAME}' is declared by '${OPENROSDE_FIRST_ENV_FILE#${OPENROSDE_ROOT_DIR}/}' and by '${OPENROSDE_ENV_FILE#${OPENROSDE_ROOT_DIR}/}', and OpenRoSDE uses the first." >&2
    else
      OPENROSDE_PLATFORM_ENV_FILES="${OPENROSDE_PLATFORM_ENV_FILES}${OPENROSDE_PLATFORM_NAME} ${OPENROSDE_ENV_FILE}"$'\n'
    fi
  fi
done

################################################################################

# Print the platforms in alphabetical order.
printf '%s' "${OPENROSDE_PLATFORM_ENV_FILES}" | cut -d' ' -f1 | sort
exit ${OPENROSDE_LISTING_EXIT_CODE}
