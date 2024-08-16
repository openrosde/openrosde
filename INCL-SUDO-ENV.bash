#!/bin/bash

# This script performs the system-wide installations with 'sudo' and requires a system reboot or re-login to take effect.
# It is included in 'SETUP-DEVEL-MACHINE.bash' by default.
#
# Usage: bash INCL-SUDO-ENV.bash

################################################################################

# Pass the 'sudo' privileges if previously granted in parent scripts.
if [ ! -z "$SUDO_USER" ]; then
  export USER=$SUDO_USER
fi

################################################################################

# Install Docker Engine.
# https://docs.docker.com/engine/install/ubuntu/

# Remove obsolete or unofficial Docker packages and dependencies to avoid conflicts during installation.
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc
  do apt-get remove $pkg
done

# Gather the required packages for Docker installation.
apt-get update && apt-get install -y \
  ca-certificates \
  curl

# Add the official Docker GPG key.
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add the official Docker repository.
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install the Docker Engine packages.
apt-get update && apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

# Test the Docker Engine installation.
docker version
docker compose version
docker run --rm hello-world

################################################################################

# Add the current user to the 'docker' group to run Docker without 'sudo'.
# Logging out and back in is required for the group change to take effect.
usermod -a -G docker ${USER}
echo "Added the current user '${USER}' to the 'docker' group."

################################################################################

# Install Nvidia Container Toolkit (that replaced Nvidia Docker 2).
# https://github.com/NVIDIA/nvidia-container-toolkit
# https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html

# Remove 'nvidia-docker' and all existing GPU containers.
docker volume ls -q -f driver=nvidia-docker | xargs -r -I{} -n1 docker ps -q -a -f volume={} | xargs -r docker rm -f
apt-get purge -y nvidia-docker

# Add the 'nvidia-container-toolkit' repositories.
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --yes --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
&& curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

# Install 'nvidia-container-toolkit' packages.
apt-get update && apt-get install -y \
  nvidia-container-toolkit

# Test the 'nvidia-container-toolkit' installation if Nvidia drivers are found.
if [ -e /proc/driver/nvidia/version ]; then
  docker run --gpus all --rm nvidia/cuda:11.2.2-base-ubuntu20.04 nvidia-smi
fi

################################################################################

# Install Terminator terminal.
# https://gnometerminator.blogspot.com/

# Install the latest version of Terminator from the Ubuntu repositories.
apt-get update && apt-get install -y \
  terminator

# Prevent the Terminator installation to replace the default Ubuntu terminal.
update-alternatives --set x-terminal-emulator /usr/bin/gnome-terminal.wrapper
