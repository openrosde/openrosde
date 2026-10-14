#!/bin/bash

# This script updates all Git submodules and applies any pending patch files, in the core and in every extension cloned into 'extensions/'.
# It is called by 'SETUP-DEVEL-MACHINE.bash' on initial setup and by 'SWITCH-ROBOT-PLATFORM.bash' on every platform switch.
#
# Usage: bash ./scripts/update-git-submodules.bash

################################################################################

# Resolve the OpenRoSDE root directory.
OPENROSDE_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

################################################################################

# Download and initialize all the Git submodules recursively, in the core and in every cloned extension.
# https://git-scm.com/book/en/v2/Git-Tools-Submodules
# Then apply the patches of each repository to its own Git submodules (if any).
for OPENROSDE_REPOSITORY_ROOT_DIR in "${OPENROSDE_ROOT_DIR}" "${OPENROSDE_ROOT_DIR}"/extensions/*; do
  if [ -e "${OPENROSDE_REPOSITORY_ROOT_DIR}/.git" ]; then
    git -C "${OPENROSDE_REPOSITORY_ROOT_DIR}" submodule update --init --recursive
    bash "${OPENROSDE_ROOT_DIR}/scripts/apply-submodule-patches.bash" "${OPENROSDE_REPOSITORY_ROOT_DIR}"
  fi
done
