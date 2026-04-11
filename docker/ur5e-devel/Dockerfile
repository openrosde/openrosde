# General guidelines and recommendations for writing 'Dockerfile':
# https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/

################################################################################

# Inherit from the SDE base image which provides CUDA, ROS Noetic, FlexBE,
# common tools, and the Bash shell environment.
ARG BASE_IMAGE=registry.gitlab.com/coarobo/sde/sde-base:latest
FROM ${BASE_IMAGE}

################################################################################

# Install the ROS dependencies of Universal Robots UR5e robot.

# https://github.com/UniversalRobots/Universal_Robots_ROS_Driver
RUN apt-get update && apt-get install -y --no-install-recommends \
  ros-noetic-ur-robot-driver \
  ros-noetic-ur-calibration \
  ros-noetic-rqt-joint-trajectory-controller \
  && rm -rf /var/lib/apt/lists/*

# https://github.com/ros-industrial/universal_robot
RUN apt-get update && apt-get install -y --no-install-recommends \
  ros-noetic-universal-robots \
  && rm -rf /var/lib/apt/lists/*

################################################################################

# Install dependencies for Intel RealSense cameras.
# https://github.com/IntelRealSense/realsense-ros

# Gather dependencies from the Ubuntu repositories.
RUN apt-get update && apt-get install -y --no-install-recommends \
  ros-noetic-realsense2-camera \
  ros-noetic-realsense2-description \
  && rm -rf /var/lib/apt/lists/*

################################################################################

# Install dependencies for OnRobot RG2/RG6/VG10/VGC10 grippers.
# https://github.com/UOsaka-Harada-Laboratory/onrobot

# Gather dependencies from the Ubuntu repositories.
RUN apt-get update && apt-get install -y --no-install-recommends \
  ros-noetic-ros-control \
  ros-noetic-ros-controllers \
  && rm -rf /var/lib/apt/lists/*

# Gather dependencies from the Python 3 repositories.
RUN pip3 install \
  pymodbus==2.5.3

################################################################################

# Install dependencies for 3Dconnexion SpaceMouse controllers.
# https://wiki.ros.org/spacenav_node

# Gather dependencies from the Ubuntu repositories.
RUN apt-get update && apt-get install -y --no-install-recommends \
  spacenavd \
  ros-noetic-spacenav-node \
  && rm -rf /var/lib/apt/lists/*

################################################################################

# Install miscellaneous ROS dependencies (incl. MoveIt and Rosbridge).
RUN apt-get update && apt-get install -y --no-install-recommends \
  ros-noetic-moveit \
  ros-noetic-moveit-servo \
  ros-noetic-rosbridge-suite \
  && rm -rf /var/lib/apt/lists/*

################################################################################

# Install common optional packages/tools.
RUN apt-get update && apt-get install -y --no-install-recommends \
  python3-tk \
  && rm -rf /var/lib/apt/lists/*

################################################################################

# Set the platform identifier as an environment variable.
ARG SDE_PLATFORM=ur5e
ENV SDE_PLATFORM=${SDE_PLATFORM}

# Pass variables for version traceability.
ARG SDE_DOCKERFILE_COMMIT_SHORT_SHA
ENV SDE_DOCKER_IMAGE_VERSION=${SDE_DOCKERFILE_COMMIT_SHORT_SHA}
