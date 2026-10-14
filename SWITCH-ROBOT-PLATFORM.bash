#!/bin/bash

# This script switches the active robot platform by switching to its default setup, its own environment template 'env/<platform>.env'.
# The template lives in 'env/' of the core or of an extension cloned into 'extensions/', and 'SWITCH-ROBOT-SETUP.bash' copies it to '.env.custom'.
#
# Usage: bash ./SWITCH-ROBOT-PLATFORM.bash <robot-platform>
#
# <robot-platform>: The target robot platform to switch to.
#                   Available platforms are found by name, as 'scripts/list-robot-platforms.bash' lists them.

################################################################################

# Resolve the repository root directory relative to this script.
SDE_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# List the available platforms, found by name.
SDE_AVAILABLE_PLATFORM_NAMES="$(bash "${SDE_ROOT_DIR}/scripts/list-robot-platforms.bash")"

# Validate the required argument.
if [ -z "$1" ]; then
  echo "Usage: bash ./SWITCH-ROBOT-PLATFORM.bash <robot-platform>"
  echo ""
  echo "Available platforms:"
  for SDE_PLATFORM_NAME in ${SDE_AVAILABLE_PLATFORM_NAMES}; do
    echo "  - ${SDE_PLATFORM_NAME}"
  done
  exit 1
fi

################################################################################

# Verify the platform is one of the available platforms.
if ! echo "${SDE_AVAILABLE_PLATFORM_NAMES}" | grep -qxF "$1"; then
  echo "Error: Platform '$1' not found."
  echo ""
  echo "Available platforms:"
  for SDE_PLATFORM_NAME in ${SDE_AVAILABLE_PLATFORM_NAMES}; do
    echo "  - ${SDE_PLATFORM_NAME}"
  done
  exit 1
fi

################################################################################

# Switch to the default setup of the platform, its own template, named after it.
bash "${SDE_ROOT_DIR}/SWITCH-ROBOT-SETUP.bash" "$1"
