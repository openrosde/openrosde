#!/bin/bash

# This script switches the active robot platform by copying the corresponding environment template from 'env/' to '.env.custom'.
#
# Usage: bash ./SWITCH-ROBOT-PLATFORM.bash <robot-platform>
#
# <robot-platform>: The target robot platform to switch to.
#                   Available platforms are found by name, as 'scripts/list-robot-platforms.bash' lists them.

################################################################################

# List the available platforms, found by name.
SDE_AVAILABLE_PLATFORM_NAMES="$(bash ./scripts/list-robot-platforms.bash)"

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

# Copy the platform template to '.env.custom'.
cp "./env/$1.env" ./.env.custom
echo "Switched to '$1' platform."

################################################################################

# Update Git submodules and apply patches to ensure the workspace is in sync.
bash ./scripts/update-git-submodules.bash
