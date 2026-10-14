#!/bin/bash

# This script lists the robot setups that OpenRoSDE finds by name, in the core and in every extension cloned into 'extensions/', one per line, in alphabetical order.
# A setup named '<setup>' is found when its environment template 'env/<setup>.env' declares 'OPENROSDE_ROBOT_SETUP=<setup>'.
# The template of every platform is its default setup, named after the platform, so a template that declares 'OPENROSDE_ROBOT_PLATFORM=<setup>' is listed too.
# The user overlay template 'env/user.env' declares neither, so it is never listed.
#
# Usage: bash ./scripts/list-robot-setups.bash

################################################################################

# Resolve the repository root directory relative to this script.
OPENROSDE_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

################################################################################

# Print the name of every environment template that declares its own setup or platform, once even if several root directories hold it.
for OPENROSDE_ENV_FILE in "${OPENROSDE_ROOT_DIR}"/env/*.env "${OPENROSDE_ROOT_DIR}"/extensions/*/env/*.env; do
  OPENROSDE_SETUP_NAME="$(basename "${OPENROSDE_ENV_FILE}" .env)"
  if [ -f "${OPENROSDE_ENV_FILE}" ] && grep -qxF -e "OPENROSDE_ROBOT_SETUP=${OPENROSDE_SETUP_NAME}" -e "OPENROSDE_ROBOT_PLATFORM=${OPENROSDE_SETUP_NAME}" "${OPENROSDE_ENV_FILE}"; then
    echo "${OPENROSDE_SETUP_NAME}"
  fi
done | sort -u
