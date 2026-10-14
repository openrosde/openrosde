# General guidelines and recommendations for writing 'Dockerfile':
# https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/

################################################################################

# Inherit from the OpenRoSDE base image which provides all common tools.
ARG OPENROSDE_BASE_IMAGE=registry.gitlab.com/coarobo/sde/openrosde-base:main
FROM ${OPENROSDE_BASE_IMAGE}

################################################################################

# Install the Fetch Robotics Fetch robot ROS dependencies.
# https://fetchrobotics.github.io/docs/

# Gather the Fetch robot packages from the ROS repositories.
# 'ros-noetic-fetch-ros' provides the robot drivers, navigation, MoveIt config, and teleoperation.
# 'fetch_gazebo' and 'fetch_gazebo_demo' are built from source as a Git submodule in the Fetch Catkin workspace.
RUN apt-get update && apt-get install -y --no-install-recommends \
  ros-noetic-fetch-ros \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Gather the Fetch robot and Gazebo simulation dependencies from the ROS repositories.
# 'ros-noetic-robot-controllers' and 'ros-noetic-rgbd-launch' are required by 'fetch_gazebo'.
# 'ros-noetic-simple-grasping' is required by 'fetch_gazebo_demo'.
RUN apt-get update && apt-get install -y --no-install-recommends \
  ros-noetic-robot-controllers \
  ros-noetic-rgbd-launch \
  ros-noetic-simple-grasping \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

################################################################################

# Set the platform identifier as an environment variable.
ARG OPENROSDE_ROBOT_PLATFORM=fetch
ENV OPENROSDE_ROBOT_PLATFORM=${OPENROSDE_ROBOT_PLATFORM}

# Pass variables for version traceability.
ARG OPENROSDE_DOCKERFILE_COMMIT_SHORT_SHA
ENV OPENROSDE_DOCKER_IMAGE_VERSION=${OPENROSDE_DOCKERFILE_COMMIT_SHORT_SHA}
