# Getting Started

Follow this step-by-step guide to perform the initial setup of the SDE on an [Ubuntu](https://www.ubuntu.com/) development machine.

> [!NOTE]
> The whole SDE is containerized/virtualized using [Docker](https://www.docker.com/).
> This ensures that all the contributors work in the exact same software environment.

> [!NOTE]
> The SDE robot, simulator, visualization, and behavior interfaces are primarily implemented with [ROS](http://www.ros.org/), [Gazebo](http://gazebosim.org/), [Rviz](https://github.com/ros-visualization/rviz), and [FlexBE](http://flexbe.github.io/).

> [!NOTE]
> The SDE primarily targets Nvidia GPU-equipped Ubuntu development machines and the Nvidia [CUDA](https://developer.nvidia.com/cuda-toolkit) platform.
> Although the SDE can be run on other GPU platforms such as Intel integrated graphics, some 3D acceleration issues may arise.
> For example, the [FlexBE App](https://github.com/FlexBE/flexbe_app) may appear partially broken due to [OpenGL](https://www.opengl.org/) errors.

> [!NOTE]
> Virtual machines are only partially supported: 3D accelerated tools will crash at runtime unless the same virtual machine drivers are installed in both the Docker container and the virtual machine.

> [!NOTE]
> Although this initial setup is meant to be performed only once, you can run it again should you want to reset the development environment as the project evolves.
> However, make sure to backup your latest changes beforehand.

## Step 0: Verify the Prerequisites

**Mandatory:**

- An Ubuntu 22.04 LTS (Jammy Jellyfish) development machine based on the AMD64 architecture.
- Access to administrator privileges (`sudo`) on the Ubuntu machine.

**Recommended:**

- A physical robot for full operability (see [Platform Documentation](platforms/)).
  If not, a Gazebo simulation provides support for basic operations.
- An Nvidia GPU capable of running CUDA 11.2, or newer, to accelerate 3D graphics and deep learning.

## Step 1: Set up the Development Environment

Set up the environment of the Ubuntu development machine with the following instructions.

1. Install [Git](https://git-scm.com/) if necessary:

    ```shell
    sudo apt-get update && sudo apt-get install -y git
    ```

2. Clone the SDE repository:

    ```shell
    git clone https://gitlab.com/coarobo/SDE.git && cd SDE/
    ```

    Enter your GitLab developer credentials if prompted.
3. Configure the system environment:

    ```shell
    bash ./SETUP-DEVEL-MACHINE.bash
    ```

    The execution of `SETUP-DEVEL-MACHINE.bash` requires `sudo` permissions to install the tools that allow virtualization, i.e., [Docker](https://www.docker.com/) (with [Docker Compose](https://github.com/docker/compose)), [Nvidia Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/index.html), and [Terminator](https://gnometerminator.blogspot.com/).
    System changes made with `sudo` are kept to a strict minimum.
4. Reboot the system (or log out and back in) for the changes to users and groups to take effect:

    ```shell
    sudo reboot
    ```

> [!NOTE]
> The `SETUP-DEVEL-MACHINE.bash` script is divided into two parts: system-wide installations (with `sudo`) and local user environment setup (without `sudo`).
> The system-wide part makes changes that require a reboot or re-login to take effect.
> However, if your system already has the necessary tools installed (Docker, Nvidia Container Toolkit, Terminator), you can skip the script and manually initialize the Git submodules with `git submodule update --init --recursive` from the SDE root directory.

> [!NOTE]
> You do not need to reboot if your local user has already been added to the `docker` group.
> If so, executing `docker --version` should not ask for `sudo`.
> In principle, you only need to reboot after the very first time you run `SETUP-DEVEL-MACHINE.bash`.

## Step 2: Configure the Platform

Select the target robot platform by editing the `.env` file at the root of the repository.

1. Set the `SDE_PLATFORM` variable to the desired platform:

    ```shell
    # Platform to use: turtlebot3, ur5e
    SDE_PLATFORM=turtlebot3
    ```

2. Optionally, create a `.env.custom` file to override default settings (see `.env.custom.example` for reference).

For platform-specific details, refer to the [Platform Documentation](platforms/).

## Step 3: Build the Docker Image

Create a virtual environment using Docker (= Docker image) on the Ubuntu development machine with the following instructions.

1. Build the Docker image:

    ```shell
    bash ./BUILD-DOCKER-IMAGE.bash #[docker-project]
    ```

    This script builds the shared base image (`sde-base`) and the platform-specific image (`${SDE_PLATFORM}-devel`) following the instructions found in `docker/`.
    Enter your GitLab developer credentials if prompted.

> [!NOTE]
> The script `BUILD-DOCKER-IMAGE.bash` first tries to download the image from the [container registry](https://gitlab.com/coarobo/SDE/container_registry) of the project.
> If, for whatever reason, the image cannot be downloaded, the script will build it locally.
> The latter process is slow and can take up to 1 hour.
> In both cases, avoid using a Wi-Fi connection to greatly accelerate the process.
> Note that future local builds will reuse cached data whenever possible.

## Step 4: Run the Docker Container

Enter a virtual instance of the Docker image (= Docker container) on the Ubuntu development machine with the following instructions.

1. Run the Docker container:

    ```shell
    bash ./RUN-DOCKER-CONTAINER.bash #[docker-project] #[ros-launch]
    ```

    This script creates or updates the container following the instructions found in `docker/docker-compose.yaml`.
    It allows the container to share system resources, such as volumes and devices, with the Ubuntu development machine.
2. Configure the freshly built Docker container by executing the following Bash function inside it:

    ```shell
    sde-get-fully-started
    ```

    This function calls several scripts to download the required datasets and build the ROS environment (= Catkin workspace) inside the Docker container.
    It will remove any existing Catkin workspace and build a new one inside `${SDE_CONTAINER_ROOT_DIR}/ros/`.
    It will also automatically source the newly built ROS environment.
3. From there, you have everything ready to start using the SDE to develop new features.
4. Use `Ctrl+d` to exit the container at any time.

> [!NOTE]
> If Nvidia drivers are present in the Ubuntu development machine, the script `RUN-DOCKER-CONTAINER.bash` will run `docker-compose-gpu.yaml` alongside `docker-compose.yaml` to mount the GPUs into the Docker container via Nvidia Container Toolkit.
> If not the case, most 3D accelerated tools, including the Gazebo simulator, will be extremely slow to run.

> [!NOTE]
> The script `RUN-DOCKER-CONTAINER.bash` will try to resolve the robot host name defined in `SDE_ROBOT_HOSTNAME` and add its IP address to `/etc/hosts`.
> Note that you can ignore the errors if you do not plan to use a physical robot at that time.

> [!NOTE]
> Be careful if you need to modify `docker-compose.yaml` or `docker-compose-gpu.yaml` as the container will be recreated from scratch the next time you run `RUN-DOCKER-CONTAINER.bash`.

> [!NOTE]
> Note that the Bash function `sde-get-fully-started` should be used only once after instantiating a new container from the Docker image.

For advanced features and Docker configuration details, refer to the [Advanced Usage](advanced-usage.md) guide.
