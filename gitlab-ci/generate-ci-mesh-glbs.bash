#!/bin/bash

# This script gives every COLLADA, STL, and OBJ mesh of a test container its GLB, as a machine of a user gets them from the user overlay and from 'scripts/generate-mesh-glbs.bash', so that the CI can check the robot model that the file service serves.
# It copies the meshes, their textures, and the package manifests out of the test container, converts them in a container of the converter image with no network, and copies only the GLBs back beside the meshes.
# The GLBs stay in the test container, which the CI removes, so none is ever published.
# When the converter image cannot be pulled, such as in the pipeline of an extension before the core publishes it, it warns and returns 2, so that the caller skips the check of the robot model.
#
# Usage: bash ./gitlab-ci/generate-ci-mesh-glbs.bash <container> <converter-image> [ros-distro]
#
# <container>: Name of the running test container, whose '/opt/ros/<ros-distro>/share' and Catkin or colcon workspaces in '${OPENROSDE_CONTAINER_ROOT_DIR}' get their GLBs.
# <converter-image>: The converter image 'openrosde-mesh2glb' to run, such as the one of the pipeline.
# [ros-distro]: The distribution of ROS of the container, such as 'noetic' or 'lyrical'.
#               Default value is 'noetic'.

################################################################################

OPENROSDE_CI_TEST_CONTAINER="$1"
OPENROSDE_CI_MESH2GLB_IMAGE="$2"
OPENROSDE_CI_MESH2GLB_CONTAINER="${OPENROSDE_CI_TEST_CONTAINER}-mesh2glb"
OPENROSDE_CI_ROS_DISTRO="${3:-noetic}"
OPENROSDE_CI_CONTAINER_ROOT_DIR="${OPENROSDE_CONTAINER_ROOT_DIR:-/root/OpenRoSDE}"

if [ -z "${OPENROSDE_CI_TEST_CONTAINER}" ] || [ -z "${OPENROSDE_CI_MESH2GLB_IMAGE}" ]; then
  echo "Error: Give the test container and the converter image, such as 'bash ./gitlab-ci/generate-ci-mesh-glbs.bash openrosde-ci-ur5e ghcr.io/openrosde/openrosde-mesh2glb:dev'."
  exit 1
fi

if ! docker pull --quiet "${OPENROSDE_CI_MESH2GLB_IMAGE}" > /dev/null 2>&1; then
  echo "Warning: The converter image '${OPENROSDE_CI_MESH2GLB_IMAGE}' cannot be pulled, so the robot model is not checked."
  exit 2
fi

################################################################################

# Start the converter with no network, and remove it whatever happens.
docker rm --force "${OPENROSDE_CI_MESH2GLB_CONTAINER}" > /dev/null 2>&1
trap 'docker rm --force "${OPENROSDE_CI_MESH2GLB_CONTAINER}" > /dev/null 2>&1' EXIT
docker run --detach --name "${OPENROSDE_CI_MESH2GLB_CONTAINER}" --network none "${OPENROSDE_CI_MESH2GLB_IMAGE}" sleep infinity > /dev/null || exit 1

# Copy the meshes, the textures, and the package manifests of the test container into '/in' of the converter, at their paths from the root, leaving out the build spaces and the Git folders.
set -o pipefail
docker exec "${OPENROSDE_CI_TEST_CONTAINER}" bash -c "cd / && find 'opt/ros/${OPENROSDE_CI_ROS_DISTRO}/share' '${OPENROSDE_CI_CONTAINER_ROOT_DIR#/}/ros' '${OPENROSDE_CI_CONTAINER_ROOT_DIR#/}/ros2' '${OPENROSDE_CI_CONTAINER_ROOT_DIR#/}/extensions' \
    \\( -name build -o -name devel -o -name install -o -name log -o -name logs -o -name .git \\) -prune -o -type f \
    \\( -iname '*.dae' -o -iname '*.stl' -o -iname '*.obj' -o -iname '*.mtl' -o -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.bmp' -o -iname '*.tga' -o -iname '*.tif' -o -iname '*.tiff' -o -iname '*.gif' -o -name package.xml \\) \
    -print0 2>/dev/null | tar --null --files-from - --create --file -" \
  | docker exec --interactive "${OPENROSDE_CI_MESH2GLB_CONTAINER}" bash -c "mkdir -p /in && tar --extract --file - --directory /in" || exit 1

# Convert every mesh into '/out', at the same paths, with one line per mesh kept in 'ci-logs/mesh-glbs.tsv', and report the meshes that could not be converted, which clients replace with the original or the collision mesh.
mkdir -p ci-logs
docker exec "${OPENROSDE_CI_MESH2GLB_CONTAINER}" python3 -I /opt/mesh2glb/generate-mesh-glbs.py --jobs "${JOB_CPUS:-4}" --out /out /in > ci-logs/mesh-glbs.tsv || exit 1
awk -F '\t' '{ count[$6 ~ /^ERROR/ ? "failed" : $6]++ } $6 ~ /^ERROR/ { print "Warning: " $1 "/" $2 ": " $6 } END { printf "Converted %d meshes of the test container, and could not convert %d.\n", count["ok"], count["failed"] }' ci-logs/mesh-glbs.tsv

# Copy the GLBs back beside their meshes in the test container.
docker exec "${OPENROSDE_CI_MESH2GLB_CONTAINER}" bash -c "mkdir -p /out && tar --create --file - --directory /out ." \
  | docker exec --interactive "${OPENROSDE_CI_TEST_CONTAINER}" tar --extract --file - --directory / || exit 1
