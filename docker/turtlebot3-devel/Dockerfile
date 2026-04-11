# General guidelines and recommendations for writing 'Dockerfile':
# https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/

################################################################################

# Inherit from the SDE base image which provides CUDA, ROS Noetic, FlexBE,
# common tools, and the Bash shell environment.
ARG BASE_IMAGE=registry.gitlab.com/coarobo/sde/sde-devel:latest
FROM ${BASE_IMAGE}

################################################################################

# Install the TurtleBot3 ROS dependencies.
# https://emanual.robotis.com/docs/en/platform/turtlebot3/quick-start/#pc-setup

# Gather the TurtleBot3 dependencies from the ROS repositories.
RUN apt-get update && apt-get install -y --no-install-recommends \
  ros-noetic-joy \
  ros-noetic-teleop-twist-joy \
  ros-noetic-teleop-twist-keyboard \
  ros-noetic-laser-proc \
  ros-noetic-rgbd-launch \
  ros-noetic-rosserial-arduino \
  ros-noetic-rosserial-python \
  ros-noetic-rosserial-client \
  ros-noetic-rosserial-msgs \
  ros-noetic-amcl \
  ros-noetic-map-server \
  ros-noetic-move-base \
  ros-noetic-urdf \
  ros-noetic-xacro \
  ros-noetic-compressed-image-transport \
  ros-noetic-rqt* \
  ros-noetic-rviz \
  ros-noetic-gmapping \
  ros-noetic-navigation \
  ros-noetic-interactive-markers \
  ros-noetic-multirobot-map-merge \
  && rm -rf /var/lib/apt/lists/*

# Gather the TurtleBot3 packages from the ROS repositories.
RUN apt-get update && apt-get install -y --no-install-recommends \
  ros-noetic-dynamixel-sdk \
  ros-noetic-turtlebot3 \
  ros-noetic-turtlebot3-msgs \
  ros-noetic-turtlebot3-simulations \
  && rm -rf /var/lib/apt/lists/*

################################################################################

# Set the platform identifier as an environment variable.
ARG SDE_PLATFORM=turtlebot3
ENV SDE_PLATFORM=${SDE_PLATFORM}

# Pass variables for version traceability.
ARG SDE_DOCKERFILE_COMMIT_SHORT_SHA
ENV SDE_DOCKER_IMAGE_VERSION=${SDE_DOCKERFILE_COMMIT_SHORT_SHA}
