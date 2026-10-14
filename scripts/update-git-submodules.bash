#!/bin/bash

# This script updates all Git submodules and applies any pending patch files, in the core and in every extension cloned into 'extensions/'.
# It is called by 'SETUP-DEVEL-MACHINE.bash' on initial setup and by 'SWITCH-ROBOT-PLATFORM.bash' on every platform switch.
#
# Usage: bash ./scripts/update-git-submodules.bash

################################################################################

# Resolve the SDE root directory.
SDE_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

################################################################################

# Download and initialize all the Git submodules recursively, in the core and in every cloned extension.
# https://git-scm.com/book/en/v2/Git-Tools-Submodules
# Then apply the patches of each repository to its own Git submodules (if any).
for SDE_REPOSITORY_ROOT_DIR in "${SDE_ROOT_DIR}" "${SDE_ROOT_DIR}"/extensions/*; do
  if [ -e "${SDE_REPOSITORY_ROOT_DIR}/.git" ]; then
    git -C "${SDE_REPOSITORY_ROOT_DIR}" submodule update --init --recursive
    bash "${SDE_ROOT_DIR}/scripts/apply-submodule-patches.bash" "${SDE_REPOSITORY_ROOT_DIR}"
  fi
done
