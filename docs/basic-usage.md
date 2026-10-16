# Basic Usage

Follow this step-by-step guide to perform the initial setup of OpenRoSDE on an [Ubuntu](https://www.ubuntu.com/) development machine.

> [!NOTE]
> The whole OpenRoSDE is containerized/virtualized using [Docker](https://www.docker.com/).
> This ensures that all the contributors work in the exact same software environment.

> [!NOTE]
> The OpenRoSDE robot, simulator, visualization, and behavior interfaces are primarily implemented with [ROS](http://www.ros.org/), [Gazebo](http://gazebosim.org/), [Rviz](https://github.com/ros-visualization/rviz), and [FlexBE](http://flexbe.github.io/).

> [!NOTE]
> OpenRoSDE primarily targets Nvidia GPU-equipped Ubuntu development machines and the Nvidia [CUDA](https://developer.nvidia.com/cuda-toolkit) platform.
> Although OpenRoSDE can be run on other GPU platforms such as Intel integrated graphics, some 3D acceleration issues may arise.
> For example, the [FlexBE App](https://github.com/FlexBE/flexbe_app) of ROS 1 may appear partially broken due to [OpenGL](https://www.opengl.org/) errors.

> [!NOTE]
> OpenRoSDE also supports [WSL 2](https://learn.microsoft.com/en-us/windows/wsl/) on Windows 11 with GPU-accelerated rendering via the [WSLg](https://github.com/microsoft/wslg) D3D12 Mesa driver.
> Performance will be lower than on a native Ubuntu installation due to the OpenGL-to-D3D12 translation layer, but 3D tools such as Gazebo, RViz, and FlexBE are usable.
> The GPU acceleration is automatically enabled when `RUN-DOCKER-CONTAINER.bash` detects the WSL 2 GPU device (`/dev/dxg`).
> Virtual machines (other than WSL 2) are only partially supported: 3D accelerated tools will crash at runtime unless the same virtual machine drivers are installed in both the Docker container and the virtual machine.

> [!NOTE]
> Although this initial setup is meant to be performed only once, you can run it again should you want to reset the development environment as the project evolves.
> However, make sure to backup your latest changes beforehand.

## ✅ Step 0: Verify the Prerequisites

**Mandatory:**

- An Ubuntu 24.04 LTS (Noble Numbat) development machine based on the AMD64 architecture, either natively or via [WSL 2](https://learn.microsoft.com/en-us/windows/wsl/) on Windows 11.
- Access to administrator privileges (`sudo`) on the Ubuntu machine.

**Recommended:**

- A physical robot for full operability (see [Supported Robot Platforms](../README.md#-supported-robot-platforms)).
  If not, a Gazebo simulation provides support for basic operations.
- An Nvidia GPU capable of running CUDA 11.2, or newer, to accelerate 3D graphics and deep learning.

## 🛠️ Step 1: Set up the Development Environment

Set up the environment of the Ubuntu development machine with the following instructions.

1. Install [Git](https://git-scm.com/) if necessary:

    ```shell
    sudo apt-get update && sudo apt-get install -y git
    ```

2. Clone the OpenRoSDE repository:

    ```shell
    git clone https://github.com/openrosde/openrosde.git && cd openrosde/
    ```

3. Configure the system environment:

    ```shell
    bash ./SETUP-DEVEL-MACHINE.bash
    ```

    The execution of `SETUP-DEVEL-MACHINE.bash` requires `sudo` permissions to install the tools that allow virtualization, i.e., [Docker](https://www.docker.com/) (with [Docker Compose](https://github.com/docker/compose)) and [Nvidia Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/index.html), together with [`tmux`](https://github.com/tmux/tmux/wiki), [`vcstool`](https://github.com/dirk-thomas/vcstool), and [Terminator](https://gnometerminator.blogspot.com/) until [#3](https://github.com/openrosde/openrosde/issues/3) removes it.
    System changes made with `sudo` are kept to a strict minimum.
4. Reboot the system (or log out and back in) for the changes to users and groups to take effect:

    ```shell
    sudo reboot
    ```

> [!NOTE]
> The `SETUP-DEVEL-MACHINE.bash` script is divided into two parts: system-wide installations (with `sudo`) and local user environment setup (without `sudo`).
> The system-wide part makes changes that require a reboot or re-login to take effect.
> However, if your system already has the necessary tools installed (Docker, Nvidia Container Toolkit, `tmux`, `vcstool`, and Terminator), you can skip the script and manually run `bash ./scripts/update-git-submodules.bash` from the OpenRoSDE root directory to initialize the Git submodules and apply patches.

> [!NOTE]
> You do not need to reboot if your local user has already been added to the `docker` group.
> If so, executing `docker --version` should not ask for `sudo`.
> In principle, you only need to reboot after the very first time you run `SETUP-DEVEL-MACHINE.bash`.

## ⚙️ Step 2: Configure the Platform

Select the target robot platform with the following instructions.

1. Clone the repository of the desired platform into `extensions/`, since the core holds no platform:

    ```shell
    git clone https://github.com/openrosde/openrosde-platform-turtlebot3.git extensions/openrosde-platform-turtlebot3
    ```

2. Switch to the platform, which also updates the Git submodules of every clone and applies their patches:

    ```shell
    bash ./SWITCH-ROBOT-PLATFORM.bash turtlebot3
    ```

The default `.env` selects `turtlebot3`, and the entry scripts stop with the commands that clone the platform when `.env` or `.env.custom` selects a platform cloned nowhere.
For platform-specific details, refer to the documentation of each platform repository, which [Supported Robot Platforms](../README.md#-supported-robot-platforms) lists.
For a robot whose setup lives in an extension, such as a platform with its devices for one installation, switch with `bash ./SWITCH-ROBOT-SETUP.bash <setup>` instead, as the [Extensions](extensions.md) guide explains.

## 🐳 Step 3: Build the Docker Image

Create a virtual environment using Docker (= Docker image) on the Ubuntu development machine with the following instructions.

1. Build the Docker image:

    ```shell
    bash ./BUILD-DOCKER-IMAGE.bash #[docker-project]
    ```

    This script pulls or builds the shared base image (`openrosde-base`), the converter of robot meshes (`openrosde-mesh2glb`), and the platform-specific image (`${OPENROSDE_ROBOT_PLATFORM}-devel`), builds the Docker layers of the extensions and the user overlay, then gives every robot mesh its GLB file, as [Robot Models](robot-models.md) describes.
    The registry serves the images without a login.

> [!NOTE]
> The script `BUILD-DOCKER-IMAGE.bash` first tries to download the image from the [container registry](https://github.com/orgs/openrosde/packages) of the project.
> If, for whatever reason, the image cannot be downloaded, the script will build it locally.
> The latter process is slow and can take up to 1 hour.
> In both cases, avoid using a Wi-Fi connection to greatly accelerate the process.
> Note that future local builds will reuse cached data whenever possible.
> Set `OPENROSDE_DOCKER_BUILD_FALLBACK=false` in `.env.custom` to stop with an error rather than build the image locally when its download fails, as a CI job should.

> [!TIP]
> A pull that fails with `denied` or `unauthorized` comes from an old login to `ghcr.io` kept in the Docker configuration of the machine, which Docker sends even though the public images need none.
> Run `docker logout ghcr.io` once, then build again.

## 🚀 Step 4: Run the Docker Container

Enter a virtual instance of the Docker image (= Docker container) on the Ubuntu development machine with the following instructions.

1. Run the Docker container:

    ```shell
    bash ./RUN-DOCKER-CONTAINER.bash #[docker-project] #[ros-launch] #[launch-args...]
    ```

    This script creates or updates the container following the instructions found in `docker/docker-compose.yaml`.
    The optional `[ros-launch]` argument preloads a ROS launch file in the opened shell.
    Any `arg:=value` tokens after it are forwarded to `roslaunch` as is, which overrides a launch file argument without modifying the launch file itself (e.g., `my_robot_launch:my_robot_bringup_default_realworld.launch robot_ip:=192.0.2.10`).
    It allows the container to share system resources, such as volumes and devices, with the Ubuntu development machine.
2. Configure the freshly built Docker container by executing the following Bash function inside it:

    ```shell
    openrosde-initialize-new-container
    ```

    This function calls several scripts to download the required datasets and build the ROS environment (= Catkin workspace) inside the Docker container.
    It will remove any existing Catkin workspace and build a new one inside `${OPENROSDE_CONTAINER_ROOT_DIR}/ros/`.
    It will also automatically source the newly built ROS environment.
3. From there, you have everything ready to start using OpenRoSDE to develop new features.
4. Use `Ctrl+d` to exit the container at any time.

> [!NOTE]
> If Nvidia drivers are present in the Ubuntu development machine, the script `RUN-DOCKER-CONTAINER.bash` will run `docker-compose-nvidia.yaml` alongside `docker-compose.yaml` to mount the GPUs into the Docker container via Nvidia Container Toolkit.
> On WSL 2, the script detects the GPU device (`/dev/dxg`) and runs `docker-compose-wsl.yaml` instead, enabling GPU-accelerated rendering via the WSLg D3D12 Mesa driver.
> If neither is detected, most 3D accelerated tools, including the Gazebo simulator, will be extremely slow to run.

> [!NOTE]
> The script `RUN-DOCKER-CONTAINER.bash` will try to resolve the robot host name defined in `OPENROSDE_ROBOT_HOSTNAME` and add its IP address to `/etc/hosts`.
> Note that you can ignore the errors if you do not plan to use a physical robot at that time.

> [!NOTE]
> Be careful if you need to modify `docker-compose.yaml`, `docker-compose-nvidia.yaml`, or `docker-compose-wsl.yaml` as the container will be recreated from scratch the next time you run `RUN-DOCKER-CONTAINER.bash`.

> [!NOTE]
> Note that the Bash function `openrosde-initialize-new-container` should be used only once after instantiating a new container from the Docker image.

## 🖥️ Step 5: Open the Multi-Terminal Session

Run the terminals of the platform together in a [`tmux`](https://github.com/tmux/tmux/wiki) session with the following instructions.

1. Exit the container (`Ctrl+d`) and launch the session from the Ubuntu development machine:

    ```shell
    bash ./RUN-TMUX-SESSION.bash #[docker-project] #[session-layout]
    ```

    The optional `[session-layout]` selects the panes of a layout, `default-gazebo` by default, or `default-realworld` for the real robot.
2. The session opens its tabs in the same standard order on every platform, `robot`, `extra`, `tools`, `user`, and `host`, and leaves out a tab with no pane.
    Its first pane shows the OpenRoSDE wordmark and how to use the tabs and the panes, which `openrosde-help` prints again in any shell of the container.
3. Each pane that runs a launch file waits for a key before it launches anything, as [Advanced Usage](advanced-usage.md) shows, so you choose when each one starts.
4. Press `Ctrl+b` then `d` to detach from the session, which keeps running, and run the same command again to attach to it.

> [!NOTE]
> The Terminator layout of earlier releases still opens with `bash ./RUN-TERMINATOR-TERMINAL.bash #[docker-project] #[terminator-layout]`, until [#3](https://github.com/openrosde/openrosde/issues/3) removes it.

For the tabs, the panes, and the other advanced features, refer to the [Advanced Usage](advanced-usage.md) guide.
