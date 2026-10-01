#!/bin/bash

# This script installs GitLab Runner, its dependencies on the host, and registers one runner instance to GitLab.com.
# It follows the runner creation workflow of GitLab 16.0 and later: the runner is created in GitLab first, then registered here with its authentication token.
# The legacy registration tokens that earlier versions of this script used are deprecated, and where GitLab has them disabled, as GitLab 17.0 and later allow, registering with one fails with '410 Gone'.
# https://docs.gitlab.com/ci/runners/new_creation_workflow/
#
# The script can be run again safely: installed packages are kept, and a runner already registered with the same token is not registered twice.
# The generated configuration resides in '/etc/gitlab-runner/config.toml', where the amount of concurrent jobs is set from 'SDE_RUNNER_CONCURRENT'.
#
# Usage: bash SETUP-GITLAB-RUNNER.bash <gitlab-runner-authentication-token>
#
# <gitlab-runner-authentication-token>: Starts with 'glrt-'. Create the runner first at https://gitlab.com/ > Project > Settings > CI/CD > Runners > Create project runner,
#                                       or at the group level for every project of the group, with its tags, then copy the token GitLab shows once.
#
# SDE_RUNNER_CONCURRENT: Optional environment variable, the number of jobs the runner may run at once (default: 4).

################################################################################

# Check if the user has provided the mandatory <gitlab-runner-authentication-token> argument.
if [[ "$#" -ne 1 ]]; then
  echo "Usage: bash SETUP-GITLAB-RUNNER.bash <gitlab-runner-authentication-token>"
  exit 1
fi

# Refuse a legacy registration token, which this script no longer supports.
if [[ "$1" != glrt-* ]]; then
  echo "The token must be a runner authentication token starting with 'glrt-', created with the runner in GitLab."
  exit 1
fi

SDE_RUNNER_TOKEN="$1"
SDE_RUNNER_CONCURRENT="${SDE_RUNNER_CONCURRENT:-4}"
SDE_RUNNER_CONFIG="/etc/gitlab-runner/config.toml"

################################################################################

# Install the OpenSSH server missing in the desktop flavors of Ubuntu.
sudo apt-get update
sudo apt-get install -y \
  openssh-server

################################################################################

# Install Docker Engine, unless it is already installed from the official repository.
# https://docs.docker.com/engine/install/ubuntu/

if dpkg -s docker-ce > /dev/null 2>&1; then
  echo "Docker Engine is already installed, skipping its installation."
else

# Remove obsolete or unofficial Docker packages and dependencies to avoid conflicts during installation.
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc
  do sudo apt-get remove -y $pkg
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
sudo docker rmi hello-world

fi

################################################################################

# Add the current user to the 'docker' group to run Docker without 'sudo'.
# Logging out and back in is required for the group change to take effect.
sudo usermod -a -G docker ${USER}
echo "Added the current user '${USER}' to the 'docker' group."

################################################################################

# Install GitLab Runner.
# https://docs.gitlab.com/runner/
# https://docs.gitlab.com/runner/install/linux-repository.html

if command -v gitlab-runner > /dev/null 2>&1; then
  echo "GitLab Runner is already installed, skipping its installation."
else

# Add the GitLab official repository.
curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | sudo bash

# Install the latest GitLab Runner.
sudo apt-get update
sudo apt-get install -y \
  gitlab-runner

fi

# Register the runner to GitLab.com using the CLI interface, unless a runner with the same token is already registered on this host.
# The configuration is generated into '/etc/gitlab-runner/config.toml'.
# The description, tags, protection, and maximum timeout of the runner are set in GitLab when it is created, not here.
# The Docker executor runs privileged, which Docker-in-Docker needs and which gives every job root access to this host, so the host should run nothing but CI.
# https://docs.gitlab.com/runner/register/
# https://docs.gitlab.com/ci/docker/docker_in_docker/
if sudo test -f "${SDE_RUNNER_CONFIG}" && sudo grep -qF "${SDE_RUNNER_TOKEN}" "${SDE_RUNNER_CONFIG}"; then
  echo "A runner with this token is already registered on this host, skipping its registration."
else
  sudo gitlab-runner register \
    --non-interactive \
    --url "https://gitlab.com/" \
    --token "${SDE_RUNNER_TOKEN}" \
    --name "${HOSTNAME}" \
    --executor "docker" \
    --docker-privileged=true \
    --docker-image "docker:29.8.1-cli" \
    --docker-volumes "/cache" \
    --env "DOCKER_DRIVER=overlay2" \
    --env "DOCKER_TLS_CERTDIR="
fi

# Let the runner take as many jobs at once as 'SDE_RUNNER_CONCURRENT', so that the platform matrix builds in parallel.
sudo sed -i "s/^concurrent = .*/concurrent = ${SDE_RUNNER_CONCURRENT}/" "${SDE_RUNNER_CONFIG}"

# Reload the 'gitlab-runner' configuration.
sudo gitlab-runner restart

# Make sure that the OverlayFS driver is loaded on boot.
# https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#limitations-of-docker-in-docker
# https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#use-the-overlayfs-driver
sudo sh -c \
  'grep -q "overlay" /etc/modules \
  || echo "\n# Make sure OverlayFS driver is loaded on boot.\noverlay" >> /etc/modules'
