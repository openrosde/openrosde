#!/bin/bash

# This script updates all Git submodules and applies any pending patch files.
# It is called by 'SETUP-DEVEL-MACHINE.bash' on initial setup and by 'SWITCH-ROBOT-PLATFORM.bash' on every platform switch.
#
# Usage: bash ./scripts/update-git-submodules.bash

################################################################################

# Resolve the SDE root directory.
SDE_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

################################################################################

# Download and initialize all the Git submodules recursively.
# https://git-scm.com/book/en/v2/Git-Tools-Submodules
git -C "${SDE_ROOT_DIR}" submodule update --init --recursive

# Apply patches to the Git submodules (if any).
source "${SDE_ROOT_DIR}/scripts/apply-submodule-patches.bash"
