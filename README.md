<p align="center">
  <a href="https://openrosde.org/">
    <img src="https://raw.githubusercontent.com/openrosde/.github/main/profile/assets/openrosde-logo.svg" alt="OpenRoSDE logo" width="96" height="96">
  </a>
</p>

# OpenRoSDE

OpenRoSDE, read "Open Robotic SDE", is the open-source reference implementation of the Software Development Environment (SDE) described in "**Software Development Environment for Collaborative Research Workflow in Robotic System Integration**" (DOI: [10.1080/01691864.2022.2068353](https://doi.org/10.1080/01691864.2022.2068353)) and maintained by [Coarobo GK](https://coarobo.com/).

[![Docker](https://img.shields.io/badge/Docker-Containerization-blue?logo=docker&logoColor=white)](https://www.docker.com/)
[![ROS Noetic](https://img.shields.io/badge/ROS_Noetic-Framework-blue?logo=ros&logoColor=white)](http://wiki.ros.org/noetic)
[![ROS 2 Lyrical](https://img.shields.io/badge/ROS_2_Lyrical-Framework-blue?logo=ros&logoColor=white)](https://docs.ros.org/en/lyrical/)
[![Ubuntu 20.04](https://img.shields.io/badge/Ubuntu_20.04-Container_OS-blue?logo=ubuntu&logoColor=white)](https://releases.ubuntu.com/20.04/)
[![Ubuntu 26.04](https://img.shields.io/badge/Ubuntu_26.04-Container_OS-blue?logo=ubuntu&logoColor=white)](https://releases.ubuntu.com/26.04/)
[![CUDA 11.2](https://img.shields.io/badge/CUDA_11.2-GPU_Acceleration-blue?logo=nvidia&logoColor=white)](https://developer.nvidia.com/cuda-toolkit)
[![Gazebo](https://img.shields.io/badge/Gazebo-Simulator-blue)](http://gazebosim.org/)
[![FlexBE](https://img.shields.io/badge/FlexBE-Behavior_Engine-blue)](http://flexbe.github.io/)
[![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-CI%2FCD-blue?logo=githubactions&logoColor=white)](https://docs.github.com/actions)
[![Git](https://img.shields.io/badge/Git-Repository-blue?logo=git&logoColor=white)](https://git-scm.com/)
[![VS Code](https://img.shields.io/badge/VS_Code-Editor-blue?logo=visualstudiocode&logoColor=white)](https://code.visualstudio.com/)
[![GitHub Copilot](https://img.shields.io/badge/GitHub_Copilot-Agent-blue?logo=githubcopilot&logoColor=white)](https://github.com/features/copilot)

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache_2.0-green)](LICENSE)

> [!TIP]
> Join the [SDE Community](https://coarobo.com/en/sde-community/) and help drive this open-source effort forward.
> For a production-ready solution with advanced features, explore [Coarobo](https://coarobo.com/).

## 🤖 Supported Robot Platforms

Each canonical platform lives in a repository of its own, which OpenRoSDE finds by name once it is cloned into `extensions/`, as the [Quick Start](#-quick-start) shows.
Every platform runs ROS 1 Noetic, apart from `turtlebot3-ros2`, which runs ROS 2 Lyrical beside it, as the [ROS 2](docs/ros2.md) guide describes.

| Platform | Robot | Repository | Documentation |
| --- | --- | --- | --- |
| `turtlebot3` | [Robotis TurtleBot3 (Waffle Pi)](https://emanual.robotis.com/docs/en/platform/turtlebot3/overview/) | [https://github.com/openrosde/openrosde-platform-turtlebot3](https://github.com/openrosde/openrosde-platform-turtlebot3) | [docs/robot-platforms/turtlebot3.md](https://github.com/openrosde/openrosde-platform-turtlebot3/blob/main/docs/robot-platforms/turtlebot3.md) |
| `turtlebot3-ros2` | [Robotis TurtleBot3 (Waffle Pi)](https://emanual.robotis.com/docs/en/platform/turtlebot3/overview/) on ROS 2 | [https://github.com/openrosde/openrosde-platform-turtlebot3](https://github.com/openrosde/openrosde-platform-turtlebot3) | [docs/robot-platforms/turtlebot3-ros2.md](https://github.com/openrosde/openrosde-platform-turtlebot3/blob/main/docs/robot-platforms/turtlebot3-ros2.md) |
| `ur5e` | [Universal Robots UR5e](https://www.universal-robots.com/products/ur5e/) | [https://github.com/openrosde/openrosde-platform-ur5e](https://github.com/openrosde/openrosde-platform-ur5e) | [docs/robot-platforms/ur5e.md](https://github.com/openrosde/openrosde-platform-ur5e/blob/main/docs/robot-platforms/ur5e.md) |
| `fetch` | [Fetch Robotics Fetch](https://fetchrobotics.github.io/docs/) | [https://github.com/openrosde/openrosde-platform-fetch](https://github.com/openrosde/openrosde-platform-fetch) | [docs/robot-platforms/fetch.md](https://github.com/openrosde/openrosde-platform-fetch/blob/main/docs/robot-platforms/fetch.md) |
| `sciurus17` | [RT Sciurus17](https://rt-net.jp/products/sciurus17/) | [https://github.com/openrosde/openrosde-platform-sciurus17](https://github.com/openrosde/openrosde-platform-sciurus17) | [docs/robot-platforms/sciurus17.md](https://github.com/openrosde/openrosde-platform-sciurus17/blob/main/docs/robot-platforms/sciurus17.md) |
| `cobotta` | [Denso COBOTTA](https://www.denso-wave.com/en/robot/product/collaborative/cobotta.html) | [https://github.com/openrosde/openrosde-platform-cobotta](https://github.com/openrosde/openrosde-platform-cobotta) | [docs/robot-platforms/cobotta.md](https://github.com/openrosde/openrosde-platform-cobotta/blob/main/docs/robot-platforms/cobotta.md) |
| `hsr` | [Toyota HSR (Human Support Robot)](https://github.com/hsr-project) | [https://github.com/openrosde/openrosde-platform-hsr](https://github.com/openrosde/openrosde-platform-hsr) | [docs/robot-platforms/hsr.md](https://github.com/openrosde/openrosde-platform-hsr/blob/main/docs/robot-platforms/hsr.md) |

## 💻 Supported Software Platforms

| Platform | GPU Acceleration | Notes |
| --- | --- | --- |
| Ubuntu 24.04 LTS (native) | Nvidia GPU via [Nvidia Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/index.html) | Recommended setup |
| Ubuntu 24.04 LTS on Windows 11 via [WSL 2](https://learn.microsoft.com/en-us/windows/wsl/) | [WSLg](https://github.com/microsoft/wslg) D3D12 Mesa driver | Lower 3D performance than native |

## 🔍 Overview

```mermaid
---
config:
  theme: neutral
---
flowchart TD
    subgraph host["Ubuntu development machine"]
        env["'.env' / '.env.custom'"]
        loader["'scripts/load-openrosde-env.bash'"]
        setup["'SETUP-DEVEL-MACHINE.bash'"]
        build["'BUILD-DOCKER-IMAGE.bash'"]
        run["'RUN-DOCKER-CONTAINER.bash'"]
        env --> loader
        setup -->|"Install Docker, CUDA, etc."| build
        loader --> build
        loader --> run
    end

    subgraph images["Docker images (Layer 1 → Layer 2 → Layer 3)"]
        base["'openrosde-base'<br/>(L1: Ubuntu 20.04, ROS Noetic,<br/>Gazebo, FlexBE, etc.)"]
        platform["'#lt;platform#gt;-devel'<br/>(L2: one per platform, built from<br/>the folder that holds the platform)"]
        base --> platform
        user["'user-devel'<br/>(L3: user overlay)"]
        platform --> user
    end

    subgraph container["Docker container"]
        shared["'openrosde_catkin_ws'<br/>(shared packages)"]
        platws["'OPENROSDE_ROBOT_PLATFORM_catkin_ws'<br/>(platform packages)"]
        userws["'user_catkin_ws'<br/>(user overlay packages)"]
        rosenv["ROS environment<br/>(Gazebo, RViz, FlexBE, etc.)"]
        shared --> rosenv
        platws --> rosenv
        userws --> rosenv
    end

    build -->|"Build / pull images"| images
    images -.->|"Selected by<br/>'OPENROSDE_ROBOT_PLATFORM'"| container
    run -->|"Enter container shell"| container
```

The Docker image stack has three layers.
**Layer 1** (`openrosde-base`) provides the shared ROS, Gazebo, and FlexBE toolchain.
**Layer 2** (`<platform>-devel`) adds the robot-specific packages selected by `OPENROSDE_ROBOT_PLATFORM`, from the repository of the platform cloned into `extensions/`.
**Layer 3** (`user-devel`) is the user overlay, where you add your own packages and customizations without touching the platform images.
A platform on ROS 2 builds on **Layer 1** `openrosde-base-ros2` instead, Ubuntu 26.04 with ROS 2 Lyrical, with the colcon workspaces of `ros2/`, as the [ROS 2](docs/ros2.md) guide describes.
Extensions cloned into `extensions/` can add their own layers between Layers 2 and 3, as the [Extensions](docs/extensions.md) guide explains.

## 🚀 Quick Start

> [!NOTE]
> The whole OpenRoSDE is containerized/virtualized using [Docker](https://www.docker.com/).
> This ensures that all the contributors work in the exact same software environment.

1. Clone and set up:

    ```shell
    sudo apt-get update && sudo apt-get install -y git
    git clone https://github.com/openrosde/openrosde.git && cd openrosde/
    bash ./SETUP-DEVEL-MACHINE.bash
    sudo reboot
    ```

2. Clone a robot platform into `extensions/`, then switch to it (the default `.env` selects `turtlebot3`):

    ```shell
    git clone https://github.com/openrosde/openrosde-platform-turtlebot3.git extensions/openrosde-platform-turtlebot3
    bash ./SWITCH-ROBOT-PLATFORM.bash turtlebot3
    ```

    > [!NOTE]
    > The core holds no TurtleBot3, since each canonical platform lives in a repository of its own, as [Supported Robot Platforms](#-supported-robot-platforms) lists.
    > The entry scripts stop with the commands that clone the platform when `.env` or `.env.custom` selects a platform cloned nowhere.

3. Build the Docker image:

    ```shell
    bash ./BUILD-DOCKER-IMAGE.bash
    ```

4. Run the Docker container:

    ```shell
    bash ./RUN-DOCKER-CONTAINER.bash
    ```

5. Inside the container, initialize the environment:

    ```shell
    openrosde-initialize-new-container
    ```

6. Exit the container (`Ctrl+d`) and launch the multi-terminal session from the Ubuntu development machine:

    ```shell
    bash ./RUN-TMUX-SESSION.bash
    ```

    The session opens its tabs in the same standard order on every platform, `robot`, `extra`, `tools`, `user`, and `host`, and leaves out a tab with no pane.
    Its first pane shows how to use its tabs and panes, which `openrosde-help` prints again in any shell of the container.
    The Terminator layout of earlier releases still opens with `bash ./RUN-TERMINATOR-TERMINAL.bash`, until [#3](https://github.com/openrosde/openrosde/issues/3) removes it.

For detailed instructions, see the [Basic Usage](docs/basic-usage.md) guide.
For advanced features, see the [Advanced Usage](docs/advanced-usage.md) guide.

## 📁 Directory Structure

```
.env                                     # Default platform configuration.
env/
  user.env                               # User overlay environment template (reference).
  openrosde-ros2.env                     # Settings of ROS 2, which a platform on ROS 2 repeats in its template.
SETUP-DEVEL-MACHINE.bash                 # Host machine setup script.
BUILD-DOCKER-IMAGE.bash                  # Docker image build/pull script.
RUN-DOCKER-CONTAINER.bash                # Docker container run/enter script.
RUN-TMUX-SESSION.bash                    # Multi-terminal 'tmux' session script.
RUN-TERMINATOR-TERMINAL.bash             # Multi-terminal Terminator launcher script (until 'tmux' replaces it).
BRINGUP-ROS-ROBOT.bash                   # Robot bringup script.
RESTART-CHRONY-SERVICE.bash              # Host and robot clock sync script.
SWITCH-ROBOT-PLATFORM.bash               # Platform switching script.
SWITCH-ROBOT-SETUP.bash                  # Setup switching script, which clones the extensions of a setup.
scripts/
  load-openrosde-env.bash                # Shared environment loader.
  load-extension-paths.bash              # Resolves the files of the platform and the extensions.
  build-extension-layers.bash            # Builds the Docker layers of the active extensions.
  list-robot-platforms.bash              # Lists the platforms found by name.
  list-robot-setups.bash                 # Lists the setups found by name.
  update-git-submodules.bash             # Updates the Git submodules of the core and the extensions, and applies their patches.
  generate-mesh-glbs.bash                # Gives every robot mesh of the workspaces its GLB file.
  print-tmux-splash.bash                 # Prints the splash and the help of the 'tmux' sessions.
  <platform>/                            # Optional platform scripts (shell, bringup, Chrony).
docker/
  docker-compose.yaml                    # Docker service definitions.
  docker-compose-user.yaml               # User overlay (always loaded).
  docker-compose-nvidia.yaml             # GPU overlay for Nvidia support.
  docker-compose-wsl.yaml                # GPU overlay for WSL 2 support.
  openrosde-base/                        # Shared base Docker image of ROS 1.
    Dockerfile
    patches/                             # Patches of the file service of ROS#.
    scripts/                             # Container helper scripts, shared by both base images.
  openrosde-base-ros2/                   # Shared base Docker image of ROS 2.
    Dockerfile
    patches/                             # Patches of the file service of ROS# on ROS 2.
  openrosde-mesh2glb/                    # Converter image of the robot meshes into GLB files.
    Dockerfile
    scripts/                             # Converter scripts.
  user-devel/                            # User overlay image (Layer 3, runtime container).
    Dockerfile
ros/
  openrosde_catkin_ws/                   # Shared Catkin workspace.
  user_catkin_ws/                        # User overlay Catkin workspace (openrosde_user_launch, openrosde_user_behaviors).
ros2/
  openrosde_colcon_ws/                   # Shared colcon workspace of ROS 2.
  user_colcon_ws/                        # User overlay colcon workspace of ROS 2 (openrosde_user_launch).
docs/                                    # Documentation.
  basic-usage.md
  advanced-usage.md
  user-overlay.md
  extensions.md
  ros2.md
  robot-models.md
tmux/
  openrosde.panes                        # Panes of the core in every 'tmux' session on ROS 1.
  openrosde-ros2.panes                   # Panes of the core in every 'tmux' session on ROS 2.
patches/                                 # Submodule patch files.
extensions/                              # Extensions cloned from their own repositories (ignored by Git), such as 'openrosde-platform-<platform>/'.
tests/                                   # Test suites of the scripts, run by 'tests/run.bash'.
gitlab-ci/                               # Scripts of the CI, which the workflows of GitHub Actions run, in a folder named after the GitLab CI of the archive.
.github/                                 # GitHub Actions workflows, their composite actions, and their scripts.
```

## 📖 Documentation

| Document | Description |
| --- | --- |
| [Basic Usage](docs/basic-usage.md) | Full setup guide: prerequisites, installation, build, and run |
| [Advanced Usage](docs/advanced-usage.md) | Bash functions, the `tmux` sessions and their standard tabs, Docker configuration, environment variables |
| [Supported Robot Platforms](#-supported-robot-platforms) | The canonical platforms, each documented in its own repository |
| [User Overlay](docs/user-overlay.md) | Add your own ROS packages, Docker layer, and environment variables without forking OpenRoSDE, run from the tab `user` of the `tmux` sessions |
| [Extensions](docs/extensions.md) | Add a platform, a device, or other packages from a repository of their own, public or private, cloned into `extensions/` |
| [Robot Models](docs/robot-models.md) | Serve the robot model to clients of `rosbridge`: the file service, why the meshes travel as GLB files, their size limit, and how to generate them |
| [ROS 2](docs/ros2.md) | Run a platform on ROS 2 beside those on ROS 1: the base image, the colcon workspaces, the network, and the checks of the CI |

## 📄 Related Publications

Summaries of the development history, requirements, vision, and goals of OpenRoSDE have been published in the following papers:
- International journals:
  - L. El Hafi, G. A. Garcia Ricardez, F. von Drigalski, Y. Inoue, M. Yamamoto, and T. Yamamoto, "**Software Development Environment for Collaborative Research Workflow in Robotic System Integration**", in *RSJ Advanced Robotics (AR), Special Issue on Software Framework for Robot System Integration*, vol. 36, no. 11, pp. 533-547, Jun. 3, 2022. DOI: [10.1080/01691864.2022.2068353](https://doi.org/10.1080/01691864.2022.2068353)
- Domestic conferences:
  - L. El Hafi and T. Yamamoto, "**Toward the Public Release of a Software Development Environment for Human Support Robots**", in *Proceedings of 2020 Annual Conference of the Robotics Society of Japan (RSJ 2020)*, ref. RSJ2020AC3E1-01, pp. 1-2, (Virtual), Oct. 9, 2020.
  - L. El Hafi, S. Matsuzaki, S. Itadera, and T. Yamamoto, "**Deployment of a Containerized Software Development Environment for Human Support Robots**", in *Proceedings of 2019 Annual Conference of the Robotics Society of Japan (RSJ 2019)*, ref. RSJ2019AC3K1-03, pp. 1-2, Tokyo, Japan, Sep. 3, 2019.
  - L. El Hafi, Y. Hagiwara, and T. Taniguchi, "**Abstraction-Rich Workflow for Agile Collaborative Development and Deployment of Robotic Solutions**", in *Proceedings of 2018 Annual Conference of the Robotics Society of Japan (RSJ 2018)*, ref. RSJ2018AC3D3-02, pp. 1-3, Kasugai, Japan, Sep. 5, 2018.

> [!NOTE]
> Cite these papers if you are using OpenRoSDE to implement your research!
> It is crucially important to disseminate OpenRoSDE across the robotics research community.

## 🔗 External Resources

- Coarobo GK:
  - Official website: [https://coarobo.com/](https://coarobo.com/)
  - GitHub organization: [https://github.com/coarobo](https://github.com/coarobo)
- OpenRoSDE:
  - GitHub organization: [https://github.com/openrosde](https://github.com/openrosde)
  - Archive of the versions before 3.0.0: [https://gitlab.com/coarobo/SDE](https://gitlab.com/coarobo/SDE)

## 🐛 Reporting Issues

Please report any issue or future work using the GitHub issue tracker: [https://github.com/openrosde/openrosde/issues](https://github.com/openrosde/openrosde/issues).
Report an issue of a platform or a device in its own repository, such as [https://github.com/openrosde/openrosde-platform-fetch/issues](https://github.com/openrosde/openrosde-platform-fetch/issues) for the Fetch.
Report a security vulnerability privately, as the security policy of the organization describes: [https://github.com/openrosde/.github/blob/main/SECURITY.md](https://github.com/openrosde/.github/blob/main/SECURITY.md).

## 🤝 Contributing

- This repository uses explicit commit messages following the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) specification.
- This project follows [Semantic Versioning](https://semver.org/) for releases.
- This project follows the [Make a README](https://www.makeareadme.com/) guidelines for documentation structure.
- This project relies on [`AGENTS.md`](AGENTS.md) for coding conventions and instructions provided to AI agents.

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for detailed contribution guidelines, including a step-by-step guide for adding support for a new robot platform.

## 👥 Authors & Acknowledgment

### 🔧 Maintainers

- **Lotfi El Hafi** (lotfi@coarobo.com)
- Sebastian Carrera (sebastian@coarobo.com)

### ✍️ Authors

- **Lotfi El Hafi**
- Felix von Drigalski
- Gustavo Alfonso Garcia Ricardez
- Masaki Yamamoto
- Shigemichi Matsuzaki
- Shunki Itadera
- Tadahiro Taniguchi
- Takashi Yamamoto
- Yoshinobu Hagiwara
- Yuki Inoue

### 🙏 Contributors

- Hiroyuki Okada
- Kazuki Miyzawa
- Keisuke Takeshita
- Kensuke Iwata
- Luis Contreras
- Nobuyuki Matsuno
- Takato Horii
- Tatsuya Matsushima
- Tomohiro Ono
- Yaonan Zhu
- Yoshiaki Asahara

## ⚖️ License

```
Copyright 2019 Coarobo GK

Licensed under the Apache License, Version 2.0
```

See [`LICENSE`](LICENSE) for details.
The versions before 3.0.0 were published under the MIT License, whose notice [`NOTICE`](NOTICE) keeps.

## 📜 Third-Party Software

The OpenRoSDE Docker images bundle third-party robotics middleware, drivers, and simulation assets, each governed by its own license.
Each platform repository records the licenses of its platform in its `NOTICE`, and some of them restrict commercial use:

| Platform | Notice | Notable terms |
| --- | --- | --- |
| `turtlebot3` | [https://github.com/openrosde/openrosde-platform-turtlebot3/blob/main/NOTICE](https://github.com/openrosde/openrosde-platform-turtlebot3/blob/main/NOTICE) | TurtleBot3 packages of ROBOTIS under Apache-2.0 |
| `fetch` | [https://github.com/openrosde/openrosde-platform-fetch/blob/main/NOTICE](https://github.com/openrosde/openrosde-platform-fetch/blob/main/NOTICE) | `fetch_description` in the image `fetch-devel` under CC BY-NC-SA 4.0 |
| `sciurus17` | [https://github.com/openrosde/openrosde-platform-sciurus17/blob/main/NOTICE](https://github.com/openrosde/openrosde-platform-sciurus17/blob/main/NOTICE) | `sciurus17_description` under the non-commercial license of RT Corporation |
| `cobotta` | [https://github.com/openrosde/openrosde-platform-cobotta/blob/main/NOTICE](https://github.com/openrosde/openrosde-platform-cobotta/blob/main/NOTICE) | `denso_cobotta_ros` and the four patches of the platform under GPL-2.0-or-later |
| `ur5e` | [https://github.com/openrosde/openrosde-platform-ur5e/blob/main/NOTICE](https://github.com/openrosde/openrosde-platform-ur5e/blob/main/NOTICE) | The default kinematics of `ur_description` under BSD 3-Clause, and the meshes of some UR models in the image `ur5e-devel` under the terms of Universal Robots A/S |
| `hsr` | [https://github.com/openrosde/openrosde-platform-hsr/blob/main/NOTICE](https://github.com/openrosde/openrosde-platform-hsr/blob/main/NOTICE) | `tmc_wrs_binary` in the image `hsr-devel` under BSD 3-Clause Clear, and `hsrb_meshes` under CC BY-NC-ND 4.0 |
| All | [ROS Noetic](https://www.ros.org/), [Gazebo](http://gazebosim.org/), [FlexBE](http://flexbe.github.io/), and platform-specific upstream packages | Per upstream (BSD, Apache 2.0, MIT, etc.) |
| All | [ROS#](https://github.com/siemens/ros-sharp) `file_server` `2.3.1` (Siemens AG), built from source in the base image with the patches of `docker/openrosde-base/patches/ros-sharp/` | [Apache 2.0](https://github.com/siemens/ros-sharp/blob/2.3.1/LICENSE.md) |
| All | [`trimesh`](https://github.com/mikedh/trimesh) and [`pycollada`](https://github.com/pycollada/pycollada) in the converter image `openrosde-mesh2glb` | [MIT](https://github.com/mikedh/trimesh/blob/main/LICENSE.md) and [BSD 3-Clause](https://github.com/pycollada/pycollada/blob/master/COPYING) |

See the `NOTICE` and `docs/robot-platforms/<platform>.md` of each platform repository for its licensing details.
