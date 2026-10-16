#!/bin/bash

# This script frees disk space on a GitHub-hosted Ubuntu runner before a job of OpenRoSDE builds or pulls the large Docker images, such as the base image of ROS 1.
# It removes the preinstalled toolchains that no job of OpenRoSDE uses, prunes the images and the build cache of Docker, and moves the storage of Docker and containerd to the temporary disk '/mnt' when that disk has more free space than the root disk.
# Every step checks the state it changes first, so the script runs again safely, and the script changes nothing unless 'RUNNER_ENVIRONMENT' is 'github-hosted', so that it never removes anything from a self-hosted runner or a development machine.
#
# Usage: bash ./.github/actions/free-disk-space/free-disk-space.bash [<docker-on-mnt>]
#
# [<docker-on-mnt>]: 'true' to move the storage of Docker and containerd to '/mnt' when it has more free space than the root disk, or 'false' to keep it on the root disk.
#                    Default value is 'true'.

################################################################################

OPENROSDE_CI_DOCKER_ON_MNT="${1:-true}"

# Refuse to run anywhere but on a GitHub-hosted runner, which GitHub discards after the job.
if [ "${RUNNER_ENVIRONMENT}" != "github-hosted" ]; then
  echo "Skipping the cleanup, which runs only on a GitHub-hosted runner, while 'RUNNER_ENVIRONMENT' is '${RUNNER_ENVIRONMENT}'."
  exit 0
fi

echo "Free disk space before the cleanup:"
df -h / /mnt 2> /dev/null

################################################################################

# Remove the preinstalled toolchains that no job of OpenRoSDE uses, each only when it is present.
for OPENROSDE_CI_UNUSED_DIR in /usr/share/dotnet /usr/local/lib/android /opt/ghc /usr/local/.ghcup /opt/hostedtoolcache/CodeQL; do
  if [ -e "${OPENROSDE_CI_UNUSED_DIR}" ]; then
    echo "Removing '${OPENROSDE_CI_UNUSED_DIR}'..."
    sudo rm -rf "${OPENROSDE_CI_UNUSED_DIR}" || exit 1
  fi
done

# Remove the images and the build cache that Docker holds before the job, which no job uses.
docker image prune --all --force > /dev/null || exit 1
docker builder prune --all --force > /dev/null || exit 1

################################################################################

# Move the storage of Docker and containerd to '/mnt' when it is a disk of its own with more free space than the root disk.
# Bind mounts keep the paths of the storage, so they serve the classic image store of Docker and the image store of containerd alike.
# The services stop first, so that nothing writes to the storage while it moves, and the state left after the prune is copied, so that Docker starts again as it was.
if [ "${OPENROSDE_CI_DOCKER_ON_MNT}" = "true" ] && mountpoint -q /mnt; then
  OPENROSDE_CI_ROOT_FREE_KB="$(df --output=avail / | tail -n 1 | tr -d ' ')"
  OPENROSDE_CI_MNT_FREE_KB="$(df --output=avail /mnt | tail -n 1 | tr -d ' ')"
  OPENROSDE_CI_MOVED_DIRS=()
  for OPENROSDE_CI_STORAGE_DIR in /var/lib/docker /var/lib/containerd; do
    if [ -d "${OPENROSDE_CI_STORAGE_DIR}" ] && ! mountpoint -q "${OPENROSDE_CI_STORAGE_DIR}"; then
      OPENROSDE_CI_MOVED_DIRS+=("${OPENROSDE_CI_STORAGE_DIR}")
    fi
  done
  if [ "${OPENROSDE_CI_MNT_FREE_KB}" -le "${OPENROSDE_CI_ROOT_FREE_KB}" ]; then
    echo "Keeping the storage of Docker on the root disk, which has more free space than '/mnt'."
  elif [ "${#OPENROSDE_CI_MOVED_DIRS[@]}" -eq 0 ]; then
    echo "The storage of Docker is already on '/mnt'."
  else
    OPENROSDE_CI_CONTAINERD_ACTIVE=false
    if systemctl is-active --quiet containerd.service; then
      OPENROSDE_CI_CONTAINERD_ACTIVE=true
    fi
    sudo systemctl stop docker.socket docker.service || exit 1
    if [ "${OPENROSDE_CI_CONTAINERD_ACTIVE}" = "true" ]; then
      sudo systemctl stop containerd.service || exit 1
    fi
    for OPENROSDE_CI_STORAGE_DIR in "${OPENROSDE_CI_MOVED_DIRS[@]}"; do
      OPENROSDE_CI_MNT_STORAGE_DIR="/mnt/openrosde-ci${OPENROSDE_CI_STORAGE_DIR}"
      sudo mkdir -p "${OPENROSDE_CI_MNT_STORAGE_DIR}" || exit 1
      sudo cp -a "${OPENROSDE_CI_STORAGE_DIR}/." "${OPENROSDE_CI_MNT_STORAGE_DIR}/" || exit 1
      sudo mount --bind "${OPENROSDE_CI_MNT_STORAGE_DIR}" "${OPENROSDE_CI_STORAGE_DIR}" || exit 1
      echo "Moved '${OPENROSDE_CI_STORAGE_DIR}' to '${OPENROSDE_CI_MNT_STORAGE_DIR}'."
    done
    if [ "${OPENROSDE_CI_CONTAINERD_ACTIVE}" = "true" ]; then
      sudo systemctl start containerd.service || exit 1
    fi
    sudo systemctl start docker.service || exit 1
  fi
fi

# Wait for Docker, which takes a few seconds to start again after a move.
for OPENROSDE_CI_WAIT_SECOND in $(seq 1 60); do
  docker info > /dev/null 2>&1 && break
  if [ "${OPENROSDE_CI_WAIT_SECOND}" -eq 60 ]; then
    echo "Error: Docker did not answer within 60 seconds after the cleanup."
    exit 1
  fi
  sleep 1
done

echo "Free disk space after the cleanup, with Docker in '$(docker info --format '{{ .DockerRootDir }}')':"
df -h / /mnt 2> /dev/null
exit 0
