#!/bin/bash

# This script applies patch files from 'patches/' to Git submodules after initialization.
# The directory structure under 'patches/' mirrors the submodule path in the repository.
# Patch files are named with a numbered prefix and three kebab-case words starting with a verb.
# After applying each patch, all files touched by it are marked 'skip-worktree' so they
# do not appear as tracked changes in 'git status' or VS Code's source control panel.
#
# Usage: source ./scripts/apply-submodule-patches.bash
#
# To create a patch: make changes in the submodule, run 'git diff > <patch-file>'.
# Then reset the submodule with 'git checkout .'.

################################################################################

# Resolve the SDE root directory.
SDE_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SDE_PATCHES_DIR="${SDE_ROOT_DIR}/patches"

################################################################################

# Apply all patch files found in the 'patches/' directory tree.
find "${SDE_PATCHES_DIR}" -name '*.patch' -type f | sort | while read SDE_PATCH_FILE; do
  # Derive the submodule path from the patch file's parent directory relative to 'patches/'.
  SDE_SUBMODULE_PATH=$(dirname "${SDE_PATCH_FILE#${SDE_PATCHES_DIR}/}")
  SDE_PATCH_BASENAME=$(basename "${SDE_PATCH_FILE}")

  # Verify that the submodule directory exists.
  if [ ! -d "${SDE_ROOT_DIR}/${SDE_SUBMODULE_PATH}" ]; then
    echo "Warning: Submodule directory '${SDE_SUBMODULE_PATH}' not found, skipping '${SDE_PATCH_BASENAME}'."
    continue
  fi

  # Apply the patch (skip if already applied).
  echo "Applying patch '${SDE_PATCH_BASENAME}' to '${SDE_SUBMODULE_PATH}'..."
  if git -C "${SDE_ROOT_DIR}/${SDE_SUBMODULE_PATH}" apply --check "${SDE_PATCH_FILE}" 2>/dev/null; then
    git -C "${SDE_ROOT_DIR}/${SDE_SUBMODULE_PATH}" apply "${SDE_PATCH_FILE}"
    echo "Successfully applied '${SDE_PATCH_BASENAME}'."
  else
    echo "Patch '${SDE_PATCH_BASENAME}' already applied or conflicts detected, skipping."
  fi

  # Mark all files touched by this patch as 'skip-worktree' so that patched files
  # do not appear as tracked changes in VS Code or 'git status' output.
  git -C "${SDE_ROOT_DIR}/${SDE_SUBMODULE_PATH}" apply --numstat "${SDE_PATCH_FILE}" 2>/dev/null \
    | awk '{print $3}' \
    | xargs git -C "${SDE_ROOT_DIR}/${SDE_SUBMODULE_PATH}" update-index --skip-worktree 2>/dev/null
done
