# General guidelines and recommendations for writing 'Dockerfile':
# https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/

# This is the base image of the platforms on ROS 2, beside 'docker/openrosde-base/Dockerfile' of the platforms on ROS 1, which stays.
# A platform declares the ROS it runs with 'OPENROSDE_ROS_VERSION' and 'OPENROSDE_ROS_DISTRO' in its template, as 'docs/ros2.md' describes.

################################################################################

# Pull the official ROS 2 Lyrical Luth (LTS) image on Ubuntu 26.04 LTS (Resolute Raccoon), pinned by the digest of its index of architectures, so that it builds the same on AMD64 and ARM64.
# https://hub.docker.com/_/ros
# The GPU of an Nvidia host reaches the container through the Nvidia Container Toolkit, which 'docker/docker-compose-nvidia.yaml' requests, so the image needs no CUDA of its own.
FROM ros:lyrical-ros-base@sha256:f79cd486fa218596747c45d00ca42101b0303fc6d94ed5adb72145cd6f54b86c

################################################################################

# Set up the time zone to avoid using 'DEBIAN_FRONTEND=noninteractive' inside 'Dockerfile' (best practice).
# This removes the interactive installation of 'tzdata' included in 'ros-lyrical-desktop-full'.
ARG TIMEZONE="Asia/Tokyo"
RUN echo ${TIMEZONE} > /etc/timezone \
  && ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime

# Install 'tzdata' without interaction.
RUN apt-get update && apt-get install -y --no-install-recommends \
  tzdata \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

################################################################################

# Install ROS 2 Lyrical Luth (LTS).
# https://docs.ros.org/en/lyrical/Installation/Ubuntu-Install-Debs.html
# The parent image already holds the ROS 2 repository, its key, and an initialized 'rosdep', so only the packages are added.

# Install the recommended ROS 2 'desktop_full' packages, with RViz, rqt, and Gazebo through 'ros_gz', and the developer tools, with 'colcon', 'rosdep', and 'vcstool'.
# Gazebo comes as the vendor packages 'gz_*_vendor' of the distribution, Gazebo Jetty for Lyrical, as REP 2000 pairs them.
RUN apt-get update && apt-get install -y --no-install-recommends \
  ros-lyrical-desktop-full \
  ros-dev-tools \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

################################################################################

# Install the FlexBE behavior engine, which the distribution releases.
# https://github.com/FlexBE/flexbe_behavior_engine
# The FlexBE App is not released for ROS 2 Lyrical, so the image holds the engine alone.
RUN apt-get update && apt-get install -y --no-install-recommends \
  ros-lyrical-flexbe-behavior-engine \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

################################################################################

# Install miscellaneous ROS packages/tools, with 'rqt_tf_tree', which 'desktop_full' leaves out, for the rqt suite of 'openrosde_launch'.
RUN apt-get update && apt-get install -y --no-install-recommends \
  ros-lyrical-moveit \
  ros-lyrical-moveit-servo \
  ros-lyrical-rosbridge-suite \
  ros-lyrical-rqt-tf-tree \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

################################################################################

# Install miscellaneous Ubuntu packages/tools.
RUN apt-get update && apt-get install -y --no-install-recommends \
  curl \
  git \
  iproute2 \
  iputils-ping \
  mesa-utils \
  nano \
  net-tools \
  psmisc \
  unzip \
  wget \
  wmctrl \
  x11-apps \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

################################################################################

# Build the file service of ROS#, which serves the meshes of the robot description to clients of 'rosbridge', such as Coarobo Viewport and Coarobo Sightline.
# https://github.com/siemens/ros-sharp/tree/2.3.1/ROS%20Packages/ROS2/file_server2
# No ROS distribution releases it, so it is built from the release '2.3.1', checked by commit, with the patches of 'docker/openrosde-base-ros2/patches/ros-sharp/'.
# It installs into '/opt/ros/lyrical' like a package of the distribution, as 'bloom' builds a binary package, so no setup script changes.
ARG OPENROSDE_ROS_SHARP_VERSION=2.3.1
ARG OPENROSDE_ROS_SHARP_COMMIT=9e2644e1b201605417308e8d1a67cdd6b012b31c
COPY ./docker/openrosde-base-ros2/patches/ros-sharp/ /tmp/ros-sharp-patches/
RUN git clone --quiet --depth 1 --filter=blob:none --no-checkout --branch ${OPENROSDE_ROS_SHARP_VERSION} https://github.com/siemens/ros-sharp.git /tmp/ros-sharp \
  && test "$(git -C /tmp/ros-sharp rev-parse HEAD)" = "${OPENROSDE_ROS_SHARP_COMMIT}" \
  && git -C /tmp/ros-sharp checkout --quiet HEAD -- "ROS Packages/ROS2/file_server2" LICENSE.md \
  && cp -R "/tmp/ros-sharp/ROS Packages/ROS2/file_server2" /tmp/file_server2 \
  && cd /tmp/file_server2 \
  && for OPENROSDE_PATCH in /tmp/ros-sharp-patches/*.patch; do git apply "${OPENROSDE_PATCH}" || exit 1; done \
  && mkdir build && cd build \
  && . /opt/ros/lyrical/setup.sh \
  && cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/ros/lyrical -DCMAKE_PREFIX_PATH=/opt/ros/lyrical -DBUILD_TESTING=OFF \
  && make -j"$(nproc)" && make install \
  && cp /tmp/ros-sharp/LICENSE.md /opt/ros/lyrical/share/file_server2/LICENSE.md \
  && cd / && rm -rf /tmp/ros-sharp /tmp/file_server2 /tmp/ros-sharp-patches

################################################################################

# Set up the Bash shell environment.

# Define the working directory.
WORKDIR /root/

# Set the OpenRoSDE root directory inside the container.
ARG OPENROSDE_CONTAINER_ROOT_DIR=/root/OpenRoSDE
ENV OPENROSDE_CONTAINER_ROOT_DIR=${OPENROSDE_CONTAINER_ROOT_DIR}

# Copy the helper scripts to the working directory, the same as those of the base image of ROS 1, which read the ROS of the platform from the settings.
COPY ./docker/openrosde-base/scripts/. ${OPENROSDE_CONTAINER_ROOT_DIR}/docker/openrosde-base/scripts/
RUN chmod -R +x ${OPENROSDE_CONTAINER_ROOT_DIR}/docker/openrosde-base/scripts/*

# Setup the Bash shell environment with '/root/.bashrc'.
RUN echo "source ${OPENROSDE_CONTAINER_ROOT_DIR}/docker/openrosde-base/scripts/initialize-bash-shell.bash" >> /root/.bashrc

# Force color prompt in terminal.
RUN sed -i 's/#force_color_prompt=yes/force_color_prompt=yes/' /root/.bashrc

# Pass variables for version traceability.
ARG OPENROSDE_DOCKERFILE_COMMIT_SHORT_SHA
ENV OPENROSDE_DOCKER_IMAGE_VERSION=${OPENROSDE_DOCKERFILE_COMMIT_SHORT_SHA}

# Add the OpenRoSDE root directory to the safe Git repository list.
RUN git config --global --add safe.directory ${OPENROSDE_CONTAINER_ROOT_DIR}

# Overwrite the entry point of the parent image.
ENTRYPOINT []

# Enter the container with a Bash shell.
CMD ["/bin/bash"]
