#!/bin/bash

# This script checks the converter of robot meshes in the CI, as 'docs/robot-models.md' describes.
# It converts the meshes of the base image and of the Catkin workspaces of the core and of the cloned extensions twice, and fails unless both runs give the same bytes.
# It then checks every GLB with the Khronos glTF-Validator, in a Node.js container with the package 'gltf-validator' pinned, and fails on any error, any warning, or any required extension.
# The converter runs with no network, the GLBs stay in the containers of the job, which it removes, and a mesh that cannot be converted is reported, since a client then falls back to the original.
#
# Usage: bash ./gitlab-ci/check-mesh-glbs.bash

################################################################################

OPENROSDE_CI_BASE_IMAGE="${OPENROSDE_CI_IMAGE_REGISTRY}/openrosde-base:${OPENROSDE_CI_IMAGE_TAG}"
OPENROSDE_CI_MESH2GLB_IMAGE="${OPENROSDE_CI_IMAGE_REGISTRY}/openrosde-mesh2glb:${OPENROSDE_CI_IMAGE_TAG}"
OPENROSDE_CI_NODE_IMAGE="node:22-slim@sha256:c3de60bf2f9dd0ac6370e6117950ff62d6e339527e7472301c9c78a017978392"
OPENROSDE_CI_GLTF_VALIDATOR_VERSION="2.0.0-dev.3.10"
OPENROSDE_CI_CONTAINER_PREFIX="openrosde-ci-mesh-glbs"

# Remove the containers of the check whatever happens.
trap 'docker rm --force ${OPENROSDE_CI_CONTAINER_PREFIX}-base ${OPENROSDE_CI_CONTAINER_PREFIX}-converter ${OPENROSDE_CI_CONTAINER_PREFIX}-validator > /dev/null 2>&1' EXIT
set -o pipefail
mkdir -p ci-logs

################################################################################

# Gather the meshes of the base image and of the workspaces into '/in' of a converter with no network.
docker run --detach --name "${OPENROSDE_CI_CONTAINER_PREFIX}-converter" --network none "${OPENROSDE_CI_MESH2GLB_IMAGE}" sleep infinity > /dev/null || exit 1
docker exec "${OPENROSDE_CI_CONTAINER_PREFIX}-converter" mkdir -p /in/opt/ros/noetic /in/workspaces || exit 1
docker create --name "${OPENROSDE_CI_CONTAINER_PREFIX}-base" "${OPENROSDE_CI_BASE_IMAGE}" true > /dev/null || exit 1
docker cp "${OPENROSDE_CI_CONTAINER_PREFIX}-base:/opt/ros/noetic/share" - | docker cp - "${OPENROSDE_CI_CONTAINER_PREFIX}-converter:/in/opt/ros/noetic/" || exit 1
tar -cf - --exclude=.git --exclude=build --exclude=devel --exclude=logs ros $(ls -d extensions 2> /dev/null) | docker cp - "${OPENROSDE_CI_CONTAINER_PREFIX}-converter:/in/workspaces/" || exit 1

# Convert every mesh twice, then compare the SHA-256 of every GLB of both runs.
for OPENROSDE_CI_RUN in 1 2; do
  docker exec "${OPENROSDE_CI_CONTAINER_PREFIX}-converter" python3 -I /opt/mesh2glb/generate-mesh-glbs.py --jobs "${JOB_CPUS:-4}" --out "/out${OPENROSDE_CI_RUN}" /in > "ci-logs/mesh-glbs-${OPENROSDE_CI_RUN}.tsv" || exit 1
  docker exec "${OPENROSDE_CI_CONTAINER_PREFIX}-converter" bash -c "mkdir -p /out${OPENROSDE_CI_RUN} && cd /out${OPENROSDE_CI_RUN} && find . -type f -name '*.glb' -exec sha256sum {} + | sort -k 2" > "ci-logs/mesh-glbs-${OPENROSDE_CI_RUN}.sha256" || exit 1
done
OPENROSDE_CI_EXIT_CODE=0
awk -F '\t' '{ count[$6 ~ /^ERROR/ ? "failed" : $6]++ } $6 ~ /^ERROR/ { print "Warning: " $1 "/" $2 ": " $6 } END { printf "Converted %d meshes, and could not convert %d, which clients replace with the original or the collision mesh.\n", count["ok"], count["failed"] }' ci-logs/mesh-glbs-1.tsv
if cmp -s ci-logs/mesh-glbs-1.sha256 ci-logs/mesh-glbs-2.sha256; then
  echo "Both runs gave the same bytes for all $(grep -c '' ci-logs/mesh-glbs-1.sha256) GLBs."
else
  echo "Error: Two runs of the converter gave different GLBs:"
  diff ci-logs/mesh-glbs-1.sha256 ci-logs/mesh-glbs-2.sha256 | head -n 20
  OPENROSDE_CI_EXIT_CODE=1
fi

# Report the largest GLBs, since a client can load none above 12,000,000 bytes, which the file service answers empty.
echo "The largest GLBs, in bytes:"
sort -t "$(printf '\t')" -k 5 -n -r ci-logs/mesh-glbs-1.tsv | head -n 10 | awk -F '\t' '{ print "  " $5 " " $1 "/" $2 ".glb" }'

################################################################################

# Check every GLB with the Khronos glTF-Validator, pinned, in a Node.js container that only installs it.
docker run --detach --name "${OPENROSDE_CI_CONTAINER_PREFIX}-validator" --workdir /work "${OPENROSDE_CI_NODE_IMAGE}" sleep infinity > /dev/null || exit 1
docker exec "${OPENROSDE_CI_CONTAINER_PREFIX}-validator" npm install --silent --no-audit --no-fund "gltf-validator@${OPENROSDE_CI_GLTF_VALIDATOR_VERSION}" > /dev/null || exit 1
docker cp "${OPENROSDE_CI_CONTAINER_PREFIX}-converter:/out1" - | docker cp - "${OPENROSDE_CI_CONTAINER_PREFIX}-validator:/work/" || exit 1
docker cp ./gitlab-ci/validate-glbs.mjs "${OPENROSDE_CI_CONTAINER_PREFIX}-validator:/work/validate-glbs.mjs" || exit 1
docker exec "${OPENROSDE_CI_CONTAINER_PREFIX}-validator" bash -c "find out1 -type f -name '*.glb' -print0 | xargs -0 --no-run-if-empty node validate-glbs.mjs" || OPENROSDE_CI_EXIT_CODE=1

exit ${OPENROSDE_CI_EXIT_CODE}
