#!/bin/bash

# This script lists the robot platforms that the SDE finds by name, in the core and in every extension cloned into 'extensions/', one per line, in alphabetical order.
# A platform named '<platform>' is found when its environment template 'env/<platform>.env' declares 'SDE_ROBOT_PLATFORM=<platform>'.
# The user overlay template 'env/user.env' declares no platform, so it is never listed.
#
# Usage: bash ./scripts/list-robot-platforms.bash

################################################################################

# Resolve the repository root directory relative to this script.
SDE_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

################################################################################

# Print the name of every environment template that declares its own platform, once even if several root directories hold it.
for SDE_ENV_FILE in "${SDE_ROOT_DIR}"/env/*.env "${SDE_ROOT_DIR}"/extensions/*/env/*.env; do
  SDE_PLATFORM_NAME="$(basename "${SDE_ENV_FILE}" .env)"
  if [ -f "${SDE_ENV_FILE}" ] && grep -qxF "SDE_ROBOT_PLATFORM=${SDE_PLATFORM_NAME}" "${SDE_ENV_FILE}"; then
    echo "${SDE_PLATFORM_NAME}"
  fi
done | sort -u
