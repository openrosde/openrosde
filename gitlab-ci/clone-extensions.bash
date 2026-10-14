#!/bin/bash

# This script clones the public extensions that the CI of OpenRoSDE tests into 'extensions/', at the versions that a '.repos' file of 'vcstool' pins, then applies their patches, as part of the CI.
# The generate job and every job of the child pipeline run it from the same file, so that every job sees the same extensions without handing them over as an artifact.
# A pipeline that a public extension triggers to test one of its branches names it in 'OPENROSDE_CI_EXTENSION_OVERRIDE=<name>=<branch>@<commit>', which checks out that commit of that branch in place of the pinned version, for an extension the file already lists only.
# Every repository is cloned anonymously over HTTPS, with the Git configuration of the machine left out, so that no token of the job, such as 'CI_JOB_TOKEN', can give a public pipeline access to a private repository.
# 'vcstool' is installed in a virtual environment of Python in '/opt/vcs', with 'setuptools' below version 81, which 'vcstool' 0.3.0 still needs, only when the file lists a repository.
#
# Usage: bash ./gitlab-ci/clone-extensions.bash <repos-file>
#
# <repos-file>: File of 'vcstool' that lists the extensions, such as 'gitlab-ci/extensions.repos', each with an anonymous HTTPS 'url' and a 'version' pinned to a tag or a commit.

################################################################################

# Resolve the repository root directory relative to this script.
OPENROSDE_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Check that the file of the repositories exists.
if [ ! -f "$1" ]; then
  echo "Error: The file of the extensions '$1' does not exist."
  exit 1
fi

# List the names of the repositories, the keys indented by two spaces under 'repositories:', each cloned into 'extensions/<name>/'.
OPENROSDE_CI_EXTENSION_NAMES="$(sed -n 's/^  \([A-Za-z0-9_.-]*\):[[:space:]]*$/\1/p' "$1")"

################################################################################

# Read the override of one extension, '<name>=<branch>@<commit>', and refuse a name that the file does not list, a malformed branch, or anything but a commit hash.
OPENROSDE_CI_OVERRIDE_NAME=""
if [ -n "${OPENROSDE_CI_EXTENSION_OVERRIDE}" ]; then
  OPENROSDE_CI_OVERRIDE_NAME="${OPENROSDE_CI_EXTENSION_OVERRIDE%%=*}"
  OPENROSDE_CI_OVERRIDE_BRANCH="${OPENROSDE_CI_EXTENSION_OVERRIDE#*=}"
  OPENROSDE_CI_OVERRIDE_COMMIT="${OPENROSDE_CI_OVERRIDE_BRANCH##*@}"
  OPENROSDE_CI_OVERRIDE_BRANCH="${OPENROSDE_CI_OVERRIDE_BRANCH%@*}"
  if ! printf '%s\n' ${OPENROSDE_CI_EXTENSION_NAMES} | grep -qxF -e "${OPENROSDE_CI_OVERRIDE_NAME}"; then
    echo "Error: 'OPENROSDE_CI_EXTENSION_OVERRIDE' names the extension '${OPENROSDE_CI_OVERRIDE_NAME}', which '$1' does not list, and only a listed extension can be tested at another version."
    exit 1
  fi
  if ! [[ "${OPENROSDE_CI_OVERRIDE_BRANCH}" =~ ^[A-Za-z0-9][A-Za-z0-9._/-]*$ ]] || [[ "${OPENROSDE_CI_OVERRIDE_BRANCH}" == *..* ]] || ! [[ "${OPENROSDE_CI_OVERRIDE_COMMIT}" =~ ^[0-9a-f]{40}$ ]]; then
    echo "Error: 'OPENROSDE_CI_EXTENSION_OVERRIDE' must read '<name>=<branch>@<commit>', with the full hash of the commit, but it is '${OPENROSDE_CI_EXTENSION_OVERRIDE}'."
    exit 1
  fi
fi

# Stop here when the file lists no repository, so that a pipeline without extensions installs nothing.
if [ -z "${OPENROSDE_CI_EXTENSION_NAMES}" ]; then
  echo "No extension to clone: '$1' lists no repository."
  exit 0
fi

# Refuse a URL that is not anonymous HTTPS, such as one that carries a user name or a token, or one over SSH.
OPENROSDE_CI_REFUSED_URLS="$(sed -n 's/^    url:[[:space:]]*//p' "$1" | grep -vE '^https://[^/@[:space:]]+/[^@[:space:]]+$')"
if [ -n "${OPENROSDE_CI_REFUSED_URLS}" ]; then
  echo "Error: '$1' lists URLs that are not anonymous HTTPS, which the CI does not clone:"
  echo "${OPENROSDE_CI_REFUSED_URLS}" | sed 's/^/  - /'
  exit 1
fi

################################################################################

# Install 'vcstool' in a virtual environment of Python, with Python itself on the Alpine image of the Docker CLI, unless an earlier run installed it.
if [ ! -x /opt/vcs/bin/vcs ]; then
  if ! command -v python3 > /dev/null 2>&1 && command -v apk > /dev/null 2>&1; then
    apk add --no-cache python3 > /dev/null || exit 1
  fi
  python3 -m venv /opt/vcs && /opt/vcs/bin/pip install --quiet --disable-pip-version-check vcstool==0.3.0 'setuptools<81' || exit 1
fi

# Run Git and 'vcstool' without the Git configuration of the machine and without any token of the job, so that a clone is always anonymous, and never prompt for a password.
function openrosde-ci-run-anonymously () {
  env -u CI_JOB_TOKEN -u CI_REGISTRY_PASSWORD GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null GIT_TERMINAL_PROMPT=0 PYTHONWARNINGS=ignore "$@"
}

# Clone the repositories, or bring the existing clones to the pinned versions, with their Git submodules.
mkdir -p "${OPENROSDE_ROOT_DIR}/extensions"
openrosde-ci-run-anonymously /opt/vcs/bin/vcs import --recursive --input "$1" "${OPENROSDE_ROOT_DIR}/extensions" || exit 1

# Check out the commit of the override, which must belong to its branch, with its Git submodules.
if [ -n "${OPENROSDE_CI_OVERRIDE_NAME}" ]; then
  OPENROSDE_CI_OVERRIDE_DIR="${OPENROSDE_ROOT_DIR}/extensions/${OPENROSDE_CI_OVERRIDE_NAME}"
  echo "Checking out '${OPENROSDE_CI_OVERRIDE_COMMIT}' of the branch '${OPENROSDE_CI_OVERRIDE_BRANCH}' of '${OPENROSDE_CI_OVERRIDE_NAME}'..."
  openrosde-ci-run-anonymously git -C "${OPENROSDE_CI_OVERRIDE_DIR}" fetch --quiet origin "refs/heads/${OPENROSDE_CI_OVERRIDE_BRANCH}" || exit 1
  if ! git -C "${OPENROSDE_CI_OVERRIDE_DIR}" merge-base --is-ancestor "${OPENROSDE_CI_OVERRIDE_COMMIT}" FETCH_HEAD 2>/dev/null; then
    echo "Error: The commit '${OPENROSDE_CI_OVERRIDE_COMMIT}' is not on the branch '${OPENROSDE_CI_OVERRIDE_BRANCH}' of '${OPENROSDE_CI_OVERRIDE_NAME}'."
    exit 1
  fi
  git -C "${OPENROSDE_CI_OVERRIDE_DIR}" checkout --quiet --detach "${OPENROSDE_CI_OVERRIDE_COMMIT}" || exit 1
  openrosde-ci-run-anonymously git -C "${OPENROSDE_CI_OVERRIDE_DIR}" submodule update --quiet --init --recursive || exit 1
fi

################################################################################

# Apply the patches of every clone and of every part of a clone to their own Git submodules.
for OPENROSDE_CI_PATCHED_ROOT_DIR in "${OPENROSDE_ROOT_DIR}"/extensions/*/ "${OPENROSDE_ROOT_DIR}"/extensions/*/parts/*/; do
  if [ -d "${OPENROSDE_CI_PATCHED_ROOT_DIR}patches" ]; then
    bash "${OPENROSDE_ROOT_DIR}/scripts/apply-submodule-patches.bash" "${OPENROSDE_CI_PATCHED_ROOT_DIR%/}"
  fi
done

# Print the commit of every clone, so that the log of the job tells what it tested.
for OPENROSDE_CI_EXTENSION_NAME in ${OPENROSDE_CI_EXTENSION_NAMES}; do
  echo "Cloned '${OPENROSDE_CI_EXTENSION_NAME}' at '$(git -C "${OPENROSDE_ROOT_DIR}/extensions/${OPENROSDE_CI_EXTENSION_NAME}" rev-parse HEAD)'."
done
