# General guidelines and recommendations for writing 'Dockerfile':
# https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/

################################################################################

# This is the base Docker image shared by all platform-specific images
# (e.g. turtlebot3-devel, ur5e-devel). It provides:
# - CUDA/cuDNN runtime
# - ROS Noetic (desktop-full)
# - FlexBE App dependencies
# - Common Python 3 and Ubuntu tools
# - Bash shell environment setup

################################################################################

# Pull the Ubuntu 20.04 (Focal Fossa) parent Docker image with CUDA/cuDNN support from the official Nvidia registry.
# https://hub.docker.com/r/nvidia/cuda/
FROM nvidia/cuda:11.2.2-cudnn8-devel-ubuntu20.04

################################################################################

# Set up the time zone to avoid using 'DEBIAN_FRONTEND=noninteractive' inside 'Dockerfile' (best practice).
# This removes the interactive installation of 'tzdata' included in 'ros-noetic-desktop-full'.
ARG TIMEZONE="Asia/Tokyo"
RUN echo ${TIMEZONE} > /etc/timezone \
  && ln -s /usr/share/zoneinfo/${TIMEZONE} /etc/localtime

# Install 'tzdata' without interaction.
RUN apt-get update && apt-get install -y --no-install-recommends \
  tzdata \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

################################################################################

# Install ROS Noetic Ninjemys (LTS).
# http://wiki.ros.org/noetic/Installation/Ubuntu

# Install tools required for the ROS installation.
RUN apt-get update && apt-get install -y --no-install-recommends \
  curl \
  && rm -rf /var/lib/apt/lists/*

# Add the ROS repository to the sources list.
RUN echo "deb http://packages.ros.org/ros/ubuntu focal main" > /etc/apt/sources.list.d/ros-latest.list

# Add the ROS repository key.
RUN curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add -

# Install the recommended ROS 'desktop' packages and developer tools.
RUN apt-get update && apt-get install -y --no-install-recommends \
  ros-noetic-desktop-full \
  python3-catkin-tools \
  python3-rosdep \
  && rm -rf /var/lib/apt/lists/*

# Initialize 'rosdep'.
# http://wiki.ros.org/rosdep
RUN rosdep init

################################################################################

# Install the FlexBE App dependencies.
# https://github.com/FlexBE/flexbe_app

# Gather the dependencies from the Ubuntu repositories.
RUN apt-get update && apt-get install -y --no-install-recommends \
  libxtst-dev \
  libcanberra-gtk3-module \
  upower \
  && rm -rf /var/lib/apt/lists/*

################################################################################

# Install common Python 3 packages/tools.

# Gather the Python 3 dependencies from the Ubuntu repositories.
RUN apt-get update && apt-get install -y --no-install-recommends \
  python3-pip  \
  python3-setuptools \
  && rm -rf /var/lib/apt/lists/*

# Upgrade Python Pip.
RUN pip3 install --upgrade pip

# Install common Python 3 packages/tools.
# RUN pip3 install \
#   TODO \
#   TODO

################################################################################

# Redirect 'python' shebangs to 'python3' for compatibility with older ROS packages.
RUN apt-get update && apt-get install -y --no-install-recommends \
  python-is-python3 \
  && rm -rf /var/lib/apt/lists/*

################################################################################

# Install common Ubuntu packages/tools.

RUN apt-get update && apt-get install -y --no-install-recommends \
  git \
  iproute2 \
  iputils-ping \
  mesa-utils \
  nano \
  net-tools \
  psmisc \
  unzip \
  wget \
  x11-apps \
  && rm -rf /var/lib/apt/lists/*

################################################################################

# Set up the Bash shell environment.

# Define the working directory.
WORKDIR /root/

# Copy the helper scripts to the working directory.
COPY ./docker/sde-base/scripts/. /root/SDE/docker/sde-base/scripts/
RUN chmod -R +x /root/SDE/docker/sde-base/scripts/*

# Setup the Bash shell environment with '/root/.bashrc'.
RUN echo "source /root/SDE/docker/sde-base/scripts/initialize-bash-shell.bash" >> /root/.bashrc

# Force color prompt in terminal.
RUN sed -i 's/#force_color_prompt=yes/force_color_prompt=yes/' /root/.bashrc

# Pass variables for version traceability.
ARG SDE_DOCKERFILE_COMMIT_SHORT_SHA
ENV SDE_DOCKER_IMAGE_VERSION=${SDE_DOCKERFILE_COMMIT_SHORT_SHA}

# Add the '/root/SDE/' directory to the safe Git repository list (no trailing '/' here).
RUN git config --global --add safe.directory /root/SDE

# Overwrite the entry point of the parent image.
ENTRYPOINT []

# Enter the container with a Bash shell.
CMD ["/bin/bash"]
