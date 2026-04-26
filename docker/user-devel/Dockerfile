# General guidelines and recommendations for writing 'Dockerfile':
# https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/

################################################################################

# Inherit from the platform-specific SDE image which provides the platform tools.
# The 'SDE_ROBOT_PLATFORM' build argument is injected from the SDE environment.
ARG SDE_ROBOT_PLATFORM
ARG SDE_PLATFORM_IMAGE=registry.gitlab.com/coarobo/sde/${SDE_ROBOT_PLATFORM}-devel:latest
FROM ${SDE_PLATFORM_IMAGE}

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

# Pass variables for version traceability.
ARG SDE_DOCKERFILE_COMMIT_SHORT_SHA
ENV SDE_DOCKER_IMAGE_VERSION=${SDE_DOCKERFILE_COMMIT_SHORT_SHA}
