#!/bin/bash

################################################################################

# Set up the system environment that requires 'sudo' privileges.
sudo -E bash INCL-SUDO-ENV.bash

################################################################################

# Set up the user environment that does not require 'sudo' privileges.
sudo bash INCL-USER-ENV.bash
