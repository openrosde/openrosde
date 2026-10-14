# General guidelines and recommendations for writing 'Dockerfile':
# https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/

################################################################################

# Inherit from the OpenRoSDE base image which provides all common tools.
ARG OPENROSDE_BASE_IMAGE=registry.gitlab.com/coarobo/sde/openrosde-base:main
FROM ${OPENROSDE_BASE_IMAGE}

################################################################################

# Install the RT Sciurus17 robot ROS dependencies.
# https://github.com/rt-net/sciurus17_ros

# Gather the MoveIt motion planning framework packages from the ROS repositories.
# 'ros-noetic-moveit' is required by 'sciurus17_moveit_config'.
RUN apt-get update && apt-get install -y --no-install-recommends \
  ros-noetic-moveit \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Gather the joint control packages from the ROS repositories.
# 'ros-noetic-joint-trajectory-controller' and 'ros-noetic-gripper-action-controller' are required by 'sciurus17_control'.
RUN apt-get update && apt-get install -y --no-install-recommends \
  ros-noetic-joint-trajectory-controller \
  ros-noetic-gripper-action-controller \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Gather transitive Gazebo simulation and Dynamixel SDK dependencies from the ROS repositories.
# 'ros-noetic-dynamixel-sdk' is required by 'sciurus17_control'.
# 'ros-noetic-roboticsgroup-upatras-gazebo-plugins' is required by 'sciurus17_gazebo'.
RUN apt-get update && apt-get install -y --no-install-recommends \
  ros-noetic-dynamixel-sdk \
  ros-noetic-roboticsgroup-upatras-gazebo-plugins \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

################################################################################

# Install the Intel RealSense cameras ROS dependencies.
# https://github.com/realsenseai/realsense-ros

# Gather the Intel RealSense camera packages from the ROS repositories.
RUN apt-get update && apt-get install -y --no-install-recommends \
  ros-noetic-realsense2-camera \
  ros-noetic-realsense2-description \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

################################################################################

# Set the platform identifier as an environment variable.
ARG OPENROSDE_ROBOT_PLATFORM=sciurus17
ENV OPENROSDE_ROBOT_PLATFORM=${OPENROSDE_ROBOT_PLATFORM}

# Pass variables for version traceability.
ARG OPENROSDE_DOCKERFILE_COMMIT_SHORT_SHA
ENV OPENROSDE_DOCKER_IMAGE_VERSION=${OPENROSDE_DOCKERFILE_COMMIT_SHORT_SHA}
