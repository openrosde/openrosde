#!/bin/bash

# This script sets up the development environment by installing tools including Docker (with Docker Compose), Nvidia Container Toolkit, and Terminator.
# The script is divided into two parts:
# 1. System-wide installations with 'sudo' that require a system reboot or re-login to take effect.
# 2. Local user environment setup without requiring 'sudo' or a system reboot or re-login to take effect.
#
# Usage: bash ./SETUP-DEVEL-MACHINE.bash

################################################################################
# System-wide installations (requires 'sudo').
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
docker version
docker compose version
docker run --rm hello-world
docker rmi hello-world

################################################################################

# Add the current user to the 'docker' group to run Docker without 'sudo'.
# Logging out and back in is required for the group change to take effect.
sudo usermod -a -G docker ${USER}
echo "Added the current user '${USER}' to the 'docker' group."

################################################################################

# Install Nvidia Container Toolkit (that replaced Nvidia Docker 2).
# https://github.com/NVIDIA/nvidia-container-toolkit
# https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html

# Remove 'nvidia-docker' and all existing GPU containers.
docker volume ls -q -f driver=nvidia-docker | xargs -r -I{} -n1 docker ps -q -a -f volume={} | xargs -r docker rm -f
sudo apt-get purge -y nvidia-docker

# Add the 'nvidia-container-toolkit' repositories.
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --yes --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
&& curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

# Install 'nvidia-container-toolkit' packages.
sudo apt-get update && sudo apt-get install -y \
  nvidia-container-toolkit

# Test the 'nvidia-container-toolkit' installation if Nvidia drivers are found.
if [ -e /proc/driver/nvidia/version ]; then
  # Configure Docker to use the Nvidia Container Runtime.
  sudo nvidia-ctk runtime configure --runtime=docker
  sudo systemctl restart docker
  docker run --gpus all --rm nvidia/cuda:11.2.2-base-ubuntu20.04 nvidia-smi
  docker rmi nvidia/cuda:11.2.2-base-ubuntu20.04
fi

################################################################################

# Install Terminator terminal.
# https://gnometerminator.blogspot.com/

# Install the latest version of Terminator from the Ubuntu repositories.
sudo apt-get update && sudo apt-get install -y \
  terminator

# Prevent the Terminator installation to replace the default Ubuntu terminal.
if [ -e /usr/bin/gnome-terminal.wrapper ]; then
  sudo update-alternatives --set x-terminal-emulator /usr/bin/gnome-terminal.wrapper
fi

################################################################################

# Install 'vcstool', which clones the repositories that a setup lists in its '.repos' file into 'extensions/'.
# https://github.com/dirk-thomas/vcstool
sudo apt-get update && sudo apt-get install -y \
  vcstool

################################################################################
# Local user environment setup (no 'sudo' required).
################################################################################

# Download, initialize, and patch all the Git submodules recursively.
bash ./scripts/update-git-submodules.bash

################################################################################

# Setup the Bash shell environment with '~/.bashrc'.

# Force color prompt in terminal.
sed -i 's/#force_color_prompt=yes/force_color_prompt=yes/' ~/.bashrc
