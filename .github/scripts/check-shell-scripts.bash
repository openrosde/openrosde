#!/bin/bash

# This script checks the shell scripts of the repository with ShellCheck, run from its Docker image pinned by digest, as part of the CI.
# The scripts of '.github/' must pass every check, while the other scripts committed to the repository must pass the checks of the severity 'error', since they were written before this check and still raise warnings.
# It reads the scripts from the Git index, so the extensions cloned into 'extensions/' and the Git submodules are left to their own repositories.
#
# Usage: bash ./.github/scripts/check-shell-scripts.bash

################################################################################

# Resolve the repository root directory relative to this script.
OPENROSDE_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Name the image of ShellCheck, pinned by the digest of its index of architectures.
OPENROSDE_CI_SHELLCHECK_IMAGE="koalaman/shellcheck:v0.11.0@sha256:61862eba1fcf09a484ebcc6feea46f1782532571a34ed51fedf90dd25f925a8d"

# Run ShellCheck on the given scripts, relative to the repository root, which it reads without writing.
function openrosde-ci-run-shellcheck () {
  docker run --rm --network none --volume "${OPENROSDE_ROOT_DIR}:/mnt:ro" --workdir /mnt "${OPENROSDE_CI_SHELLCHECK_IMAGE}" --format=gcc "$@"
}

################################################################################

# List the committed scripts, and those of '.github/' apart.
mapfile -d '' OPENROSDE_CI_SCRIPT_FILES < <(git -C "${OPENROSDE_ROOT_DIR}" ls-files -z -- '*.bash' '*.sh')
mapfile -d '' OPENROSDE_CI_GITHUB_SCRIPT_FILES < <(git -C "${OPENROSDE_ROOT_DIR}" ls-files -z -- '.github/*.bash' '.github/*.sh')
if [ "${#OPENROSDE_CI_SCRIPT_FILES[@]}" -eq 0 ]; then
  echo "Error: Git lists no shell script in '${OPENROSDE_ROOT_DIR}'."
  exit 1
fi

# Check every script for errors, and the scripts of '.github/' for every finding, and report both results.
OPENROSDE_CI_EXIT_CODE=0
echo "Checking ${#OPENROSDE_CI_SCRIPT_FILES[@]} scripts for errors..."
openrosde-ci-run-shellcheck --severity=error "${OPENROSDE_CI_SCRIPT_FILES[@]}" || OPENROSDE_CI_EXIT_CODE=1
if [ "${#OPENROSDE_CI_GITHUB_SCRIPT_FILES[@]}" -gt 0 ]; then
  echo "Checking ${#OPENROSDE_CI_GITHUB_SCRIPT_FILES[@]} scripts of '.github/' for every finding..."
  openrosde-ci-run-shellcheck --severity=style "${OPENROSDE_CI_GITHUB_SCRIPT_FILES[@]}" || OPENROSDE_CI_EXIT_CODE=1
fi
if [ "${OPENROSDE_CI_EXIT_CODE}" -eq 0 ]; then
  echo "ShellCheck found nothing."
fi
exit ${OPENROSDE_CI_EXIT_CODE}
