# General guidelines and recommendations for writing 'Dockerfile':
# https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/

################################################################################

# Inherit from the platform-specific SDE image which provides the platform tools.
# The 'SDE_ROBOT_PLATFORM' build argument is injected from the SDE environment.
ARG SDE_ROBOT_PLATFORM
ARG SDE_PLATFORM_IMAGE=registry.gitlab.com/coarobo/sde/${SDE_ROBOT_PLATFORM}-devel:latest
FROM ${SDE_PLATFORM_IMAGE}

################################################################################

# Install user-defined system dependencies.
# Add your own 'apt-get install' or 'pip3 install' commands here.
# Example:
#
# RUN apt-get update && apt-get install -y --no-install-recommends \
#   my-package-1 \
#   my-package-2 \
#   && apt-get clean && rm -rf /var/lib/apt/lists/*
#
# RUN pip3 install \
#   my-python-package==1.0.0

################################################################################

# Install dependencies for the FastSAM real-time segmentation demo.
# ros/user_catkin_ws/src/sde_user_launch/scripts/seg_fastsam_node.py
# ros/user_catkin_ws/src/sde_user_launch/launch/seg_fastsam.launch
# https://docs.ultralytics.com/models/fast-sam/

# The base image apt-installs 'python3-psutil' as a distutils package, which pip cannot safely
# uninstall/upgrade on its own. '--ignore-installed' lets pip shadow it with a pip-managed copy
# instead of failing with "Cannot uninstall psutil ... distutils installed project" when
# 'ultralytics' (below) tries to pull in a newer version.
RUN pip3 install --ignore-installed psutil

# GPU-enabled PyTorch (matches the CUDA 12.1 runtime already on this image).
RUN pip3 install torch --index-url https://download.pytorch.org/whl/cu121

# Ultralytics provides the 'FastSAM' class used by seg_fastsam_node.py.
RUN pip3 install ultralytics

# 'ultralytics' pulls in 'opencv-python' as a dependency. That shadows the ROS-provided
# 'python3-opencv' that 'cv_bridge' is built against and breaks it (e.g. 'cv2_to_imgmsg' raising
# 'KeyError: 16' for a perfectly ordinary bgr8 image). Remove it -- 'ros-noetic-desktop-full'
# (installed by 'sde-base') already provides a working 'cv2' via the system 'python3-opencv'.
RUN pip3 uninstall -y opencv-python

# FastSAM weights are NOT baked into the image here: this Dockerfile stage builds before
# '/root/SDE' is bind-mounted at runtime, so anything written under that path during the image
# build would just be hidden by the host repo mount later. Download the weights once per
# container instead (see 'sde_user_launch/README.md' or the FastSAM demo instructions):
#
#   mkdir -p ~/SDE/ros/user_catkin_ws/src/sde_user_launch/models/fastsam
#   cd ~/SDE/ros/user_catkin_ws/src/sde_user_launch/models/fastsam
#   python3 -c "from ultralytics import FastSAM; FastSAM('FastSAM-x.pt')"

################################################################################

# Pass variables for version traceability.
ARG SDE_DOCKERFILE_COMMIT_SHORT_SHA
ENV SDE_DOCKER_IMAGE_VERSION=${SDE_DOCKERFILE_COMMIT_SHORT_SHA}
