# General guidelines and recommendations for writing 'Dockerfile':
# https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/

################################################################################

# This image converts the meshes of robot descriptions, COLLADA, STL, and OBJ, into GLB files for the file service of 'rosbridge_server_default.launch', as 'docs/robot-models.md' describes.
# It runs apart from the ROS images, since its libraries need a newer Python than the Python 3.8 of Ubuntu 20.04.
# The Python image is pinned by digest and every library by version, so that the same mesh gives the same bytes on every machine of the same architecture.
# https://hub.docker.com/_/python
FROM python:3.12-slim@sha256:a6e34c598f2467ed0e9a8d349809fcd8b5c603269512df273a0bb1784edc11b1

################################################################################

# Install the converter libraries: 'trimesh' (MIT) with 'pycollada' (BSD) for COLLADA, and the libraries they need to give the same bytes on every run.
# https://github.com/mikedh/trimesh
# https://github.com/pycollada/pycollada
RUN pip install --no-cache-dir \
  trimesh==5.1.1 \
  pycollada==0.9.3 \
  numpy==2.5.4 \
  scipy==1.18.1 \
  lxml==6.1.3 \
  pillow==12.3.0

# Copy the converter scripts.
COPY ./docker/openrosde-mesh2glb/scripts/. /opt/mesh2glb/

################################################################################

# Pass variables for version traceability.
ARG OPENROSDE_DOCKERFILE_COMMIT_SHORT_SHA
ENV OPENROSDE_DOCKER_IMAGE_VERSION=${OPENROSDE_DOCKERFILE_COMMIT_SHORT_SHA}
