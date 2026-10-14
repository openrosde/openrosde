# General guidelines and recommendations for writing 'Dockerfile':
# https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/

################################################################################

# Global build argument used by the second 'FROM' stage below.
# It must be declared before any 'FROM' so buildkit treats it as a global ARG.
ARG OPENROSDE_BASE_IMAGE=registry.gitlab.com/coarobo/sde/openrosde-base:main

################################################################################

# Stage 1: Toyota HSR WRS binary distribution.
# https://github.com/hsr-project/tmc_wrs_docker
#
# This image is publicly distributed by Toyota Motor Corporation under the BSD 3-Clause Clear License and contains the full HSR ROS Noetic stack: URDF/SRDF, MoveIt configuration, navigation stack, controllers, all 'tmc_*' and 'hsrb_*' packages, and the WRS competition worlds.
# It is the only practical way to obtain a functional HSR Noetic simulator because Toyota has migrated the source-code stack to ROS 2 Humble and the higher-level Noetic packages remain on the private 'git.hsr.io' GitLab.
FROM ghcr.io/hsr-project/tmc_wrs_binary:noetic-latest AS hsr_binary

################################################################################

# Stage 2: OpenRoSDE base image (CUDA + ROS Noetic + OpenRoSDE tooling).
FROM ${OPENROSDE_BASE_IMAGE}

################################################################################

# Copy the additional ROS packages (tmc_*, hsrb_*) from Toyota's binary image into the existing '/opt/ros/noetic' tree without clobbering 'openrosde-base' files.
# The binary image builds these packages as a catkin workspace with '--cmake-args -DCMAKE_INSTALL_PREFIX=/opt/ros/noetic', so they live directly under '/opt/ros/noetic' and are available as soon as that setup.bash is sourced.
# No separate workspace overlay is needed.
COPY --from=hsr_binary /opt/ros/noetic /tmp/hsr_ros_overlay
RUN cp -rn /tmp/hsr_ros_overlay/share/. /opt/ros/noetic/share/ \
  && cp -rn /tmp/hsr_ros_overlay/lib/. /opt/ros/noetic/lib/ \
  && (cp -rn /tmp/hsr_ros_overlay/include/. /opt/ros/noetic/include/ 2>/dev/null || true) \
  && (cp -rn /tmp/hsr_ros_overlay/etc/. /opt/ros/noetic/etc/ 2>/dev/null || true) \
  && rm -rf /tmp/hsr_ros_overlay

# Install additional runtime dependencies required by the HSR Gazebo bringup.
# 'ros-noetic-desktop-full' (installed by 'openrosde-base') already provides 'gazebo_ros', 'xacro', 'rviz', 'robot_state_publisher', and 'joint_state_publisher'.
# 'ros-noetic-gazebo-ros-control' wires Gazebo simulated joints to 'controller_manager'.
# 'ros-noetic-joint-state-controller' and 'ros-noetic-joint-trajectory-controller' provide the controllers loaded by 'hsrb_gazebo_bringup' (arm, head, gripper, base).
# 'ros-noetic-joint-state-publisher-gui' provides an interactive sliders panel to drive the URDF in RViz.
# 'ros-noetic-navigation' provides 'amcl' and 'move_base' used by 'hsrb_rosnav_config/hsrb_nav.launch'.
# 'libsdl1.2debian' is required at runtime by the WRS-shipped 'gnome_segway_*' Gazebo plugins.
RUN apt-get update && apt-get install -y --no-install-recommends \
  ros-noetic-gazebo-ros-control \
  ros-noetic-joint-state-controller \
  ros-noetic-joint-trajectory-controller \
  ros-noetic-joint-state-publisher-gui \
  ros-noetic-navigation \
  libsdl1.2debian \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

################################################################################

# Set the platform identifier as an environment variable.
ARG OPENROSDE_ROBOT_PLATFORM=hsr
ENV OPENROSDE_ROBOT_PLATFORM=${OPENROSDE_ROBOT_PLATFORM}

# Pass variables for version traceability.
ARG OPENROSDE_DOCKERFILE_COMMIT_SHORT_SHA
ENV OPENROSDE_DOCKER_IMAGE_VERSION=${OPENROSDE_DOCKERFILE_COMMIT_SHORT_SHA}
