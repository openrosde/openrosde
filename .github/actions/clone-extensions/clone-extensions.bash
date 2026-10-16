#!/bin/bash

# This script clones the public extensions that 'gitlab-ci/extensions.repos' pins into 'extensions/' of the core checked out in the workspace, with 'gitlab-ci/clone-extensions.bash', in a job of GitHub Actions.
# It first gives the user of the runner the folder '/opt/vcs', where 'gitlab-ci/clone-extensions.bash' installs 'vcstool', since that user cannot write to '/opt', and installs 'python3-venv' when Python cannot create a virtual environment without it.
# When it is given the name of an extension under test, it removes the pinned clone of that extension afterwards, so that the job checks out the version under test in its place.
#
# Usage: bash ./.github/actions/clone-extensions/clone-extensions.bash [<extension-name>]
#
# [<extension-name>]: Folder of the extension under test in 'extensions/', such as 'openrosde-platform-ur5e', with letters, digits, and '_.-' alone.
#                     Default is none, which keeps every pinned clone.

################################################################################

# Name the root directory of the core, which the job checked out in the workspace.
OPENROSDE_ROOT_DIR="${GITHUB_WORKSPACE:-${PWD}}"

# Refuse the name of an extension that is not a plain folder name, since this script removes that folder.
if [ -n "$1" ] && { ! [[ "$1" =~ ^[A-Za-z0-9_.-]+$ ]] || [ "$1" = "." ] || [ "$1" = ".." ]; }; then
  echo "Error: The extension under test must be a folder name with letters, digits, and '_.-' alone, but it is '$1'."
  exit 1
fi

################################################################################

# Give the user of the runner the folder where 'gitlab-ci/clone-extensions.bash' installs 'vcstool', unless it can already write there.
if [ ! -w /opt/vcs ]; then
  sudo install -d -o "$(id -u)" -g "$(id -g)" /opt/vcs || exit 1
fi

# Install the virtual environments of Python, unless Python already has them.
if ! python3 -c 'import ensurepip, venv' > /dev/null 2>&1; then
  sudo apt-get update -qq && sudo apt-get install -y -qq python3-venv > /dev/null || exit 1
fi

# Clone the extensions at their pinned versions, anonymously, as every job of the GitLab pipeline does.
bash "${OPENROSDE_ROOT_DIR}/gitlab-ci/clone-extensions.bash" "${OPENROSDE_ROOT_DIR}/gitlab-ci/extensions.repos" || exit 1

################################################################################

# Remove the pinned clone of the extension under test, if the file lists it, so that the job checks out the version under test in its place.
if [ -n "$1" ] && [ -e "${OPENROSDE_ROOT_DIR}/extensions/$1" ]; then
  echo "Removing the pinned clone of '$1', which the version under test replaces."
  rm -rf "${OPENROSDE_ROOT_DIR:?}/extensions/$1" || exit 1
fi
