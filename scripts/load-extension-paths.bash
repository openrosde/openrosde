#!/bin/bash

# This script resolves where the SDE finds the files of the active platform and extensions, on the host and inside the Docker container alike.
# The core and every extension cloned into 'extensions/<extension>/' share one layout: 'env/', 'docker/', 'ros/', 'scripts/', 'terminator/', and 'patches/'.
# A file named after a platform is looked up in the core first, then in every cloned extension in alphabetical order.
# The Catkin workspaces and the Docker Compose overlays only come from the core, the platform, and the extensions listed in 'SDE_ROBOT_EXTENSIONS'.
#
# Usage: source ./scripts/load-extension-paths.bash <sde-root-dir>
#
# <sde-root-dir>: Root directory of the SDE, '${SDE_ROOT_DIR}' on the host or '${SDE_CONTAINER_ROOT_DIR}' inside the Docker container.
#
# The script reads 'SDE_ROBOT_PLATFORM' and 'SDE_ROBOT_EXTENSIONS', loaded from '.env' and '.env.custom', and defines:
# - 'SDE_SEARCH_ROOT_DIRS': the core, then every cloned extension, where files named after a platform are looked up.
# - 'SDE_ROBOT_PLATFORM_ROOT_DIR': the root directory that holds 'env/${SDE_ROBOT_PLATFORM}.env', the core or an extension.
# - 'SDE_ACTIVE_ROOT_DIRS': the core, the root directory of the platform, then the extensions of 'SDE_ROBOT_EXTENSIONS' in their order.
# - 'SDE_CATKIN_WORKSPACE_DIRS': the Catkin workspaces to build and source, in that order.
# - 'sde-find-extension-file <relative-path>': prints the first match of '<relative-path>' in 'SDE_SEARCH_ROOT_DIRS'.
# - 'sde-find-platform-root-dir <robot-platform>': prints the root directory that holds 'env/<robot-platform>.env'.

################################################################################

# Store the root directory of the SDE given as argument.
SDE_LOOKUP_ROOT_DIR="$1"

################################################################################

# List the root directories where files named after a platform are looked up: the core first, then every cloned extension.
SDE_SEARCH_ROOT_DIRS=("${SDE_LOOKUP_ROOT_DIR}")
for SDE_EXTENSION_ROOT_DIR in "${SDE_LOOKUP_ROOT_DIR}"/extensions/*/; do
  if [ -d "${SDE_EXTENSION_ROOT_DIR}" ]; then
    SDE_SEARCH_ROOT_DIRS+=("${SDE_EXTENSION_ROOT_DIR%/}")
  fi
done

# Print the first match of a relative path in the search root directories.
function sde-find-extension-file () {
  local SDE_SEARCH_ROOT_DIR
  for SDE_SEARCH_ROOT_DIR in "${SDE_SEARCH_ROOT_DIRS[@]}"; do
    if [ -e "${SDE_SEARCH_ROOT_DIR}/$1" ]; then
      echo "${SDE_SEARCH_ROOT_DIR}/$1"
      return 0
    fi
  done
  return 1
}

# Print the root directory that holds the environment template of a platform, or the core if no root directory holds it.
function sde-find-platform-root-dir () {
  local SDE_PLATFORM_ENV_FILE
  SDE_PLATFORM_ENV_FILE="$(sde-find-extension-file "env/$1.env")"
  if [ -n "${SDE_PLATFORM_ENV_FILE}" ]; then
    dirname "$(dirname "${SDE_PLATFORM_ENV_FILE}")"
  else
    echo "${SDE_LOOKUP_ROOT_DIR}"
  fi
}

################################################################################

# Find the root directory of the active platform.
SDE_ROBOT_PLATFORM_ROOT_DIR="$(sde-find-platform-root-dir "${SDE_ROBOT_PLATFORM}")"

# List the active root directories: the core, the root directory of the platform, then the extensions of 'SDE_ROBOT_EXTENSIONS' in their order.
SDE_ACTIVE_ROOT_DIRS=("${SDE_LOOKUP_ROOT_DIR}")
if [ "${SDE_ROBOT_PLATFORM_ROOT_DIR}" != "${SDE_LOOKUP_ROOT_DIR}" ]; then
  SDE_ACTIVE_ROOT_DIRS+=("${SDE_ROBOT_PLATFORM_ROOT_DIR}")
fi
for SDE_EXTENSION_NAME in ${SDE_ROBOT_EXTENSIONS}; do
  SDE_EXTENSION_ROOT_DIR="${SDE_LOOKUP_ROOT_DIR}/extensions/${SDE_EXTENSION_NAME}"
  if [ ! -d "${SDE_EXTENSION_ROOT_DIR}" ]; then
    echo "Warning: Extension '${SDE_EXTENSION_NAME}' of 'SDE_ROBOT_EXTENSIONS' is not cloned in 'extensions/${SDE_EXTENSION_NAME}/', skipping it." >&2
  elif [ "${SDE_EXTENSION_ROOT_DIR}" != "${SDE_ROBOT_PLATFORM_ROOT_DIR}" ]; then
    SDE_ACTIVE_ROOT_DIRS+=("${SDE_EXTENSION_ROOT_DIR}")
  fi
done

################################################################################

# List the Catkin workspaces in the order they are built and sourced:
# 1. The shared workspace of the core.
# 2. The workspace of the platform.
# 3. Every other workspace of the platform root directory (if it is an extension) and of the active extensions, in their order.
# 4. The user workspace of the core, if it holds packages.
SDE_CATKIN_WORKSPACE_DIRS=("${SDE_LOOKUP_ROOT_DIR}/ros/sde_catkin_ws")
SDE_ROBOT_PLATFORM_CATKIN_WS="${SDE_ROBOT_PLATFORM_ROOT_DIR}/ros/${SDE_ROBOT_PLATFORM}_catkin_ws"
if [ -d "${SDE_ROBOT_PLATFORM_CATKIN_WS}" ]; then
  SDE_CATKIN_WORKSPACE_DIRS+=("${SDE_ROBOT_PLATFORM_CATKIN_WS}")
fi
for SDE_EXTENSION_ROOT_DIR in "${SDE_ACTIVE_ROOT_DIRS[@]:1}"; do
  for SDE_EXTENSION_CATKIN_WS in "${SDE_EXTENSION_ROOT_DIR}"/ros/*_catkin_ws; do
    if [ -d "${SDE_EXTENSION_CATKIN_WS}" ] && [ "${SDE_EXTENSION_CATKIN_WS}" != "${SDE_ROBOT_PLATFORM_CATKIN_WS}" ]; then
      SDE_CATKIN_WORKSPACE_DIRS+=("${SDE_EXTENSION_CATKIN_WS}")
    fi
  done
done
if [ -d "${SDE_LOOKUP_ROOT_DIR}/ros/user_catkin_ws/src" ]; then
  SDE_CATKIN_WORKSPACE_DIRS+=("${SDE_LOOKUP_ROOT_DIR}/ros/user_catkin_ws")
fi

# Clear the loop variables.
unset SDE_EXTENSION_ROOT_DIR SDE_EXTENSION_NAME SDE_EXTENSION_CATKIN_WS
