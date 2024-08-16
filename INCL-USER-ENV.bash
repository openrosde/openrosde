#!/bin/bash

# This script sets up the local user environment without requiring 'sudo' or a system reboot or re-login to take effect.
# It is included in 'SETUP-DEVEL-MACHINE.bash' by default.
#
# Usage: bash INCL-USER-ENV.bash

################################################################################

# Download and initialize all the Git submodules recursively.
# https://git-scm.com/book/en/v2/Git-Tools-Submodules
git submodule update --init --recursive

################################################################################

# Setup the Bash shell environment with '~/.bashrc'.

# Force color prompt in terminal.
sed -i 's/#force_color_prompt=yes/force_color_prompt=yes/' ~/.bashrc
