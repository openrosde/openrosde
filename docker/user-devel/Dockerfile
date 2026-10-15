# General guidelines and recommendations for writing 'Dockerfile':
# https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/

################################################################################

# Inherit from the platform-specific OpenRoSDE image which provides the platform tools, or from the last Docker layer of the active extensions on top of it.
# The 'OPENROSDE_ROBOT_PLATFORM' and 'OPENROSDE_PLATFORM_IMAGE' build arguments are injected from the OpenRoSDE environment.
ARG OPENROSDE_ROBOT_PLATFORM
ARG OPENROSDE_PLATFORM_IMAGE=registry.gitlab.com/coarobo/sde/${OPENROSDE_ROBOT_PLATFORM}-devel:main
ARG OPENROSDE_MESH2GLB_IMAGE=registry.gitlab.com/coarobo/sde/openrosde-mesh2glb:main
FROM ${OPENROSDE_PLATFORM_IMAGE} AS overlay

################################################################################

# Install user-defined system dependencies.
# Add your own 'apt-get install' or 'pip3 install' commands here.
# Example:
#
# RUN apt-get update && apt-get install -y --no-install-recommends \
#   my-package-1 \
#   my-package-2 \
#   && apt-get clean && rm -rf /var/lib/apt/lists/*
#
# RUN pip3 install \
#   my-python-package==1.0.0

################################################################################

# Convert every COLLADA, STL, and OBJ mesh installed in the images into a GLB beside it, for the file service of 'rosbridge_server_default.launch', as 'docs/robot-models.md' describes.
# The converter runs in its own image, since it needs a newer Python than the one of the ROS images, and only the GLBs come back into this one.
# This layer is built locally only, so the GLBs of meshes that may not be redistributed are never published.
# The meshes of the Catkin workspaces get theirs from 'scripts/generate-mesh-glbs.bash', since the workspaces are mounted at run time.
FROM ${OPENROSDE_MESH2GLB_IMAGE} AS glb
COPY --from=overlay /opt/ros/noetic/share /in
RUN python3 -I /opt/mesh2glb/generate-mesh-glbs.py --jobs "$(nproc)" --out /out /in > /out.tsv && mkdir -p /out

FROM overlay
COPY --from=glb /out/ /opt/ros/noetic/share/

################################################################################

# Pass variables for version traceability.
ARG OPENROSDE_DOCKERFILE_COMMIT_SHORT_SHA
ENV OPENROSDE_DOCKER_IMAGE_VERSION=${OPENROSDE_DOCKERFILE_COMMIT_SHORT_SHA}
