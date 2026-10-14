#!/bin/bash

# This script resolves where OpenRoSDE finds the files of the active platform, setup, and extensions, on the host and inside the Docker container alike.
# The core and every extension cloned into 'extensions/<extension>/' share one layout: 'env/', 'docker/', 'ros/', 'scripts/', 'tmux/', 'terminator/', and 'patches/'.
# An extension may also hold parts in 'extensions/<extension>/parts/<part>/', each with the same layout, so that one extension of a company holds the units of several robots, and each part is activated by its name like an extension.
# An environment template 'env/<name>.env' is looked up in the core first, then in every cloned extension followed by its parts, in alphabetical order.
# A file named after the setup comes from the folder of the setup, and a file named after the platform from the folder of the platform, then from the core, so a clone that is not active never supplies one.
# The Catkin workspaces, the Docker Compose overlays, and the 'tmux' panes only come from the core, the platform, the extensions listed in 'OPENROSDE_ROBOT_EXTENSIONS', and the setup.
#
# Usage: source ./scripts/load-extension-paths.bash <openrosde-root-dir>
#
# <openrosde-root-dir>: Root directory of OpenRoSDE, '${OPENROSDE_ROOT_DIR}' on the host or '${OPENROSDE_CONTAINER_ROOT_DIR}' inside the Docker container.
#
# The script reads 'OPENROSDE_ROBOT_PLATFORM', 'OPENROSDE_ROBOT_SETUP', and 'OPENROSDE_ROBOT_EXTENSIONS', loaded from '.env' and '.env.custom', and defines:
# - 'OPENROSDE_SEARCH_ROOT_DIRS': the core, then every cloned extension followed by its parts, where environment templates are looked up.
# - 'OPENROSDE_DECLARED_PLATFORM_NAMES' and 'OPENROSDE_DECLARED_SETUP_NAMES': the names that the templates of 'OPENROSDE_SEARCH_ROOT_DIRS' declare as their own platform or setup, each surrounded by spaces.
# - 'OPENROSDE_ROBOT_PLATFORM_ROOT_DIR': the root directory that holds 'env/${OPENROSDE_ROBOT_PLATFORM}.env', the core, an extension, or a part.
# - 'OPENROSDE_ROBOT_SETUP_ROOT_DIR': the root directory that holds 'env/${OPENROSDE_ROBOT_SETUP}.env', the core, an extension, or a part.
# - 'OPENROSDE_ACTIVE_ROOT_DIRS': the core, the root directory of the platform, the extensions or parts of 'OPENROSDE_ROBOT_EXTENSIONS' in their order, then the root directory of the setup.
# - 'OPENROSDE_CATKIN_WORKSPACE_DIRS': the Catkin workspaces to build and source, in that order.
# - 'OPENROSDE_COMPOSE_OVERLAY_FILES': the Docker Compose overlays of the platform, then of the active extensions and the setup, in that order.
# - 'OPENROSDE_TMUX_PANES_FILES': the pane files of the 'tmux' session, in the order their windows appear: the setup or else the platform, the active extensions and the setup, then the core.
# - 'openrosde-find-extension-file <relative-path>': prints the first match of '<relative-path>' in 'OPENROSDE_SEARCH_ROOT_DIRS'.
# - 'openrosde-find-extension-root <name>': prints the root directory of the extension 'extensions/<name>/' or of the single part 'extensions/<extension>/parts/<name>/', and fails when none or several hold it.
# - 'openrosde-find-setup-file <relative-path-pattern>': prints the first match of the pattern, where '%s' stands for the setup in its root directory, then for the platform in its root directory, then for either in the core.
# - 'openrosde-find-platform-root-dir <robot-platform>': prints the root directory that holds 'env/<robot-platform>.env'.
#
# 'OPENROSDE_ROBOT_SETUP' falls back to the platform when its template does not run the active platform, as with a '.env.custom' written before setups existed.

################################################################################

# Store the root directory of OpenRoSDE given as argument.
OPENROSDE_LOOKUP_ROOT_DIR="$1"

################################################################################

# List the root directories where the environment templates are looked up: the core first, then every cloned extension, each followed by its parts.
OPENROSDE_SEARCH_ROOT_DIRS=("${OPENROSDE_LOOKUP_ROOT_DIR}")
for OPENROSDE_EXTENSION_ROOT_DIR in "${OPENROSDE_LOOKUP_ROOT_DIR}"/extensions/*/; do
  if [ -d "${OPENROSDE_EXTENSION_ROOT_DIR}" ]; then
    OPENROSDE_SEARCH_ROOT_DIRS+=("${OPENROSDE_EXTENSION_ROOT_DIR%/}")
    for OPENROSDE_PART_ROOT_DIR in "${OPENROSDE_EXTENSION_ROOT_DIR}"parts/*/; do
      if [ -d "${OPENROSDE_PART_ROOT_DIR}" ]; then
        OPENROSDE_SEARCH_ROOT_DIRS+=("${OPENROSDE_PART_ROOT_DIR%/}")
      fi
    done
  fi
done

# Collect the names that the templates declare as their own platform, with the line 'OPENROSDE_ROBOT_PLATFORM=<platform>' in 'env/<platform>.env', or as their own setup, with the line 'OPENROSDE_ROBOT_SETUP=<setup>' in 'env/<setup>.env'.
# The lines are read here rather than with 'grep', since the loader runs in every shell of the Docker container.
OPENROSDE_DECLARED_PLATFORM_NAMES=" "
OPENROSDE_DECLARED_SETUP_NAMES=" "
for OPENROSDE_SEARCH_ROOT_DIR in "${OPENROSDE_SEARCH_ROOT_DIRS[@]}"; do
  for OPENROSDE_DECLARING_ENV_FILE in "${OPENROSDE_SEARCH_ROOT_DIR}"/env/*.env; do
    if [ ! -f "${OPENROSDE_DECLARING_ENV_FILE}" ]; then
      continue
    fi
    OPENROSDE_DECLARED_ENV_NAME="${OPENROSDE_DECLARING_ENV_FILE##*/}"
    OPENROSDE_DECLARED_ENV_NAME="${OPENROSDE_DECLARED_ENV_NAME%.env}"
    while IFS= read -r OPENROSDE_DECLARING_ENV_LINE || [ -n "${OPENROSDE_DECLARING_ENV_LINE}" ]; do
      if [ "${OPENROSDE_DECLARING_ENV_LINE}" = "OPENROSDE_ROBOT_PLATFORM=${OPENROSDE_DECLARED_ENV_NAME}" ] && [[ "${OPENROSDE_DECLARED_PLATFORM_NAMES}" != *" ${OPENROSDE_DECLARED_ENV_NAME} "* ]]; then
        OPENROSDE_DECLARED_PLATFORM_NAMES="${OPENROSDE_DECLARED_PLATFORM_NAMES}${OPENROSDE_DECLARED_ENV_NAME} "
      elif [ "${OPENROSDE_DECLARING_ENV_LINE}" = "OPENROSDE_ROBOT_SETUP=${OPENROSDE_DECLARED_ENV_NAME}" ] && [[ "${OPENROSDE_DECLARED_SETUP_NAMES}" != *" ${OPENROSDE_DECLARED_ENV_NAME} "* ]]; then
        OPENROSDE_DECLARED_SETUP_NAMES="${OPENROSDE_DECLARED_SETUP_NAMES}${OPENROSDE_DECLARED_ENV_NAME} "
      fi
    done < "${OPENROSDE_DECLARING_ENV_FILE}"
  done
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

# Print the root directory of the extension 'extensions/<name>/' or of the single part 'extensions/<extension>/parts/<name>/'.
# Fail with an error when no folder holds the name, or when several do, since a part is activated by its name alone.
function openrosde-find-extension-root () {
  local OPENROSDE_CANDIDATE_ROOT_DIR
  local OPENROSDE_MATCHING_ROOT_DIRS=()
  if [ -n "$1" ]; then
    for OPENROSDE_CANDIDATE_ROOT_DIR in "${OPENROSDE_LOOKUP_ROOT_DIR}/extensions/$1/" "${OPENROSDE_LOOKUP_ROOT_DIR}"/extensions/*/parts/"$1"/; do
      if [ -d "${OPENROSDE_CANDIDATE_ROOT_DIR}" ]; then
        OPENROSDE_MATCHING_ROOT_DIRS+=("${OPENROSDE_CANDIDATE_ROOT_DIR%/}")
      fi
    done
  fi
  if [ "${#OPENROSDE_MATCHING_ROOT_DIRS[@]}" -eq 1 ]; then
    echo "${OPENROSDE_MATCHING_ROOT_DIRS[0]}"
    return 0
  elif [ "${#OPENROSDE_MATCHING_ROOT_DIRS[@]}" -eq 0 ]; then
    echo "Error: Extension '$1' of 'OPENROSDE_ROBOT_EXTENSIONS' is cloned neither in 'extensions/$1/' nor as a part in 'extensions/<extension>/parts/$1/'." >&2
  else
    echo "Error: Extension '$1' of 'OPENROSDE_ROBOT_EXTENSIONS' is ambiguous, since several folders hold it:$(printf " '%s/'" "${OPENROSDE_MATCHING_ROOT_DIRS[@]#${OPENROSDE_LOOKUP_ROOT_DIR}/}")." >&2
  fi
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

# Print the first match of a relative path pattern, where '%s' stands for the setup in the root directory of the setup, then for the platform in the root directory of the platform, then for the setup and the platform in the core.
# Any other clone never supplies the file, even if it holds one of that name.
function openrosde-find-setup-file () {
  local OPENROSDE_SETUP_RELATIVE_PATH OPENROSDE_PLATFORM_RELATIVE_PATH OPENROSDE_CANDIDATE_FILE
  printf -v OPENROSDE_SETUP_RELATIVE_PATH "$1" "${OPENROSDE_ROBOT_SETUP}"
  printf -v OPENROSDE_PLATFORM_RELATIVE_PATH "$1" "${OPENROSDE_ROBOT_PLATFORM}"
  for OPENROSDE_CANDIDATE_FILE in \
    "${OPENROSDE_ROBOT_SETUP_ROOT_DIR}/${OPENROSDE_SETUP_RELATIVE_PATH}" \
    "${OPENROSDE_ROBOT_PLATFORM_ROOT_DIR}/${OPENROSDE_PLATFORM_RELATIVE_PATH}" \
    "${OPENROSDE_LOOKUP_ROOT_DIR}/${OPENROSDE_SETUP_RELATIVE_PATH}" \
    "${OPENROSDE_LOOKUP_ROOT_DIR}/${OPENROSDE_PLATFORM_RELATIVE_PATH}"; do
    if [ -e "${OPENROSDE_CANDIDATE_FILE}" ]; then
      echo "${OPENROSDE_CANDIDATE_FILE}"
      return 0
    fi
  done
  return 1
}

# Tell whether an active root directory other than the core contributes a file named '<name>', such as 'tmux/<name>.panes' or 'docker/docker-compose-<name>.yaml'.
# A file named after a platform or a setup that a template declares is only taken when it is named after the active setup and lies in the root directory of the setup, since the root directory of the platform, then the core, supply the files of the active platform.
# Every other file is taken, since one part is one unit.
function openrosde-select-extension-file () {
  if [ -n "$2" ] && [[ "${OPENROSDE_DECLARED_PLATFORM_NAMES}${OPENROSDE_DECLARED_SETUP_NAMES}" == *" $2 "* ]]; then
    [ "$2" = "${OPENROSDE_ROBOT_SETUP}" ] && [ "$1" = "${OPENROSDE_ROBOT_SETUP_ROOT_DIR}" ]
    return
  fi
  return 0
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

# List the active root directories: the core, the root directory of the platform, the extensions or parts of 'OPENROSDE_ROBOT_EXTENSIONS' in their order, then the root directory of the setup.
# A name that no folder or several folders hold is skipped, with the error of 'openrosde-find-extension-root'.
OPENROSDE_ACTIVE_ROOT_DIRS=("${OPENROSDE_LOOKUP_ROOT_DIR}")
if [ "${OPENROSDE_ROBOT_PLATFORM_ROOT_DIR}" != "${OPENROSDE_LOOKUP_ROOT_DIR}" ]; then
  OPENROSDE_ACTIVE_ROOT_DIRS+=("${OPENROSDE_ROBOT_PLATFORM_ROOT_DIR}")
fi
for OPENROSDE_EXTENSION_NAME in ${OPENROSDE_ROBOT_EXTENSIONS}; do
  OPENROSDE_EXTENSION_ROOT_DIR="$(openrosde-find-extension-root "${OPENROSDE_EXTENSION_NAME}")" || continue
  if [ "${OPENROSDE_EXTENSION_ROOT_DIR}" != "${OPENROSDE_ROBOT_PLATFORM_ROOT_DIR}" ] && [ "${OPENROSDE_EXTENSION_ROOT_DIR}" != "${OPENROSDE_ROBOT_SETUP_ROOT_DIR}" ]; then
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
# 3. Every other workspace of the platform root directory (if it is an extension or a part), of the active extensions and parts in their order, then of the setup.
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

################################################################################

# List the Docker Compose overlays that 'RUN-DOCKER-CONTAINER.bash' adds between 'docker/docker-compose.yaml' and 'docker/docker-compose-user.yaml' of the core:
# 1. The overlay of the platform, 'docker/docker-compose-<platform>.yaml' of the root directory of the platform, or else of the core.
# 2. Every other overlay of the platform root directory (if it is an extension or a part), of the active extensions and parts in their order, then of the setup, unless 'openrosde-select-extension-file' leaves it out.
OPENROSDE_COMPOSE_OVERLAY_FILES=()
for OPENROSDE_PLATFORM_COMPOSE_FILE in "${OPENROSDE_ROBOT_PLATFORM_ROOT_DIR}/docker/docker-compose-${OPENROSDE_ROBOT_PLATFORM}.yaml" "${OPENROSDE_LOOKUP_ROOT_DIR}/docker/docker-compose-${OPENROSDE_ROBOT_PLATFORM}.yaml"; do
  if [ -f "${OPENROSDE_PLATFORM_COMPOSE_FILE}" ]; then
    OPENROSDE_COMPOSE_OVERLAY_FILES+=("${OPENROSDE_PLATFORM_COMPOSE_FILE}")
    break
  fi
done
for OPENROSDE_EXTENSION_ROOT_DIR in "${OPENROSDE_ACTIVE_ROOT_DIRS[@]:1}"; do
  for OPENROSDE_EXTENSION_COMPOSE_FILE in "${OPENROSDE_EXTENSION_ROOT_DIR}"/docker/docker-compose*.yaml; do
    OPENROSDE_EXTENSION_FILE_NAME="${OPENROSDE_EXTENSION_COMPOSE_FILE##*/docker-compose}"
    OPENROSDE_EXTENSION_FILE_NAME="${OPENROSDE_EXTENSION_FILE_NAME%.yaml}"
    OPENROSDE_EXTENSION_FILE_NAME="${OPENROSDE_EXTENSION_FILE_NAME#-}"
    if [ -f "${OPENROSDE_EXTENSION_COMPOSE_FILE}" ] && [ "${OPENROSDE_EXTENSION_COMPOSE_FILE}" != "${OPENROSDE_PLATFORM_COMPOSE_FILE}" ] && openrosde-select-extension-file "${OPENROSDE_EXTENSION_ROOT_DIR}" "${OPENROSDE_EXTENSION_FILE_NAME}"; then
      OPENROSDE_COMPOSE_OVERLAY_FILES+=("${OPENROSDE_EXTENSION_COMPOSE_FILE}")
    fi
  done
done

# List the pane files of the 'tmux' session in the order their windows appear:
# 1. The panes of the setup, 'tmux/<setup>.panes', which replace those of the platform, 'tmux/<platform>.panes', as 'openrosde-find-setup-file' looks them up.
# 2. Every other pane file of the platform root directory (if it is an extension or a part), of the active extensions and parts in their order, then of the setup, unless 'openrosde-select-extension-file' leaves it out.
# 3. The panes of the core, 'tmux/openrosde.panes'.
OPENROSDE_TMUX_PANES_FILES=()
OPENROSDE_SETUP_PANES_FILE="$(openrosde-find-setup-file "tmux/%s.panes")"
if [ -n "${OPENROSDE_SETUP_PANES_FILE}" ]; then
  OPENROSDE_TMUX_PANES_FILES+=("${OPENROSDE_SETUP_PANES_FILE}")
fi
for OPENROSDE_EXTENSION_ROOT_DIR in "${OPENROSDE_ACTIVE_ROOT_DIRS[@]:1}"; do
  for OPENROSDE_EXTENSION_PANES_FILE in "${OPENROSDE_EXTENSION_ROOT_DIR}"/tmux/*.panes; do
    OPENROSDE_EXTENSION_FILE_NAME="${OPENROSDE_EXTENSION_PANES_FILE##*/}"
    OPENROSDE_EXTENSION_FILE_NAME="${OPENROSDE_EXTENSION_FILE_NAME%.panes}"
    if [ -f "${OPENROSDE_EXTENSION_PANES_FILE}" ] && [ "${OPENROSDE_EXTENSION_PANES_FILE}" != "${OPENROSDE_SETUP_PANES_FILE}" ] && openrosde-select-extension-file "${OPENROSDE_EXTENSION_ROOT_DIR}" "${OPENROSDE_EXTENSION_FILE_NAME}"; then
      OPENROSDE_TMUX_PANES_FILES+=("${OPENROSDE_EXTENSION_PANES_FILE}")
    fi
  done
done
OPENROSDE_TMUX_PANES_FILES+=("${OPENROSDE_LOOKUP_ROOT_DIR}/tmux/openrosde.panes")

# Clear the loop variables.
unset OPENROSDE_EXTENSION_ROOT_DIR OPENROSDE_PART_ROOT_DIR OPENROSDE_EXTENSION_NAME OPENROSDE_EXTENSION_CATKIN_WS
unset OPENROSDE_SEARCH_ROOT_DIR OPENROSDE_DECLARING_ENV_FILE OPENROSDE_DECLARED_ENV_NAME OPENROSDE_DECLARING_ENV_LINE
unset OPENROSDE_PLATFORM_COMPOSE_FILE OPENROSDE_EXTENSION_COMPOSE_FILE OPENROSDE_EXTENSION_PANES_FILE OPENROSDE_EXTENSION_FILE_NAME OPENROSDE_SETUP_PANES_FILE
