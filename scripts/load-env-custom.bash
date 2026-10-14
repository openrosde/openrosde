#!/bin/bash

# This script overwrites the default environment variables with the user's variables from the '.env.custom' file, if it exists.
# A '.env.custom' written before the SDE became OpenRoSDE names its variables 'SDE_*', so their values are copied to the 'OPENROSDE_*' names, with a warning that says how to rename them for good.
# It is sourced by 'scripts/load-openrosde-env.bash' on the host and by 'initialize-bash-shell.bash' inside the container.
#
# Usage: source ./scripts/load-env-custom.bash <root-dir>
#
# <root-dir>: The root directory of OpenRoSDE, which holds '.env.custom'.

################################################################################

if [ -f "$1/.env.custom" ]; then
  source "$1/.env.custom"

  # Copy the value of every old 'SDE_*' variable to its 'OPENROSDE_*' name.
  OPENROSDE_OLD_VARIABLES="$(grep -o '^SDE_[A-Za-z0-9_]*' "$1/.env.custom")"
  if [ -n "${OPENROSDE_OLD_VARIABLES}" ]; then
    for OPENROSDE_OLD_VARIABLE in ${OPENROSDE_OLD_VARIABLES}; do
      printf -v "OPENROSDE_${OPENROSDE_OLD_VARIABLE#SDE_}" '%s' "${!OPENROSDE_OLD_VARIABLE}"
    done
    echo "Warning: '.env.custom' still names its variables 'SDE_*', which OpenRoSDE now reads as 'OPENROSDE_*'." >&2
    echo "Rename them for good with: sed -i 's/^SDE_/OPENROSDE_/' '$1/.env.custom'" >&2
  fi
  unset OPENROSDE_OLD_VARIABLES OPENROSDE_OLD_VARIABLE
fi
