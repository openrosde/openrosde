#!/bin/bash

# This script sets up the development environment by installing tools including Docker (with Docker Compose), Nvidia Container Toolkit, and Terminator.
# The script is divided into two parts:
# 1. 'INCL-SUDO-ENV.bash' which performs the system-wide installations with 'sudo' and requires a system reboot or re-login to take effect.
# 2. 'INCL-USER-ENV.bash' which sets up the local user environment without requiring 'sudo' or a system reboot or re-login to take effect.
#
# Usage: bash SETUP-DEVEL-MACHINE.bash

################################################################################

# Set up the system environment with 'sudo' privileges.
sudo -E bash INCL-SUDO-ENV.bash

################################################################################

# Set up the user environment without 'sudo' privileges.
bash INCL-USER-ENV.bash
