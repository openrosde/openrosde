#!/bin/bash

# This script switches the active robot setup by copying its environment template to '.env.custom', after cloning the repositories the setup needs.
# A setup is an environment template 'env/<setup>.env' that declares 'OPENROSDE_ROBOT_SETUP=<setup>', in the core, in an extension cloned into 'extensions/', or in a part of an extension in 'extensions/<extension>/parts/'.
# The template of every platform is its default setup, named after the platform.
# If 'env/<setup>.repos' lies beside the template, 'vcs import' of 'vcstool' clones the repositories it lists into 'extensions/', skipping those already cloned, with a warning for every clone whose 'origin' points to another repository than the file, over HTTPS and SSH alike.
# The switch fails, and leaves the setup unchanged, when the platform of the setup or any name of its 'OPENROSDE_ROBOT_EXTENSIONS' does not resolve once the repositories are cloned.
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

# Print the host and the path of a Git URL, without its scheme, user, port, or trailing '.git', so that 'git@<host>:<path>.git', 'ssh://git@<host>/<path>', and 'https://<host>/<path>.git' compare equal.
function openrosde-normalize-repository-url () {
  echo "$1" | sed -E \
    -e 's#^[a-zA-Z][a-zA-Z0-9+.-]*://##' \
    -e 's#^[^@/]*@##' \
    -e 's#^([^/:]+):[0-9]*/#\1/#' \
    -e 's#^([^/:]+):#\1/#' \
    -e 's#/+$##' \
    -e 's#\.git$##' \
    | tr '[:upper:]' '[:lower:]'
}

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

  # Warn about every repository already cloned from another repository than the one the file lists, which 'vcs import --skip-existing' leaves at its old version, and print a command that would point it to the URL of the file.
  # A clone over SSH of the repository that the file lists over HTTPS, or the reverse, is the same repository, so it raises no warning.
  while read -r OPENROSDE_REPOSITORY_NAME OPENROSDE_REPOSITORY_URL; do
    OPENROSDE_REPOSITORY_DIR="${OPENROSDE_ROOT_DIR}/extensions/${OPENROSDE_REPOSITORY_NAME}"
    if [ -e "${OPENROSDE_REPOSITORY_DIR}/.git" ]; then
      OPENROSDE_REPOSITORY_ORIGIN_URL="$(git -C "${OPENROSDE_REPOSITORY_DIR}" remote get-url origin 2>/dev/null)"
      if [ -n "${OPENROSDE_REPOSITORY_ORIGIN_URL}" ] && [ "$(openrosde-normalize-repository-url "${OPENROSDE_REPOSITORY_ORIGIN_URL}")" != "$(openrosde-normalize-repository-url "${OPENROSDE_REPOSITORY_URL}")" ]; then
        echo "Warning: 'extensions/${OPENROSDE_REPOSITORY_NAME}/' is cloned from '${OPENROSDE_REPOSITORY_ORIGIN_URL}' rather than from '${OPENROSDE_REPOSITORY_URL}', which '${OPENROSDE_SETUP_REPOS_FILE#${OPENROSDE_ROOT_DIR}/}' lists, so 'vcs import' leaves it as it is."
        echo "If the clone should follow the file, point it there, over SSH instead if you clone over SSH, with: git -C '${OPENROSDE_REPOSITORY_DIR}' remote set-url origin '${OPENROSDE_REPOSITORY_URL}'"
      fi
    fi
  done < <(awk '/^  [^ #][^:]*:[[:space:]]*$/ { name = $1; sub(/:$/, "", name) } /^    url:/ { url = $2; gsub(/^["\047]|["\047]$/, "", url); print name, url }' "${OPENROSDE_SETUP_REPOS_FILE}")

  echo "Cloning the repositories of '$1' that are missing from 'extensions/'..."
  mkdir -p "${OPENROSDE_ROOT_DIR}/extensions"
  if ! vcs import --skip-existing --input "${OPENROSDE_SETUP_REPOS_FILE}" "${OPENROSDE_ROOT_DIR}/extensions"; then
    echo "Error: 'vcs import' failed, so the setup stays unchanged."
    exit 1
  fi
fi

################################################################################

# Check that the platform of the setup and every name of its 'OPENROSDE_ROBOT_EXTENSIONS' resolve, now that its repositories are cloned, so that a missing one fails here rather than later in Docker Compose or Catkin.
OPENROSDE_SETUP_PLATFORM_NAME="$(source "${OPENROSDE_SETUP_ENV_FILE}" > /dev/null 2>&1; echo "${OPENROSDE_ROBOT_PLATFORM}")"
OPENROSDE_SETUP_EXTENSION_NAMES="$(source "${OPENROSDE_SETUP_ENV_FILE}" > /dev/null 2>&1; echo "${OPENROSDE_ROBOT_EXTENSIONS}")"
if ! bash "${OPENROSDE_ROOT_DIR}/scripts/list-robot-platforms.bash" 2>/dev/null | grep -qxF "${OPENROSDE_SETUP_PLATFORM_NAME}"; then
  echo "Error: Platform '${OPENROSDE_SETUP_PLATFORM_NAME}' of setup '$1' is not found, so the setup stays unchanged."
  echo "Clone the extension that holds it into 'extensions/', or list it in 'env/$1.repos', as 'docs/extensions.md' explains."
  exit 1
fi
OPENROSDE_UNRESOLVED_EXTENSION_NAMES=""
for OPENROSDE_EXTENSION_NAME in ${OPENROSDE_SETUP_EXTENSION_NAMES}; do
  if ! openrosde-find-extension-root "${OPENROSDE_EXTENSION_NAME}" > /dev/null; then
    OPENROSDE_UNRESOLVED_EXTENSION_NAMES="${OPENROSDE_UNRESOLVED_EXTENSION_NAMES} '${OPENROSDE_EXTENSION_NAME}'"
  fi
done
if [ -n "${OPENROSDE_UNRESOLVED_EXTENSION_NAMES}" ]; then
  echo "Error: Extensions${OPENROSDE_UNRESOLVED_EXTENSION_NAMES} of setup '$1' do not resolve, so the setup stays unchanged."
  echo "Clone each into 'extensions/', or list it in 'env/$1.repos', as 'docs/extensions.md' explains."
  exit 1
fi

################################################################################

# Copy the setup template to '.env.custom'.
cp "${OPENROSDE_SETUP_ENV_FILE}" "${OPENROSDE_ROOT_DIR}/.env.custom"
echo "Switched to '$1' setup."

################################################################################

# Update Git submodules and apply patches to ensure the workspace is in sync.
bash "${OPENROSDE_ROOT_DIR}/scripts/update-git-submodules.bash"
