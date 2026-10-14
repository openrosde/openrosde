# General guidelines and recommendations for writing 'Dockerfile':
# https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/

################################################################################

# Inherit from the OpenRoSDE base image which provides all common tools.
ARG OPENROSDE_BASE_IMAGE=registry.gitlab.com/coarobo/sde/openrosde-base:main
FROM ${OPENROSDE_BASE_IMAGE}

################################################################################

# Install the Denso COBOTTA robot ROS dependencies.
# https://github.com/DENSORobot/denso_cobotta_ros

# Gather the MoveIt motion planning framework packages from the ROS repositories.
# 'ros-noetic-moveit' is required by 'denso_cobotta_moveit_config'.
RUN apt-get update && apt-get install -y --no-install-recommends \
  ros-noetic-moveit \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Gather the ros-control and ros-controllers packages from the ROS repositories.
# 'ros-noetic-ros-control' provides the hardware interface and controller manager.
# 'ros-noetic-ros-controllers' provides joint trajectory, position, and gripper controllers.
# Both are required by 'denso_cobotta_control' and 'denso_cobotta_driver'.
RUN apt-get update && apt-get install -y --no-install-recommends \
  ros-noetic-ros-control \
  ros-noetic-ros-controllers \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Gather the Gazebo ros-control integration package from the ROS repositories.
# 'ros-noetic-gazebo-ros-control' is required by 'denso_cobotta_gazebo'.
RUN apt-get update && apt-get install -y --no-install-recommends \
  ros-noetic-gazebo-ros-control \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

################################################################################

# Set the platform identifier as an environment variable.
ARG OPENROSDE_ROBOT_PLATFORM=cobotta
ENV OPENROSDE_ROBOT_PLATFORM=${OPENROSDE_ROBOT_PLATFORM}

# Pass variables for version traceability.
ARG OPENROSDE_DOCKERFILE_COMMIT_SHORT_SHA
ENV OPENROSDE_DOCKER_IMAGE_VERSION=${OPENROSDE_DOCKERFILE_COMMIT_SHORT_SHA}
