#!/bin/bash

# This script installs GitLab Runner, its dependencies on the host, and registers one runner instance to GitLab.com.
# Multiple executions of this script add multiple runner instances even though one runner is designed to start multiple executors.
# The generated configuration resides in '/etc/gitlab-runner/config.toml', where the amount of concurrent executors can also be set manually.
#
# Usage: bash SETUP-GITLAB-RUNNER.bash <gitlab-runner-registration-token>
#
# <gitlab-runner-registration-token>: To be retrieved from https://gitlab.com/ > Project > Settings > CI/CD > Runners.

################################################################################

# Check if the user has provided the mandatory <gitlab-runner-registration-token> argument.
if [[ "$#" -ne 1 ]]; then
  echo "Usage: bash SETUP-GITLAB-RUNNER.bash <gitlab-runner-registration-token>"
  exit 1
fi

################################################################################

# Install the OpenSSH server missing in the desktop flavors of Ubuntu.
sudo apt-get update
sudo apt-get install -y \
  openssh-server

################################################################################

# Install Docker Engine.
# https://docs.docker.com/engine/install/ubuntu/

# Remove obsolete or unofficial Docker packages and dependencies to avoid conflicts during installation.
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc
  do sudo apt-get remove $pkg
done

# Gather the required packages for Docker installation.
sudo apt-get update && sudo apt-get install -y \
  ca-certificates \
  curl

# Add the official Docker GPG key.
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the official Docker repository.
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

# Install the Docker Engine packages.
sudo apt-get update && sudo apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

# Test the Docker Engine installation.
sudo docker version
sudo docker compose version
sudo docker run --rm hello-world

################################################################################

# Add the current user to the 'docker' group to run Docker without 'sudo'.
# Logging out and back in is required for the group change to take effect.
sudo usermod -a -G docker ${USER}
echo "Added the current user '${USER}' to the 'docker' group."

################################################################################

# Install GitLab Runner.
# https://docs.gitlab.com/runner/
# https://docs.gitlab.com/runner/install/linux-repository.html

# Add the GitLab official repository.
curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | sudo bash

# Install GitLab Runner version 'GITLAB_RUNNER_VERSION'.
sudo apt-get update
sudo apt-get install -y \
  gitlab-runner

# Register a new runner to GitLab.com using the CLI interface.
# The configuration is generated into '/etc/gitlab-runner/config.toml'.
# For multiple executors on this runner, edit the executor variable in the configuration file.
# https://docs.gitlab.com/runner/register/index.html
# https://docs.gitlab.com/runner/register/index.html#one-line-registration-command
sudo gitlab-runner register \
  --non-interactive \
  --url "https://gitlab.com/" \
  --registration-token "$1" \
  --executor "docker" \
  --docker-privileged=true \
  --docker-image "alpine:latest" \
  --env "DOCKER_DRIVER=overlay2" \
  --env "DOCKER_TLS_CERTDIR=" \
  --description "${HOSTNAME}-${RANDOM}"

# Reload the 'gitlab-runner' configuration.
sudo killall -SIGHUP gitlab-runner

# Make sure that the OverlayFS driver is loaded on boot.
# https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#limitations-of-docker-in-docker
# https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#use-the-overlayfs-driver
sudo sh -c \
  'grep -q "overlay" /etc/modules \
  || echo "\n# Make sure OverlayFS driver is loaded on boot.\noverlay" >> /etc/modules'
