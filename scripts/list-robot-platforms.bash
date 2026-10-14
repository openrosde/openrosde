#!/bin/bash

# This script lists the robot platforms that OpenRoSDE finds by name, in the core and in every extension cloned into 'extensions/', one per line, in alphabetical order.
# A platform named '<platform>' is found when its environment template 'env/<platform>.env' declares 'OPENROSDE_ROBOT_PLATFORM=<platform>'.
# The user overlay template 'env/user.env' declares no platform, so it is never listed.
#
# Usage: bash ./scripts/list-robot-platforms.bash

################################################################################

# Resolve the repository root directory relative to this script.
OPENROSDE_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

################################################################################

# Print the name of every environment template that declares its own platform, once even if several root directories hold it.
for OPENROSDE_ENV_FILE in "${OPENROSDE_ROOT_DIR}"/env/*.env "${OPENROSDE_ROOT_DIR}"/extensions/*/env/*.env; do
  OPENROSDE_PLATFORM_NAME="$(basename "${OPENROSDE_ENV_FILE}" .env)"
  if [ -f "${OPENROSDE_ENV_FILE}" ] && grep -qxF "OPENROSDE_ROBOT_PLATFORM=${OPENROSDE_PLATFORM_NAME}" "${OPENROSDE_ENV_FILE}"; then
    echo "${OPENROSDE_PLATFORM_NAME}"
  fi
done | sort -u
