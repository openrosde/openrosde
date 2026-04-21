#!/bin/bash

# This script switches the active robot platform by copying the corresponding
# environment template from 'env/' to '.env.custom'.
#
# Usage: bash ./SWITCH-ROBOT-PLATFORM.bash <robot-platform>
#
# <robot-platform>: The target robot platform to switch to.
#                   Available platforms are listed in the 'env/' directory.

################################################################################

# Validate the required argument.
if [ -z "$1" ]; then
  echo "Usage: bash ./SWITCH-ROBOT-PLATFORM.bash <robot-platform>"
  echo ""
  echo "Available platforms:"
  for SDE_ENV_FILE in ./env/*.env; do
    echo "  - $(basename "${SDE_ENV_FILE}" .env)"
  done
  exit 1
fi

################################################################################

# Verify the platform template exists.
if [ ! -f "./env/$1.env" ]; then
  echo "Error: Platform template 'env/$1.env' not found."
  echo ""
  echo "Available platforms:"
  for SDE_ENV_FILE in ./env/*.env; do
    echo "  - $(basename "${SDE_ENV_FILE}" .env)"
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
