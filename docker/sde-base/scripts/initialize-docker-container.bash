#!/bin/bash

# This script initializes the Docker container at startup by starting required services and keeping the container running in the background.
# It is referenced in 'docker-compose.yaml' and invoked when the container is (re)started.
#
# Usage: bash initialize-docker-container.bash

################################################################################

# Start the D-Bus daemon.
service dbus start

################################################################################

# Keep the Docker container running in the background.
# https://stackoverflow.com/questions/30209776/docker-container-will-automatically-stop-after-docker-run-d
tail -f /dev/null
