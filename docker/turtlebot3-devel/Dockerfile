# General guidelines and recommendations for writing 'Dockerfile':
# https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/

################################################################################

# Inherit from the OpenRoSDE base image which provides all common tools.
ARG OPENROSDE_BASE_IMAGE=registry.gitlab.com/coarobo/sde/openrosde-base:main
FROM ${OPENROSDE_BASE_IMAGE}

################################################################################

# Install the TurtleBot3 robot ROS dependencies.
# https://emanual.robotis.com/docs/en/platform/turtlebot3/quick-start/#pc-setup

# Gather the TurtleBot3 robot dependencies from the ROS repositories.
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
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Gather the TurtleBot3 robot packages from the ROS repositories.
RUN apt-get update && apt-get install -y --no-install-recommends \
  ros-noetic-dynamixel-sdk \
  ros-noetic-turtlebot3 \
  ros-noetic-turtlebot3-msgs \
  ros-noetic-turtlebot3-simulations \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

################################################################################

# Set the platform identifier as an environment variable.
ARG OPENROSDE_ROBOT_PLATFORM=turtlebot3
ENV OPENROSDE_ROBOT_PLATFORM=${OPENROSDE_ROBOT_PLATFORM}

# Pass variables for version traceability.
ARG OPENROSDE_DOCKERFILE_COMMIT_SHORT_SHA
ENV OPENROSDE_DOCKER_IMAGE_VERSION=${OPENROSDE_DOCKERFILE_COMMIT_SHORT_SHA}
