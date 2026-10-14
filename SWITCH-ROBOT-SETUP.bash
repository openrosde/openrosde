#!/bin/bash

# This script switches the active robot setup by copying its environment template to '.env.custom', after cloning the repositories the setup needs.
# A setup is an environment template 'env/<setup>.env' that declares 'OPENROSDE_ROBOT_SETUP=<setup>', in the core or in an extension cloned into 'extensions/'.
# The template of every platform is its default setup, named after the platform.
# If 'env/<setup>.repos' lies beside the template, 'vcs import' of 'vcstool' clones the repositories it lists into 'extensions/', skipping those already cloned.
#
# Usage: bash ./SWITCH-ROBOT-SETUP.bash <robot-setup>
#
# <robot-setup>: The target robot setup to switch to.
#                Available setups are found by name, as 'scripts/list-robot-setups.bash' lists them.

################################################################################

# Resolve the repository root directory relative to this script.
OPENROSDE_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Resolve where the files named after a setup or a platform live, in the core or in 'extensions/'.
source "${OPENROSDE_ROOT_DIR}/scripts/load-extension-paths.bash" "${OPENROSDE_ROOT_DIR}"

# List the available setups, found by name.
OPENROSDE_AVAILABLE_SETUP_NAMES="$(bash "${OPENROSDE_ROOT_DIR}/scripts/list-robot-setups.bash")"

# Validate the required argument.
if [ -z "$1" ]; then
  echo "Usage: bash ./SWITCH-ROBOT-SETUP.bash <robot-setup>"
  echo ""
  echo "Available setups:"
  for OPENROSDE_SETUP_NAME in ${OPENROSDE_AVAILABLE_SETUP_NAMES}; do
    echo "  - ${OPENROSDE_SETUP_NAME}"
  done
  exit 1
fi

################################################################################

# Verify the setup is one of the available setups.
if ! echo "${OPENROSDE_AVAILABLE_SETUP_NAMES}" | grep -qxF "$1"; then
  echo "Error: Setup '$1' not found."
  echo "Clone the extension that holds it into 'extensions/' first, as 'docs/extensions.md' explains."
  echo ""
  echo "Available setups:"
  for OPENROSDE_SETUP_NAME in ${OPENROSDE_AVAILABLE_SETUP_NAMES}; do
    echo "  - ${OPENROSDE_SETUP_NAME}"
  done
  exit 1
fi

################################################################################

# Clone the repositories that the setup lists in 'env/<setup>.repos' (if any) into 'extensions/', skipping those already cloned.
# https://github.com/dirk-thomas/vcstool
OPENROSDE_SETUP_ENV_FILE="$(openrosde-find-extension-file "env/$1.env")"
OPENROSDE_SETUP_REPOS_FILE="${OPENROSDE_SETUP_ENV_FILE%.env}.repos"
if [ -f "${OPENROSDE_SETUP_REPOS_FILE}" ]; then
  if ! command -v vcs > /dev/null 2>&1; then
    echo "Error: Setup '$1' lists its repositories in '${OPENROSDE_SETUP_REPOS_FILE#${OPENROSDE_ROOT_DIR}/}', which needs 'vcs' from 'vcstool'."
    echo "Install it with 'sudo apt-get install vcstool', as 'SETUP-DEVEL-MACHINE.bash' does."
    exit 1
  fi
  echo "Cloning the repositories of '$1' that are missing from 'extensions/'..."
  mkdir -p "${OPENROSDE_ROOT_DIR}/extensions"
  if ! vcs import --skip-existing --input "${OPENROSDE_SETUP_REPOS_FILE}" "${OPENROSDE_ROOT_DIR}/extensions"; then
    echo "Error: 'vcs import' failed, so the setup stays unchanged."
    exit 1
  fi
fi

################################################################################

# Copy the setup template to '.env.custom'.
cp "${OPENROSDE_SETUP_ENV_FILE}" "${OPENROSDE_ROOT_DIR}/.env.custom"
echo "Switched to '$1' setup."

################################################################################

# Update Git submodules and apply patches to ensure the workspace is in sync.
bash "${OPENROSDE_ROOT_DIR}/scripts/update-git-submodules.bash"
