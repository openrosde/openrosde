#!/bin/bash

# This script loads the settings of OpenRoSDE inside the Docker container: the defaults of '.env', the user's '.env.custom', and where the files of the platform, the setup, and the extensions live.
# Every variable it sets is exported, so that a script that the shell runs, such as 'reset-catkin-workspaces.bash', reads the same platform, setup, and extensions.
# The functions of 'scripts/load-extension-paths.bash' stay in the shell that sources this script, since the arrays they read cannot be exported.
# It is sourced by 'docker/openrosde-base/scripts/initialize-bash-shell.bash' in every shell of the container, and by the CI scripts of 'gitlab-ci/' that run in a container.
#
# Usage: source ./scripts/load-openrosde-settings.bash <openrosde-root-dir>
#
# <openrosde-root-dir>: Root directory of OpenRoSDE, '${OPENROSDE_CONTAINER_ROOT_DIR}' inside the Docker container.

################################################################################

# Export every variable that the settings set.
set -a

# Load the default environment variables from the '.env' file:
source "$1/.env"

# Overwrite the default environment variables with the user's variables from the '.env.custom' file (if it exists):
source "$1/scripts/load-env-custom.bash" "$1"

# Resolve where the files of the platform, the setup, and the extensions live, and list their Catkin workspaces in order.
source "$1/scripts/load-extension-paths.bash" "$1"

# Stop exporting, and keep the functions of the loader out of the environment of other processes.
set +a
for OPENROSDE_LOADER_FUNCTION_NAME in $(compgen -A function openrosde-); do
  export -f -n "${OPENROSDE_LOADER_FUNCTION_NAME}"
done
unset OPENROSDE_LOADER_FUNCTION_NAME
