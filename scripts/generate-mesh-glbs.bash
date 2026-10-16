#!/bin/bash

# This script converts every COLLADA, STL, and OBJ mesh of the Catkin and colcon workspaces of the core and of the cloned extensions into a GLB beside it, named by appending '.glb', such as 'base.dae.glb', for the file service that 'rosbridge_server_default.launch' starts.
# The meshes of the packages installed in the images, under '/opt/ros/<distribution>/share', get their GLBs when the user overlay builds, in 'docker/user-devel/Dockerfile'.
# On ROS 2, a colcon workspace serves its meshes from its install space, so build it again after this script, as 'docs/robot-models.md' describes.
# GLBs are generated locally only, never committed and never published, since the meshes of some robots may not be redistributed, as 'docs/robot-models.md' explains.
# It runs the converter image 'openrosde-mesh2glb' as the host user with no network, and converts only the meshes whose GLB is missing or older, so it can run again at any time, such as after editing a mesh.
# It is called by 'BUILD-DOCKER-IMAGE.bash' once the images are ready, and it warns rather than fails when Docker or the image is missing, so that it never stops the script that calls it.
# It also adds the patterns of the GLBs to 'info/exclude' of every Git repository it may write into, the submodules and the extensions, so that no GLB shows as a change there.
#
# Usage: bash ./scripts/generate-mesh-glbs.bash [image]
#
# [image]: The converter image to run.
#          Default is '${OPENROSDE_DOCKER_REGISTRY}/openrosde-mesh2glb:${OPENROSDE_DOCKER_IMAGE_TAG}', from the settings of OpenRoSDE.

################################################################################

# Resolve the repository root directory relative to this script.
OPENROSDE_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Name the converter image, from the settings unless it is given.
OPENROSDE_MESH2GLB_IMAGE="$1"
if [ -z "${OPENROSDE_MESH2GLB_IMAGE}" ]; then
  OPENROSDE_QUIET=true source "${OPENROSDE_ROOT_DIR}/scripts/load-openrosde-env.bash" > /dev/null
  OPENROSDE_MESH2GLB_IMAGE="${OPENROSDE_DOCKER_REGISTRY}/openrosde-mesh2glb:${OPENROSDE_DOCKER_IMAGE_TAG}"
fi

################################################################################

# Add the patterns of the GLBs to 'info/exclude' of the core, of every extension, and of every submodule of theirs, each only once.
OPENROSDE_GLB_PATTERNS=('*.[dD][aA][eE].glb' '*.[sS][tT][lL].glb' '*.[oO][bB][jJ].glb')
for OPENROSDE_REPOSITORY_ROOT_DIR in "${OPENROSDE_ROOT_DIR}" "${OPENROSDE_ROOT_DIR}"/extensions/*; do
  if [ ! -e "${OPENROSDE_REPOSITORY_ROOT_DIR}/.git" ]; then
    continue
  fi
  for OPENROSDE_GIT_DIR in "${OPENROSDE_REPOSITORY_ROOT_DIR}" $(git -C "${OPENROSDE_REPOSITORY_ROOT_DIR}" submodule foreach --quiet --recursive 'echo "${toplevel}/${sm_path}"' 2>/dev/null); do
    OPENROSDE_EXCLUDE_FILE="$(git -C "${OPENROSDE_GIT_DIR}" rev-parse --git-path info/exclude 2>/dev/null)"
    if [ -z "${OPENROSDE_EXCLUDE_FILE}" ]; then
      continue
    fi
    if [[ "${OPENROSDE_EXCLUDE_FILE}" != /* ]]; then
      OPENROSDE_EXCLUDE_FILE="${OPENROSDE_GIT_DIR}/${OPENROSDE_EXCLUDE_FILE}"
    fi
    mkdir -p "$(dirname "${OPENROSDE_EXCLUDE_FILE}")"
    for OPENROSDE_GLB_PATTERN in "${OPENROSDE_GLB_PATTERNS[@]}"; do
      grep -q -x -F -e "${OPENROSDE_GLB_PATTERN}" "${OPENROSDE_EXCLUDE_FILE}" 2>/dev/null || echo "${OPENROSDE_GLB_PATTERN}" >> "${OPENROSDE_EXCLUDE_FILE}"
    done
  done
done

################################################################################

# Convert the meshes of the workspaces with the converter image, as the host user, so that every GLB belongs to that user.
# The converter prints one line per mesh, which is summed up here, with a warning for each mesh that failed.
set -o pipefail
if ! command -v docker > /dev/null 2>&1; then
  echo "Warning: Docker is missing, so the GLBs of the robot meshes were not generated, and clients fall back to the original meshes or their bundled models."
  exit 0
fi
echo "Generating the GLBs of the robot meshes in '${OPENROSDE_ROOT_DIR}/ros', '${OPENROSDE_ROOT_DIR}/ros2', and '${OPENROSDE_ROOT_DIR}/extensions' with '${OPENROSDE_MESH2GLB_IMAGE}'."
if ! docker run --rm --network none \
  --user "$(id -u):$(id -g)" \
  --volume "${OPENROSDE_ROOT_DIR}:${OPENROSDE_ROOT_DIR}" \
  "${OPENROSDE_MESH2GLB_IMAGE}" \
  python3 -I /opt/mesh2glb/generate-mesh-glbs.py --jobs "${OPENROSDE_BUILD_JOBS:-$(nproc 2> /dev/null || echo 4)}" "${OPENROSDE_ROOT_DIR}/ros" "${OPENROSDE_ROOT_DIR}/ros2" "${OPENROSDE_ROOT_DIR}/extensions" \
  | awk -F '\t' '{ count[$6 ~ /^ERROR/ ? "failed" : $6]++ } $6 ~ /^ERROR/ { print "Warning: " $1 "/" $2 ": " $6 } END { printf "Converted %d meshes, kept %d current GLBs, and could not convert %d meshes.\n", count["ok"], count["current"], count["failed"] }'; then
  echo "Warning: The converter image '${OPENROSDE_MESH2GLB_IMAGE}' could not run, so the GLBs of the robot meshes were not generated, and clients fall back to the original meshes or their bundled models."
fi
exit 0
