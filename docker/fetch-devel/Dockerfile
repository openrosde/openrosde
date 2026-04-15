# General guidelines and recommendations for writing 'Dockerfile':
# https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/

################################################################################

# Inherit from the SDE base image which provides all common tools.
ARG SDE_BASE_IMAGE=registry.gitlab.com/coarobo/sde/sde-base:latest
FROM ${SDE_BASE_IMAGE}

################################################################################

# Install the Fetch Robotics Fetch robot ROS dependencies.
# https://fetchrobotics.github.io/docs/

# Gather the Fetch robot packages from the ROS repositories.
# 'ros-noetic-fetch-ros' provides the robot drivers, navigation, MoveIt config, and teleoperation.
RUN apt-get update && apt-get install -y --no-install-recommends \
  ros-noetic-fetch-ros \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Gather the Fetch robot Gazebo simulation packages from the ROS repositories.
# https://fetchrobotics.github.io/docs/gazebo.html#installation
# 'ros-noetic-fetch-gazebo-demo' provides the Gazebo worlds, simulation launch files, and pre-built maps.
RUN apt-get update && apt-get install -y --no-install-recommends \
  ros-noetic-fetch-gazebo-demo \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Gather additional Fetch robot dependencies from the ROS repositories.
RUN apt-get update && apt-get install -y --no-install-recommends \
  ros-noetic-robot-controllers \
  ros-noetic-rgbd-launch \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

################################################################################

# Set the platform identifier as an environment variable.
ARG SDE_ROBOT_PLATFORM=fetch
ENV SDE_ROBOT_PLATFORM=${SDE_ROBOT_PLATFORM}

# Pass variables for version traceability.
ARG SDE_DOCKERFILE_COMMIT_SHORT_SHA
ENV SDE_DOCKER_IMAGE_VERSION=${SDE_DOCKERFILE_COMMIT_SHORT_SHA}
