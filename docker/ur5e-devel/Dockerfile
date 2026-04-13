# General guidelines and recommendations for writing 'Dockerfile':
# https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/

################################################################################

# Inherit from the SDE base image which provides CUDA, ROS Noetic, FlexBE,
# common tools, and the Bash shell environment.
ARG SDE_BASE_IMAGE=registry.gitlab.com/coarobo/sde/sde-base:latest
FROM ${SDE_BASE_IMAGE}

################################################################################

# Install the Universal Robots UR5e robot ROS dependencies.

# Gather the UR5e robot driver packages and dependencies from the ROS repositories.
# https://github.com/UniversalRobots/Universal_Robots_ROS_Driver
RUN apt-get update && apt-get install -y --no-install-recommends \
  ros-noetic-ur-robot-driver \
  ros-noetic-ur-calibration \
  ros-noetic-rqt-joint-trajectory-controller \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Gather the UR5e simulation model packages from the ROS repositories.
# https://github.com/ros-industrial/universal_robot
RUN apt-get update && apt-get install -y --no-install-recommends \
  ros-noetic-universal-robots \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

################################################################################

# Install the OnRobot RG2/RG6/VG10/VGC10 grippers ROS dependencies.
# https://github.com/UOsaka-Harada-Laboratory/onrobot

# Gather the OnRobot package dependencies from the ROS repositories.
RUN apt-get update && apt-get install -y --no-install-recommends \
  ros-noetic-ros-control \
  ros-noetic-ros-controllers \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Gather the OnRobot package dependencies from the Python 3 repositories.
RUN pip3 install \
  pymodbus==2.5.3

################################################################################

# Install the Intel RealSense cameras ROS dependencies.
# https://github.com/IntelRealSense/realsense-ros

# Gather the Intel RealSense camera packages from the ROS repositories.
RUN apt-get update && apt-get install -y --no-install-recommends \
  ros-noetic-realsense2-camera \
  ros-noetic-realsense2-description \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

################################################################################

# Install the 3Dconnexion SpaceNavigator/SpaceMouse controllers ROS dependencies.
# https://wiki.ros.org/spacenav_node

# Gather the SpaceNavigator/SpaceMouse package dependencies from the Ubuntu repositories.
RUN apt-get update && apt-get install -y --no-install-recommends \
  spacenavd \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Gather the SpaceNavigator/SpaceMouse package dependencies from the ROS repositories.
RUN apt-get update && apt-get install -y --no-install-recommends \
  ros-noetic-spacenav-node \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

################################################################################

# Set the platform identifier as an environment variable.
ARG SDE_ROBOT_PLATFORM=ur5e
ENV SDE_ROBOT_PLATFORM=${SDE_ROBOT_PLATFORM}

# Pass variables for version traceability.
ARG SDE_DOCKERFILE_COMMIT_SHORT_SHA
ENV SDE_DOCKER_IMAGE_VERSION=${SDE_DOCKERFILE_COMMIT_SHORT_SHA}
