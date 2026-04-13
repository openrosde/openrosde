# Software Development Environment (SDE)

Open-source reference implementation of the Software Development Environment (SDE) described in "**Software Development Environment for Collaborative Research Workflow in Robotic System Integration**" (DOI: [10.1080/01691864.2022.2068353](https://doi.org/10.1080/01691864.2022.2068353)) and maintained by [Coarobo GK](https://coarobo.com/).

[![Docker](https://img.shields.io/badge/Docker-Containerization-blue?logo=docker&logoColor=white)](https://www.docker.com/)
[![ROS Noetic](https://img.shields.io/badge/ROS_Noetic-Framework-blue?logo=ros&logoColor=white)](http://wiki.ros.org/noetic)
[![Ubuntu 20.04](https://img.shields.io/badge/Ubuntu_20.04-Container_OS-blue?logo=ubuntu&logoColor=white)](https://releases.ubuntu.com/20.04/)
[![CUDA 11.2](https://img.shields.io/badge/CUDA_11.2-GPU_Acceleration-blue?logo=nvidia&logoColor=white)](https://developer.nvidia.com/cuda-toolkit)
[![Gazebo](https://img.shields.io/badge/Gazebo-Simulator-blue)](http://gazebosim.org/)
[![FlexBE](https://img.shields.io/badge/FlexBE-Behavior_Engine-blue)](http://flexbe.github.io/)
[![GitLab CI](https://img.shields.io/badge/GitLab_CI-CI%2FCD-blue?logo=gitlab&logoColor=white)](https://docs.gitlab.com/ee/ci/)
[![Git](https://img.shields.io/badge/Git-Repository-blue?logo=git&logoColor=white)](https://git-scm.com/)
[![VS Code](https://img.shields.io/badge/VS_Code-Editor-blue?logo=visualstudiocode&logoColor=white)](https://code.visualstudio.com/)
[![GitHub Copilot](https://img.shields.io/badge/GitHub_Copilot-Agent-blue?logo=githubcopilot&logoColor=white)](https://github.com/features/copilot)

[![License: MIT](https://img.shields.io/badge/License-MIT-green)](LICENSE)

## Content

[[_TOC_]]

## Supported Platforms

| Platform | Robot | Documentation |
| --- | --- | --- |
| `turtlebot3` | Robotis [TurtleBot3 (Waffle Pi)](https://emanual.robotis.com/docs/en/platform/turtlebot3/overview/) | [docs/platforms/turtlebot3.md](docs/platforms/turtlebot3.md) |
| `ur5e` | [Universal Robot UR5e](https://www.universal-robots.com/products/ur5e/) | [docs/platforms/ur5e.md](docs/platforms/ur5e.md) |

## Quick Start

> **Note:**
  The whole SDE is containerized/virtualized using [Docker](https://www.docker.com/).
  This ensures that all the contributors work in the exact same software environment.

1. Clone and set up:

    ```shell
    sudo apt-get update && sudo apt-get install -y git
    cd ~/ && git clone https://gitlab.com/coarobo/SDE.git
    cd ~/SDE/ && bash ./SETUP-DEVEL-MACHINE.bash
    sudo reboot
    ```

2. Build the Docker image:

    ```shell
    cd ~/SDE/ && bash ./BUILD-DOCKER-IMAGE.bash
    ```

3. Run the Docker container:

    ```shell
    cd ~/SDE/ && bash ./RUN-DOCKER-CONTAINER.bash
    ```

4. Inside the container, initialize the environment:

    ```shell
    sde-get-fully-started
    ```

For detailed instructions, see the [Getting Started](docs/getting-started.md) guide.
For advanced features, see the [Advanced Usage](docs/advanced-usage.md) guide.

## Directory Structure

```
.env                                     # Default platform configuration.
.env.custom.example                      # Template for user overrides.
SETUP-DEVEL-MACHINE.bash                 # Host machine setup script.
BUILD-DOCKER-IMAGE.bash                  # Docker image build/pull script.
RUN-DOCKER-CONTAINER.bash                # Docker container run/enter script.
RUN-TERMINATOR-TERMINAL.bash             # Multi-terminal launcher script.
BRINGUP-ROS-ROBOT.bash                   # Robot bringup script.
scripts/
  load-sde-env.bash                      # Shared environment loader.
docker/
  docker-compose.yaml                    # Docker service definitions.
  docker-compose-gpu.yaml                # GPU overlay for Nvidia support.
  sde-base/                              # Shared base Docker image.
    Dockerfile
    scripts/                             # Container helper scripts.
  turtlebot3-devel/                      # TurtleBot3 platform image.
    Dockerfile
  ur5e-devel/                            # UR5e platform image.
    Dockerfile
ros/
  sde_catkin_ws/                          # Shared Catkin workspace.
  turtlebot3_catkin_ws/                   # TurtleBot3 Catkin workspace.
  ur5e_catkin_ws/                         # UR5e Catkin workspace.
docs/                                    # Documentation.
  getting-started.md
  advanced-usage.md
  platforms/
    turtlebot3.md
    ur5e.md
terminator/
  config                                 # Terminator layout configuration.
gitlab-ci/                               # GitLab CI/CD scripts.
```

## Documentation

| Document | Description |
| --- | --- |
| [Getting Started](docs/getting-started.md) | Full setup guide: prerequisites, installation, build, and run |
| [Advanced Usage](docs/advanced-usage.md) | Bash functions, multiple terminals, Docker configuration, environment variables |
| [TurtleBot3](docs/platforms/turtlebot3.md) | TurtleBot3 robot configuration, installation, and operation |
| [UR5e](docs/platforms/ur5e.md) | UR5e robot setup, network, ROS communication, and operation |

## Related Publications

Summaries of the development history, requirements, vision, and goals of the SDE have been published in the following papers:
- International journals:
  - L. El Hafi, G. A. Garcia Ricardez, F. von Drigalski, Y. Inoue, M. Yamamoto, and T. Yamamoto, "**Software Development Environment for Collaborative Research Workflow in Robotic System Integration**", in *RSJ Advanced Robotics (AR), Special Issue on Software Framework for Robot System Integration*, vol. 36, no. 11, pp. 533-547, Jun. 3, 2022. DOI: [10.1080/01691864.2022.2068353](https://doi.org/10.1080/01691864.2022.2068353)
- Domestic conferences:
  - L. El Hafi and T. Yamamoto, "**Toward the Public Release of a Software Development Environment for Human Support Robots**", in *Proceedings of 2020 Annual Conference of the Robotics Society of Japan (RSJ 2020)*, ref. RSJ2020AC3E1-01, pp. 1-2, (Virtual), Oct. 9, 2020.
  - L. El Hafi, S. Matsuzaki, S. Itadera, and T. Yamamoto, "**Deployment of a Containerized Software Development Environment for Human Support Robots**", in *Proceedings of 2019 Annual Conference of the Robotics Society of Japan (RSJ 2019)*, ref. RSJ2019AC3K1-03, pp. 1-2, Tokyo, Japan, Sep. 3, 2019.
  - L. El Hafi, Y. Hagiwara, and T. Taniguchi, "**Abstraction-Rich Workflow for Agile Collaborative Development and Deployment of Robotic Solutions**", in *Proceedings of 2018 Annual Conference of the Robotics Society of Japan (RSJ 2018)*, ref. RSJ2018AC3D3-02, pp. 1-3, Kasugai, Japan, Sep. 5, 2018.

> **Note:**
  Cite these papers if you are using the SDE to implement your research!
  It is crucially important to disseminate the SDE across the robotics research community.

## External Resources

- Coarobo GK:
  - Official website: [https://coarobo.com/](https://coarobo.com/)
  - GitLab group: [https://gitlab.com/coarobo](https://gitlab.com/coarobo)
  - GitHub organization: [https://github.com/coarobo](https://github.com/coarobo)
- Robotis TurtleBot3 (Waffle Pi):
  - Official manual: [https://emanual.robotis.com/docs/en/platform/turtlebot3/overview/](https://emanual.robotis.com/docs/en/platform/turtlebot3/overview/)
  - GitHub repository: [https://github.com/ROBOTIS-GIT/turtlebot3](https://github.com/ROBOTIS-GIT/turtlebot3)
  - ROS wiki: [http://wiki.ros.org/turtlebot3](http://wiki.ros.org/turtlebot3)
- Universal Robot UR5e:
  - Official website: [https://www.universal-robots.com/products/ur5e/](https://www.universal-robots.com/products/ur5e/)
  - ROS Driver: [https://github.com/UniversalRobots/Universal_Robots_ROS_Driver](https://github.com/UniversalRobots/Universal_Robots_ROS_Driver)

## Reporting Issues

Please report any issue or future work using the GitLab issue tracker: [https://gitlab.com/coarobo/SDE/issues](https://gitlab.com/coarobo/SDE/issues).

## Contributing

This repository uses explicit commit messages following the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) specification.
This project relies on [`AGENTS.md`](AGENTS.md) for project context and instructions provided to AI agents and coding assistants.

## Authors & Acknowledgment

- Lotfi El Hafi (lotfi@coarobo.com)
- Sebastian Carrera (sebastian@coarobo.com)
- Gustavo Alfonso Garcia Ricardez
- Felix von Drigalski
- Yukiyasu Domae
- Masaki Yamamoto
- Tadahiro Yamamoto

## License

```
MIT License

Copyright (c) 2019 Coarobo GK
```

See [`LICENSE`](LICENSE) for details.
