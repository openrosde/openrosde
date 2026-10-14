#!/bin/bash

# This script resolves where OpenRoSDE finds the files of the active platform and extensions, on the host and inside the Docker container alike.
# The core and every extension cloned into 'extensions/<extension>/' share one layout: 'env/', 'docker/', 'ros/', 'scripts/', 'terminator/', and 'patches/'.
# A file named after a setup or a platform is looked up in the core first, then in every cloned extension in alphabetical order.
# The Catkin workspaces and the Docker Compose overlays only come from the core, the platform, the extensions listed in 'OPENROSDE_ROBOT_EXTENSIONS', and the setup.
#
# Usage: source ./scripts/load-extension-paths.bash <openrosde-root-dir>
#
# <openrosde-root-dir>: Root directory of OpenRoSDE, '${OPENROSDE_ROOT_DIR}' on the host or '${OPENROSDE_CONTAINER_ROOT_DIR}' inside the Docker container.
#
# The script reads 'OPENROSDE_ROBOT_PLATFORM', 'OPENROSDE_ROBOT_SETUP', and 'OPENROSDE_ROBOT_EXTENSIONS', loaded from '.env' and '.env.custom', and defines:
# - 'OPENROSDE_SEARCH_ROOT_DIRS': the core, then every cloned extension, where files named after a setup or a platform are looked up.
# - 'OPENROSDE_ROBOT_PLATFORM_ROOT_DIR': the root directory that holds 'env/${OPENROSDE_ROBOT_PLATFORM}.env', the core or an extension.
# - 'OPENROSDE_ROBOT_SETUP_ROOT_DIR': the root directory that holds 'env/${OPENROSDE_ROBOT_SETUP}.env', the core or an extension.
# - 'OPENROSDE_ACTIVE_ROOT_DIRS': the core, the root directory of the platform, the extensions of 'OPENROSDE_ROBOT_EXTENSIONS' in their order, then the root directory of the setup.
# - 'OPENROSDE_CATKIN_WORKSPACE_DIRS': the Catkin workspaces to build and source, in that order.
# - 'openrosde-find-extension-file <relative-path>': prints the first match of '<relative-path>' in 'OPENROSDE_SEARCH_ROOT_DIRS'.
# - 'openrosde-find-setup-file <relative-path-pattern>': prints the first match of the pattern, where '%s' stands for the setup, then for the platform.
# - 'openrosde-find-platform-root-dir <robot-platform>': prints the root directory that holds 'env/<robot-platform>.env'.
#
# 'OPENROSDE_ROBOT_SETUP' falls back to the platform when its template does not run the active platform, as with a '.env.custom' written before setups existed.

################################################################################

# Store the root directory of OpenRoSDE given as argument.
OPENROSDE_LOOKUP_ROOT_DIR="$1"

################################################################################

# List the root directories where files named after a platform are looked up: the core first, then every cloned extension.
OPENROSDE_SEARCH_ROOT_DIRS=("${OPENROSDE_LOOKUP_ROOT_DIR}")
for OPENROSDE_EXTENSION_ROOT_DIR in "${OPENROSDE_LOOKUP_ROOT_DIR}"/extensions/*/; do
  if [ -d "${OPENROSDE_EXTENSION_ROOT_DIR}" ]; then
    OPENROSDE_SEARCH_ROOT_DIRS+=("${OPENROSDE_EXTENSION_ROOT_DIR%/}")
  fi
done

# Print the first match of a relative path in the search root directories.
function openrosde-find-extension-file () {
  local OPENROSDE_SEARCH_ROOT_DIR
  for OPENROSDE_SEARCH_ROOT_DIR in "${OPENROSDE_SEARCH_ROOT_DIRS[@]}"; do
    if [ -e "${OPENROSDE_SEARCH_ROOT_DIR}/$1" ]; then
      echo "${OPENROSDE_SEARCH_ROOT_DIR}/$1"
      return 0
    fi
  done
  return 1
}

# Print the root directory that holds the environment template of a platform, or the core if no root directory holds it.
function openrosde-find-platform-root-dir () {
  local OPENROSDE_PLATFORM_ENV_FILE
  OPENROSDE_PLATFORM_ENV_FILE="$(openrosde-find-extension-file "env/$1.env")"
  if [ -n "${OPENROSDE_PLATFORM_ENV_FILE}" ]; then
    dirname "$(dirname "${OPENROSDE_PLATFORM_ENV_FILE}")"
  else
    echo "${OPENROSDE_LOOKUP_ROOT_DIR}"
  fi
}

# Print the first match of a relative path pattern, where '%s' stands for the setup first, then for the platform.
function openrosde-find-setup-file () {
  openrosde-find-extension-file "$(printf "$1" "${OPENROSDE_ROBOT_SETUP}")" || openrosde-find-extension-file "$(printf "$1" "${OPENROSDE_ROBOT_PLATFORM}")"
}

################################################################################

# Find the root directory of the active platform.
OPENROSDE_ROBOT_PLATFORM_ROOT_DIR="$(openrosde-find-platform-root-dir "${OPENROSDE_ROBOT_PLATFORM}")"

# Use the platform as the setup when the setup template does not run the active platform, as with a '.env.custom' written before setups existed.
OPENROSDE_ROBOT_SETUP_ENV_FILE="$(openrosde-find-extension-file "env/${OPENROSDE_ROBOT_SETUP}.env")"
if [ -z "${OPENROSDE_ROBOT_SETUP_ENV_FILE}" ] || ! grep -qxF "OPENROSDE_ROBOT_PLATFORM=${OPENROSDE_ROBOT_PLATFORM}" "${OPENROSDE_ROBOT_SETUP_ENV_FILE}"; then
  OPENROSDE_ROBOT_SETUP="${OPENROSDE_ROBOT_PLATFORM}"
  OPENROSDE_ROBOT_SETUP_ENV_FILE="$(openrosde-find-extension-file "env/${OPENROSDE_ROBOT_SETUP}.env")"
fi

# Find the root directory of the active setup, the core if no root directory holds its template.
if [ -n "${OPENROSDE_ROBOT_SETUP_ENV_FILE}" ]; then
  OPENROSDE_ROBOT_SETUP_ROOT_DIR="$(dirname "$(dirname "${OPENROSDE_ROBOT_SETUP_ENV_FILE}")")"
else
  OPENROSDE_ROBOT_SETUP_ROOT_DIR="${OPENROSDE_LOOKUP_ROOT_DIR}"
fi

# List the active root directories: the core, the root directory of the platform, the extensions of 'OPENROSDE_ROBOT_EXTENSIONS' in their order, then the root directory of the setup.
OPENROSDE_ACTIVE_ROOT_DIRS=("${OPENROSDE_LOOKUP_ROOT_DIR}")
if [ "${OPENROSDE_ROBOT_PLATFORM_ROOT_DIR}" != "${OPENROSDE_LOOKUP_ROOT_DIR}" ]; then
  OPENROSDE_ACTIVE_ROOT_DIRS+=("${OPENROSDE_ROBOT_PLATFORM_ROOT_DIR}")
fi
for OPENROSDE_EXTENSION_NAME in ${OPENROSDE_ROBOT_EXTENSIONS}; do
  OPENROSDE_EXTENSION_ROOT_DIR="${OPENROSDE_LOOKUP_ROOT_DIR}/extensions/${OPENROSDE_EXTENSION_NAME}"
  if [ ! -d "${OPENROSDE_EXTENSION_ROOT_DIR}" ]; then
    echo "Warning: Extension '${OPENROSDE_EXTENSION_NAME}' of 'OPENROSDE_ROBOT_EXTENSIONS' is not cloned in 'extensions/${OPENROSDE_EXTENSION_NAME}/', skipping it." >&2
  elif [ "${OPENROSDE_EXTENSION_ROOT_DIR}" != "${OPENROSDE_ROBOT_PLATFORM_ROOT_DIR}" ] && [ "${OPENROSDE_EXTENSION_ROOT_DIR}" != "${OPENROSDE_ROBOT_SETUP_ROOT_DIR}" ]; then
    OPENROSDE_ACTIVE_ROOT_DIRS+=("${OPENROSDE_EXTENSION_ROOT_DIR}")
  fi
done
if [ "${OPENROSDE_ROBOT_SETUP_ROOT_DIR}" != "${OPENROSDE_LOOKUP_ROOT_DIR}" ] && [ "${OPENROSDE_ROBOT_SETUP_ROOT_DIR}" != "${OPENROSDE_ROBOT_PLATFORM_ROOT_DIR}" ]; then
  OPENROSDE_ACTIVE_ROOT_DIRS+=("${OPENROSDE_ROBOT_SETUP_ROOT_DIR}")
fi

################################################################################

# List the Catkin workspaces in the order they are built and sourced:
# 1. The shared workspace of the core.
# 2. The workspace of the platform.
# 3. Every other workspace of the platform root directory (if it is an extension), of the active extensions in their order, then of the setup.
# 4. The user workspace of the core, if it holds packages.
OPENROSDE_CATKIN_WORKSPACE_DIRS=("${OPENROSDE_LOOKUP_ROOT_DIR}/ros/openrosde_catkin_ws")
OPENROSDE_ROBOT_PLATFORM_CATKIN_WS="${OPENROSDE_ROBOT_PLATFORM_ROOT_DIR}/ros/${OPENROSDE_ROBOT_PLATFORM}_catkin_ws"
if [ -d "${OPENROSDE_ROBOT_PLATFORM_CATKIN_WS}" ]; then
  OPENROSDE_CATKIN_WORKSPACE_DIRS+=("${OPENROSDE_ROBOT_PLATFORM_CATKIN_WS}")
fi
for OPENROSDE_EXTENSION_ROOT_DIR in "${OPENROSDE_ACTIVE_ROOT_DIRS[@]:1}"; do
  for OPENROSDE_EXTENSION_CATKIN_WS in "${OPENROSDE_EXTENSION_ROOT_DIR}"/ros/*_catkin_ws; do
    if [ -d "${OPENROSDE_EXTENSION_CATKIN_WS}" ] && [ "${OPENROSDE_EXTENSION_CATKIN_WS}" != "${OPENROSDE_ROBOT_PLATFORM_CATKIN_WS}" ]; then
      OPENROSDE_CATKIN_WORKSPACE_DIRS+=("${OPENROSDE_EXTENSION_CATKIN_WS}")
    fi
  done
done
if [ -d "${OPENROSDE_LOOKUP_ROOT_DIR}/ros/user_catkin_ws/src" ]; then
  OPENROSDE_CATKIN_WORKSPACE_DIRS+=("${OPENROSDE_LOOKUP_ROOT_DIR}/ros/user_catkin_ws")
fi

# Clear the loop variables.
unset OPENROSDE_EXTENSION_ROOT_DIR OPENROSDE_EXTENSION_NAME OPENROSDE_EXTENSION_CATKIN_WS
