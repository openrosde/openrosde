# AGENTS.md

This file contains instructions for AI coding agents working on this project.

## Project Overview

This project is OpenRoSDE, read "Open Robotic SDE", the open-source reference implementation of the Software Development Environment (SDE) for collaborative robotics research (see `README.md` for details).
It provides a containerized, multi-platform development environment based on Docker, ROS, and Gazebo that supports multiple robot platforms (TurtleBot3, UR5e, Fetch, Sciurus17, COBOTTA, HSR) through a shared configuration system, with every platform in a repository of its own, cloned into `extensions/`.
It is being split into a platform-agnostic core with extensions, as [OpenRoSDE Split](#openrosde-split) describes, so read that section before changing anything.

### Tool Chain

- Containerization: [Docker](https://www.docker.com/) (with [Docker Compose](https://github.com/docker/compose)).
- GPU Acceleration: [Nvidia Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/index.html), [CUDA](https://developer.nvidia.com/cuda-toolkit) 11.2.
- Container OS: [Ubuntu](https://ubuntu.com/) 20.04 (Focal Fossa) on ROS 1, and [Ubuntu](https://ubuntu.com/) 26.04 (Resolute Raccoon) on ROS 2.
- Robotics Framework: [ROS](http://www.ros.org/) Noetic, and [ROS 2](https://docs.ros.org/en/lyrical/) Lyrical Luth beside it for the platforms that declare it (see [ROS 2](#ros-2)).
- Simulator: [Gazebo](http://gazebosim.org/).
- Visualization: [Rviz](https://github.com/ros-visualization/rviz).
- Behavior Engine: [FlexBE](http://flexbe.github.io/).
- Build System: [catkin](https://wiki.ros.org/catkin) (via `catkin build`) on ROS 1, and [colcon](https://colcon.readthedocs.io/) (via `colcon build`) on ROS 2.
- Multi-Terminal: [tmux](https://github.com/tmux/tmux/wiki), and [Terminator](https://gnometerminator.blogspot.com/) until `tmux` replaces it.
- Scripting: [Bash](https://www.gnu.org/software/bash/).
- Configuration: `.env` / `.env.custom` files.
- CI/CD: [GitHub Actions](https://docs.github.com/actions), whose workflows run the scripts of `gitlab-ci/`, a folder named after the GitLab CI that ran the versions before 3.0.0, until #13 renames it.
- Repository: [Git](https://git-scm.com/) (versioning), [GitHub](https://github.com/) (hosting).
- Editor: [VS Code](https://code.visualstudio.com/).
- Agents: [Claude Code](https://claude.com/claude-code), [GitHub Copilot](https://github.com/features/copilot).
- License: [Apache License 2.0](LICENSE) from version 3.0.0, with a [`NOTICE`](NOTICE) that keeps the MIT License of the earlier versions.

## OpenRoSDE Split

On 2026-10-10 the maintainers approved the split of the SDE into OpenRoSDE, read "Open Robotic SDE": a platform-agnostic open core, with platforms, devices, and extensions around it, composed into setups.
The steps were tracked as issues 37 to 42 of the milestone `Split the SDE into the OpenRoSDE core and its extensions`, and the ROS 2 work in the milestone `Run OpenRoSDE on ROS 2 beside ROS 1`, in the GitLab archive at `https://gitlab.com/coarobo/SDE`.
The issues still open moved to GitHub on 2026-10-16: the ROS 2 work is #2, the rest of the split, the retirement of Terminator included, is #3, and the follow-up of the review of the CI is #4.
The reasoning, the full plan, and the state of the work live in the maintainers' note `Shin-Coarobo OpenRoSDE`, which is not public.

### Target Shape

- The core keeps the entry scripts, `scripts/`, `gitlab-ci/`, the `openrosde-base` image, the generic Docker Compose files, and `ros/openrosde_catkin_ws/` with FlexBE and `openrosde_launch`.
- Every file named after a platform (`env/<platform>.env`, `docker/<platform>-devel/`, `docker/docker-compose-<platform>.yaml`, `ros/<platform>_catkin_ws/`, `terminator/<platform>.config`, `docs/robot-platforms/<platform>.md`, and its patches) moves to the repository of that platform, or to a device or a setup where it belongs to one.
- A platform is one robot as sold, with its public drivers, and each canonical robot moves to an `openrosde-platform-<name>` repository: `turtlebot3`, `fetch`, `sciurus17`, `cobotta`, `hsr`, and the plain Universal Robots UR5e.
  All six live in `https://github.com/openrosde/openrosde-platform-<name>`, each starting from one import commit that names the commit of the GitLab archive it comes from.
  The UR5e there is the plain robot, fixed to `world` with nothing on its flange, whose description package a setup replaces to mount its devices, as `docs/robot-platforms/ur5e.md` of `openrosde-platform-ur5e` describes.
  The package that `OPENROSDE_UR5E_DESCRIPTION_PACKAGE` names holds `urdf/ur5e_<environment>.xacro`, `config/ur5e/ur5e_<environment>.srdf`, `config/ur5e/ur5e_calibration.yaml`, and `config/rviz/ur5e_rviz_default.rviz`, and its xacro files call the macro `openrosde_ur5e` of `urdf/inc/ur5e_macro.xacro` of `openrosde_ur5e_launch`, so the robot is described once for every setup.
- A device is one upstream driver of hardware anyone can buy, such as a gripper, a camera, or an input device, with every model that driver supports, which names no robot and moves to a public `openrosde-device-<driver>` repository: first `openrosde-device-onrobot` for the OnRobot RG and VG grippers with the gripper action shim, `openrosde-device-realsense` for the RealSense cameras, and `openrosde-device-spacenav` for the 3Dconnexion SpaceMouse.
- A setup is one installation of a robot: it pins its platform, devices, and extensions, mounts the devices in the robot description, and holds the calibration, addresses, serial numbers, poses, layouts, and runbook of that installation alone.
  Each platform ships a default setup with the plain robot, and the user selects a setup rather than a platform.
- A setup is a template that any extension holds, named `<owner>-<platform>-<place>`, so one private extension of a company can hold its packages and the setups of all its robots.
- The Coarobo UR5e bench is the first setup, in the private extension of Coarobo, beside the bindings of Coarobo Sightline and Coarobo Viewport and the FastSAM segmentation, which have all left the core and its user layer, and the setup of a client takes the same shape in a private extension of that client.
- The Unity ROS TCP Endpoint left the core on 2026-10-15, once Coarobo Sightline reached the Fetch and the UR5e through `rosbridge` alone, so `openrosde_launch:rosbridge_server_default.launch` on port `9090` is the one transport the core provides to web and Unity clients.
- The user layer stays in the core as the template every extension starts from.
- Terminator gives way to `tmux` sessions built by `RUN-TMUX-SESSION.bash` from the panes each part declares, which ran on a real UR5e on 2026-10-16 (#5), and leaves the core with #3.
- The repository moved to GitHub as OpenRoSDE, `https://github.com/openrosde/openrosde`, under the Apache License 2.0 from version 3.0.0, with a `NOTICE` that keeps the MIT notice of the earlier code, while `https://gitlab.com/coarobo/SDE` stays as an archive, since papers cite it.
- ROS 2 comes beside ROS 1 and never replaces it, since robots such as the Fetch run only on ROS 1, and each platform declares the ROS it runs, as [ROS 2](#ros-2) describes (#2).

### Rules During the Split

- Keep every platform building and running on ROS 1 at every step, since the Coarobo UR5e bench runs its demos from `dev`.
- Add no Coarobo setup or product binding to the core, to a platform, or to a device, since they live in the private extension of Coarobo.
- Design every mechanism so that a private setup or extension, cloned from a private repository of a client, works exactly as a public one does.
  Hard-code no Git group, registry, or host, and give the setups and extensions of Coarobo no special case.
- `LICENSE` and the `<license>` of every `package.xml` of this repository are the Apache License 2.0 since the move to GitHub in version 3.0.0, with a `NOTICE` that keeps the MIT notice of the earlier versions.
  A new public repository of the split starts under the Apache License 2.0 too, with a `NOTICE` that reads `Copyright 2019 Coarobo GK`, keeps the MIT notice of the earlier code, and records the third-party software of that repository.
- Keep the interfaces that Coarobo products use working through every step, as [Interfaces Used by Coarobo Products](#interfaces-used-by-coarobo-products) lists.

### Interfaces Used by Coarobo Products

Coarobo Sightline and Coarobo Viewport reach the robot through the interfaces below, which the core and the public platforms start from the files named beside them.
The contract is kept in `Docs/robot-interface.md` of `coarobo/coarobo-sightline`, a private repository, and in the maintainers' `Shin-Coarobo OpenRoSDE` note.
Record a change of a topic name, a message type, a port, or the launch file that starts one of them in both places before making it.

- `/joint_states`, `/tf`, `/tf_static`, and `clock`: the bringup of each platform.
- `/servo_server/delta_twist_cmds`: MoveIt Servo, started by `openrosde_ur5e_teleop/launch/ur5e_teleop.launch` of `openrosde-platform-ur5e`, which `ur5e_teleop_default_<environment>.launch` includes.
- `fetch_ee_cmd_vel`, relayed to the Cartesian twist controller of the Fetch: `openrosde_fetch_teleop`, started by `fetch_teleop_default.launch`, both in `openrosde-platform-fetch`.
- Port `9090` of `rosbridge`: `openrosde_launch:rosbridge_server_default.launch`.
- The robot model: `robot_description` through `/rosapi/get_param`, and its meshes as GLB files through the service `/file_server/get_file` of the ROS# node `file_server` that `rosbridge_server_default.launch` starts, as [Robot Models](docs/robot-models.md) describes.

The other interfaces of the products, such as the gripper action, the camera relays, and the bridge of `/cmd_vel` of the UR5e bench, are started by the setups that use them, from public devices and the private bindings of Coarobo, and their contract is kept in the same two places.

### Parallel Work

- Coarobo Sightline (`coarobo/coarobo-sightline`) and Coarobo Viewport (`coarobo/coarobo-viewport`) are developed in their own repositories, often by other agents at the same time as one working here.
- An agent working here owns this repository and the extension repositories of the split, and leaves those two repositories to their own sessions.
- Coarobo Sightline reaches robots through `rosbridge`, as Coarobo Viewport does, so that it no longer depends on OpenRoSDE and runs on ROS 1 and ROS 2 alike.

## Directory Structure

- `docker/`: Docker images and container scripts.
  - `openrosde-base/`: Shared base image of ROS 1 (`Dockerfile`, helper `scripts/`, which both base images copy, and the patches of ROS# in `patches/ros-sharp/`).
  - `openrosde-base-ros2/`: Shared base image of ROS 2 (`Dockerfile`, and the patches of ROS# for `file_server2` in `patches/ros-sharp/`).
  - `user-devel/`: User overlay image (Layer 3, runtime container, which inherits from `${OPENROSDE_ROBOT_PLATFORM}-devel`, built locally only).
  - `docker-compose.yaml`: Base service definitions (defines `openrosde-base`, `openrosde-platform`, and `openrosde`).
  - `docker-compose-nvidia.yaml`: Nvidia GPU overlay.
  - `docker-compose-wsl.yaml`: WSL 2 GPU overlay.
  - `docker-compose-user.yaml`: User overlay (always loaded by `RUN-DOCKER-CONTAINER.bash`).
- `ros/`: ROS Catkin workspaces of the platforms on ROS 1.
  - `openrosde_catkin_ws/`: Shared workspace (FlexBE packages, `openrosde_launch/`).
  - `user_catkin_ws/`: User overlay workspace (`openrosde_user_launch/`, `openrosde_user_behaviors/`). Platform-agnostic.
- `ros2/`: colcon workspaces of the platforms on ROS 2.
  - `openrosde_colcon_ws/`: Shared workspace (`openrosde_launch/` with `rosbridge_server_default.launch.xml` and `rqt_suite_default.launch.xml`).
  - `user_colcon_ws/`: User overlay workspace (`openrosde_user_launch/` with `user_example_default.launch.xml`). Platform-agnostic.
- `scripts/`: Shared shell scripts (`load-openrosde-env.bash`, `load-openrosde-settings.bash`, `load-env-custom.bash`, `load-extension-paths.bash`, `build-extension-layers.bash`, `list-robot-platforms.bash`, `list-robot-setups.bash`, `generate-mesh-glbs.bash`, `print-tmux-splash.bash`, `update-git-submodules.bash`, `apply-submodule-patches.bash`), and the optional scripts of each setup or platform in `scripts/<setup or platform>/`.
- `patches/`: Patches of the Git submodules, mirroring the submodule paths.
- `env/`: `user.env` (user overlay reference template) and `openrosde-ros2.env` (the settings of ROS 2, which the template of a platform on ROS 2 repeats and the CI tests the core alone with), while every platform holds its own template in its repository.
- `extensions/`: Extensions, each a Git repository cloned into `extensions/<extension>/` and ignored by the Git of the core, apart from `README.md`, such as the canonical platforms `openrosde-platform-<platform>/` with the layout of the core.
  An extension of a company may split the units of several robots into parts, `extensions/<extension>/parts/<part>/`, each with the layout of the core and activated by its name.
- `docs/`: Documentation.
  - `basic-usage.md`: Full setup guide.
  - `advanced-usage.md`: Advanced features and configuration.
  - `user-overlay.md`: User overlay (Layer 3) usage and customization.
  - `extensions.md`: Extensions cloned into `extensions/`, and how OpenRoSDE finds their files.
  - `ros2.md`: Platforms on ROS 2 beside those on ROS 1.
  - `robot-models.md`: The robot model that `rosbridge` serves to its clients, with the GLB files of the meshes.
- `tmux/`: Pane files of the `tmux` sessions: `openrosde.panes` for the core on ROS 1 and `openrosde-ros2.panes` on ROS 2, while each platform holds its own `<platform>.panes` in its repository.
- `terminator/`: The injected copies of `RUN-TERMINATOR-TERMINAL.bash`, which creates the folder when a clone lacks it, while each platform holds its own Terminator layouts in its repository.
- `tests/`: Test suites of the scripts (`tests/suites/`), which `tests/run.bash` runs in a Debian container on scratch copies of the repository, with every outside command stubbed.
- `gitlab-ci/`: The scripts of the CI, which the workflows of `.github/` run, in a folder named after the GitLab CI that ran the versions before 3.0.0, until #13 renames it: the public extensions that the CI tests (`extensions.repos`), and the scripts that clone them (`clone-extensions.bash`), generate the pipeline of the platforms and setups found by name (`generate-ci-pipeline.bash`), build or reuse an image (`build-ci-image.bash`), check the GLB files of the converter (`check-mesh-glbs.bash`), test a setup (`test-catkin-workspaces.bash`, `generate-ci-mesh-glbs.bash`, `check-robot-model.bash`, `check-launch-files.bash`, `run-extension-checks.bash`), check that no script moves a robot (`check-no-motion.bash`), and publish the images (`publish-ci-images.bash`), with the allowlists of those checks (`allowed-duplicate-nodes.txt`, `allowed-simulation-launches.txt`).
  `generate-ci-pipeline.bash` prints the pipeline as a GitLab child pipeline whose jobs extend the hidden jobs of `openrosde-pipeline.yml`, which `.github/scripts/print-ci-matrices.bash` reads to build the matrices of the workflows, while `gitlab-ci.yml`, the parent pipeline of the GitLab archive, runs nowhere and stays for the checks of `tests/suites/test-ci-scripts.bash` until #13.
- `.github/`: GitHub Actions, which run the scripts of `gitlab-ci/`: the workflows (`workflows/checks.yml`, `workflows/ci.yml`, and the reusable `workflows/extension.yml`), the composite actions that free disk space, clone the extensions, and log in to the registry (`actions/`), and the scripts that wire the workflows to `gitlab-ci/` (`scripts/`).

## Agent Persona

You are a Robotics Research Engineer assisting in the maintenance of this multi-platform Docker-based ROS development environment.
You have expertise in Docker, ROS, Bash scripting, and Linux system administration.

## Architecture

### Multi-Platform Design

OpenRoSDE supports multiple robot platforms through a single codebase controlled by the `OPENROSDE_ROBOT_PLATFORM` variable in `.env`:

- A shared base Docker image contains common tools and dependencies: `openrosde-base` for the platforms on ROS 1, and `openrosde-base-ros2` for those on ROS 2, which `OPENROSDE_ROS_VERSION` of the template of the platform selects.
- Platform-specific images (`turtlebot3-devel`, `ur5e-devel`, `fetch-devel`, `sciurus17-devel`, `cobotta-devel`, `hsr-devel`) extend the base with robot-specific packages, each built from the folder that holds its platform, and the CI of the core still publishes them all under `OPENROSDE_DOCKER_REGISTRY`.
- A user overlay image (`user-devel`) extends the selected platform image and is the actual runtime container. It is platform-agnostic and built locally only, as `openrosde-local/<setup>/user-devel:latest`, a name that no `docker push` can publish.
- The active extensions may add Docker layers (`docker/<name>-devel/Dockerfile`, `FROM ${OPENROSDE_PARENT_IMAGE}`) between the platform image and the user overlay, built locally only by `scripts/build-extension-layers.bash`, in the order of the active folders, as `openrosde-local/<setup>/<name>-devel:latest`, and `OPENROSDE_USER_PARENT_IMAGE` names the last one (see `docs/extensions.md`).
  Never tag a local layer or the user overlay with the name of a registry, since one `docker push` would then publish it.
- The platform image is built from the folder that holds the platform, the core, an extension, or a part, so that its `COPY` instructions read from there, as those of a layer do.
- The Catkin workspaces are sourced in sequence: shared (`openrosde_catkin_ws`), platform-specific (`${OPENROSDE_ROBOT_PLATFORM}_catkin_ws`), the workspaces of the active extensions, then user overlay (`user_catkin_ws`).
  On ROS 2, the colcon workspaces of `ros2/` take their place in the same order, from `openrosde_colcon_ws` to `user_colcon_ws`, and `OPENROSDE_CATKIN_WORKSPACE_DIRS` keeps its name while it lists them.
- All scripts derive their behavior from `OPENROSDE_ROBOT_PLATFORM` and `OPENROSDE_ROBOT_EXTENSIONS` loaded via `scripts/load-openrosde-env.bash`.
- A platform lives in the core, in an extension cloned into `extensions/`, or in a part of an extension, and `scripts/load-extension-paths.bash` resolves where its files are, on the host and inside the container alike (see `docs/extensions.md`).
  An environment template `env/<name>.env` is looked up in the core first, then in every cloned extension followed by its parts.
  A file named after the setup comes from the folder of the setup, and a file named after the platform from the folder of the platform, then from the core, so a clone that is not active never supplies one.
  Workspaces, Docker layers, Docker Compose overlays, and `tmux` panes only come from the core, the platform, the extensions or parts of `OPENROSDE_ROBOT_EXTENSIONS`, and the setup, and an overlay or a pane file named after a platform or a setup that is not active is left out.

### Configuration System

- `.env`: Default configuration (committed to Git). Do not add fallback defaults (`:-`) in scripts, since all defaults live here.
- `.env.custom`: User overrides (Git-ignored, created from a platform template in `env/`).
- `scripts/load-openrosde-env.bash`: Shared loader sourced by all top-level `*.bash` scripts. Resolves `OPENROSDE_ROOT_DIR`, loads `.env`/`.env.custom`, and exports every `OPENROSDE_*` variable for Docker Compose interpolation and for the platform scripts.
- `scripts/load-openrosde-settings.bash`: Shared loader of the shell of the container and of the CI scripts that run in it. Loads `.env`/`.env.custom` and the paths of the extensions with every variable exported, so a script that the shell runs reads the same setup.
  It prints every `OPENROSDE_*` variable unless `OPENROSDE_QUIET=true`, and never prints the value of one whose name holds `PASSWORD`, `TOKEN`, or `SECRET`, so name every credential that way.

### Platform Switching

Switching platforms requires only running `bash ./SWITCH-ROBOT-PLATFORM.bash <platform>` (e.g., `bash ./SWITCH-ROBOT-PLATFORM.bash ur5e`), which switches to the default setup of the platform.
A setup is a template `env/<setup>.env` that declares `OPENROSDE_ROBOT_SETUP=<setup>` with its platform and extensions, in the core or in an extension, and `bash ./SWITCH-ROBOT-SETUP.bash <setup>` clones the repositories of its `env/<setup>.repos` with `vcstool` before copying it to `.env.custom` (see `docs/extensions.md`).
The template of every platform is its default setup and declares `OPENROSDE_ROBOT_SETUP=<platform>`.
`scripts/load-extension-paths.bash` falls back to the platform as the setup when the template of `OPENROSDE_ROBOT_SETUP` does not run the active platform, so a `.env.custom` written before setups existed keeps its platform files.
`RUN-DOCKER-CONTAINER.bash` automatically detects containers from a different platform under the same Docker project and runs `docker compose down` to cleanly remove them before starting the new platform's container.

### Docker Compose Service Targeting

`docker-compose.yaml` defines three services:
- `openrosde-base` (build-only shared base image, no `container_name`).
- `openrosde-platform` (build-only platform-specific image, no `container_name`, whose image is `<platform>-devel:${OPENROSDE_DOCKER_IMAGE_TAG}`, `main`, `dev`, or a release `vX.Y.Z`).
- `openrosde` (runtime user-overlay container, whose image is `openrosde-local/<setup>/user-devel:latest`, built locally only, inherits from `openrosde-platform` or from the last Docker layer of the extensions).

Always target the `openrosde` service explicitly with `docker compose up -d openrosde` to avoid accidentally starting the build-only services, which have no `container_name` and would cause naming conflicts.
`BUILD-DOCKER-IMAGE.bash` builds all three services in order: `openrosde-base` -> `openrosde-platform` -> `openrosde`. The `user-devel` image is always built locally and is never published by `gitlab-ci/publish-ci-images.bash`.

### Docker Compose Platform Overlays

Every platform has a Docker Compose overlay file (`docker-compose-<platform>.yaml`) that passes platform-specific environment variables to the container.
`RUN-DOCKER-CONTAINER.bash` automatically includes `docker-compose-${OPENROSDE_ROBOT_PLATFORM}.yaml` if the file exists, so new platforms can add their own overlay without modifying the script.
Platforms that do not yet require extra variables still have an overlay file for consistency.

### User Overlay (Layer 3)

The user overlay is a third Docker stage on top of `<platform>-devel`, intended for end-user customization without forking OpenRoSDE.
It is always built locally by `BUILD-DOCKER-IMAGE.bash`, never pushed to the registry, and platform-agnostic (the same overlay rebuilds on top of whichever `OPENROSDE_ROBOT_PLATFORM` is selected).

Components:
- `docker/user-devel/Dockerfile`: third-stage image. `FROM ${OPENROSDE_PLATFORM_IMAGE}` where `OPENROSDE_PLATFORM_IMAGE` defaults to `ghcr.io/openrosde/${OPENROSDE_ROBOT_PLATFORM}-devel:main`.
- `docker/docker-compose-user.yaml`: always loaded by `RUN-DOCKER-CONTAINER.bash` (no `if -f` guard). Exposes `OPENROSDE_USER_*` environment variables and is the place to add user-specific volume mounts.
- `ros/user_catkin_ws/`: last Catkin workspace, sourced after the platform workspace and those of the active extensions in `source-catkin-workspaces.bash`, built by `build-catkin-workspaces.bash` and rebuilt by `reset-catkin-workspaces.bash`.
- `ros/user_catkin_ws/src/openrosde_user_launch/`: starter launch package with `user_example_default.launch` and a `config/` directory (`rviz/`, `maps/`) for user assets.
- `ros/user_catkin_ws/src/openrosde_user_behaviors/`: starter FlexBE behaviors package with `User Example Behavior` (uses only `LogState` + `WaitState`, runs on every platform).
- `env/user.env`: reference template documenting `OPENROSDE_USER_*` variables. Not auto-loaded, so users add overrides to `.env.custom` instead.

`OPENROSDE_USER_*` defaults live in the top-level `.env` and in every per-platform `env/*.env` template (so platform switching does not erase the user-overlay defaults).
`scripts/load-openrosde-env.bash` exports every `OPENROSDE_*` variable, the `OPENROSDE_USER_*` ones included, so it can be interpolated by `docker-compose-user.yaml`.
In the `tmux` sessions, the window `user` of `tmux/openrosde.panes` runs the user-overlay starter (`openrosde_user_launch:user_example_default.launch`, or `user_example_default.launch.xml` on ROS 2) and a shell in the container.
Until #3 removes Terminator, the user overlay also reuses the platform Terminator layout: `RUN-TERMINATOR-TERMINAL.bash` always opens `terminator/${OPENROSDE_ROBOT_PLATFORM}.config`, and Number 12 (`terminal25`) of every platform layout is pre-wired to the user-overlay starter (`openrosde_user_launch:user_example_default.launch`).
The remaining spare panes (Numbers 8-11) are free shells reserved for additional user-overlay launches.

### Tmux Sessions

`RUN-TMUX-SESSION.bash [docker-project] [session-layout]` runs the terminals in a `tmux` session named `openrosde-<platform>-<docker-project>`, or attaches to it if it already runs.
The session gathers the pane files of the setup (`tmux/<setup>.panes`), or else of the platform (`tmux/<platform>.panes`), of the active extensions and the setup (every other `tmux/*.panes` of their folders, apart from those named after a platform or a setup that is not active), then of the core (`tmux/openrosde.panes`, or `tmux/openrosde-ros2.panes` on ROS 2), and opens a window on the first pane of each window name, with the panes of each window in the order of the pane files.
The pane file of a setup replaces that of its platform, as its Terminator layout does, and a device ships no pane file, since its panes belong to each setup.
Each line of a pane file reads `<layouts> <window> <launch-file> [<arg:=value> ...]`, where `<layouts>` is `*` or a comma-separated list of layouts (`default-gazebo`, `default-realworld`, or a layout of a setup), and the words `shell` and `host` open a shell in the container or on the host.
The windows are the standard windows that `OPENROSDE_TMUX_STANDARD_WINDOWS` of `scripts/load-extension-paths.bash` names, which open as tabs numbered from 1 in this order whatever order the pane files declare them in, each only when it holds a pane of the layout: `robot` (the bringup, visualization, planning, and drivers of the platform and its devices), `extra` (optional processes of a setup or an extension, such as cameras, perception, or a demo), `tools` (the FlexBE App on ROS 1 or the FlexBE WebUI on ROS 2, the rqt suite, `rosbridge`), `user` (the user overlay starter and a container shell), and `host`.
A window outside them opens after them with a warning of `RUN-TMUX-SESSION.bash`, and `gitlab-ci/check-launch-files.bash` fails on it in every pane file that the CI checks, so put every pane of a platform, a setup, or an extension in `robot` or `extra`.
The session turns the mouse on and titles the terminal `OpenRoSDE (<session>)`, which `maximize-app-window.bash` matches like the Terminator title.
It gives itself a status bar, with `OpenRoSDE`, the setup, and the layout on the left, the tabs in the middle, and `help: openrosde-help` on the right, in a purple accent, or plain when `NO_COLOR` is set or the terminal has fewer than 8 colors.
Set every option of a session with `tmux set-option -t <session>`, or on each of its windows, and never a global option or a `bind-key`, since both are shared by every session of the `tmux` server, which `tests/suites/test-tmux-sessions.bash` checks.
The first pane that enters the container gets `OPENROSDE_TMUX_SESSION_NAME` and `OPENROSDE_TMUX_SESSION_LAYOUT` in its environment, which `RUN-DOCKER-CONTAINER.bash` passes into the container with the Docker project, the container, and `NO_COLOR`.
`initialize-bash-shell.bash` then prints the splash of `scripts/print-tmux-splash.bash`, a wordmark drawn in the script and a short help, right before the prompt of the pane, since it clears the pane when it starts, and clears those variables.
`openrosde-help` prints the same help under a one-line wordmark in every shell of the container, as `bash ./scripts/print-tmux-splash.bash --help` does on the host.
Until #3 retires Terminator, keep `tmux/<platform>.panes` in step with `terminator/<platform>.config`, since the platform pane files were generated from the Terminator layouts.
`tests/suites/test-terminator-parity.bash` checks that every layout of a Terminator config of the core, and of every platform cloned into `extensions/`, runs the same launch files and arguments as the panes of that layout.

### Terminator Layouts

Terminator configuration files are per-platform in `terminator/` of the folder that holds the platform (e.g., `terminator/turtlebot3.config` of `openrosde-platform-turtlebot3`), or of the setup, which takes precedence.
Layout names follow the pattern: `openrosde-<platform>-term-11-<variant>-<environment>`.
`RUN-TERMINATOR-TERMINAL.bash` accepts a `[terminator-layout]` argument of the form `<variant>-<environment>` (e.g. `default-gazebo`, `default-realworld`), defaulting to `default-gazebo`.
The script prepends `11-` to build the full layout name passed to `terminator --layout`.
`RUN-TERMINATOR-TERMINAL.bash` pre-starts the Docker container with `--no-exec` before launching Terminator to avoid race conditions from multiple panes running `RUN-DOCKER-CONTAINER.bash` simultaneously.
The `sed` command injects `${OPENROSDE_DOCKER_PROJECT}` into the config, producing a `.config.tmp` file that is git-ignored.

All platform configs share an identical 15-terminal tree structure.
The bottom-left 4 terminals are standardized across all platforms and both environments:
- `terminal6` (Number: 4): bringup launch (or empty if no realworld bringup exists, e.g., TurtleBot3 realworld and Sciurus17 realworld).
- `terminal7` (Number: 5): RViz launch.
- `terminal9` (Number: 6): MoveIt (or navigation, depending on platform).
- `terminal10` (Number: 7): FlexBE app (`openrosde_launch:flexbe_app_default.launch`), on all platforms and in both gazebo and realworld layouts.
The top-right pair (`terminal13` / `terminal14`, Numbers: 2 / 3) is used for platform-specific secondary launches (e.g., gripper control, teleop, mapping).
Spare terminals (Numbers: 8-11) are available for additional launches (e.g., the cameras of a setup at Number: 8 in the Terminator layouts of that setup).
Number: 12 (`terminal25`) is standardized across all platforms and both environments for `openrosde_user_launch:user_example_default.launch` (user overlay starter).
Number: 13 (`terminal26`) is standardized across all platforms and both environments for `openrosde_launch:rqt_suite_default.launch`.
Number: 14 (`terminal28`) is a shell inside the container in every layout, where the Unity ROS TCP Endpoint ran until it left the core.
Number: 15 (`terminal29`) is standardized across all platforms and both environments for `openrosde_launch:rosbridge_server_default.launch`.

### Variable Naming Convention

All custom environment variables use the `OPENROSDE_` prefix. Examples:
- `OPENROSDE_ROBOT_PLATFORM`: Target robot platform (`turtlebot3`, `ur5e`, `fetch`).
- `OPENROSDE_ROBOT_SETUP`: Active setup, named after its template `env/<setup>.env` (the platform name for a default setup).
- `OPENROSDE_PLATFORM_REPOSITORY_URL`: Repository of a public platform, with `%s` for its name, which `scripts/load-openrosde-env.bash` names in its hint when the selected platform is cloned nowhere.
- `OPENROSDE_ROBOT_EXTENSIONS`: Names of the active extensions in `extensions/` or of their parts in `extensions/<extension>/parts/`, separated by spaces, each held by one folder only.
- `OPENROSDE_DOCKER_REGISTRY`: Registry of the base and platform images (`ghcr.io/openrosde` by default).
- `OPENROSDE_DOCKER_IMAGE_TAG`: Tag of the base and platform images, `main`, `dev`, or a release such as `v3.0.0`, or `auto` to derive `main` or `dev` from the branch.
- `OPENROSDE_DOCKER_BUILD_FALLBACK`: Images that `BUILD-DOCKER-IMAGE.bash` builds when their pull fails, `true` for the base and platform images, `platform` for the platform image alone, or `false` for neither, which a CI job sets so that a failed pull fails rather than building the base for hours.
- `OPENROSDE_QUIET`: `true` leaves out the list of every `OPENROSDE_*` variable that the entry scripts print.
- `OPENROSDE_LOCAL_IMAGE_PREFIX`: Derived prefix `openrosde-local/<setup>` of the local Docker layers and of the user overlay, with the setup in lowercase, as a Docker repository name requires.
- `OPENROSDE_CORE_VERSION`: Version of the core that a setup template pins, as a release tag or a branch, which `SWITCH-ROBOT-SETUP.bash` compares with the checkout.
- `OPENROSDE_CONTAINER_ROOT_DIR`: OpenRoSDE root path inside the Docker container.
- `OPENROSDE_ROOT_DIR`: OpenRoSDE root path on the host (auto-resolved, not in `.env`).
- `OPENROSDE_DOCKER_PROJECT`: Docker project name for container naming.
- `OPENROSDE_DOCKER_CONTAINER`: Derived container name (`openrosde-${OPENROSDE_ROBOT_PLATFORM}-${OPENROSDE_DOCKER_PROJECT}-1`).
- `OPENROSDE_USER_ID` / `OPENROSDE_GROUP_ID`: Host user/group IDs passed to the container.
- `OPENROSDE_BASE_DOCKERFILE_COMMIT_SHORT_SHA` / `OPENROSDE_ROBOT_PLATFORM_DOCKERFILE_COMMIT_SHORT_SHA`: Git commit hashes for image traceability.
- `OPENROSDE_ROBOT_PLATFORM_DOCKERFILE`: Derived path of the platform Dockerfile, `docker/<platform>-devel/Dockerfile`, relative to `OPENROSDE_ROBOT_PLATFORM_ROOT_DIR`, the build context of the platform image.
- `OPENROSDE_ROS_VERSION`: Version of ROS that the platform runs, `1` by default or `2`, which the template of a platform on ROS 2 sets, and on which the entry scripts stop for any other value.
- `OPENROSDE_ROS_DISTRO`: Distribution of ROS in `/opt/ros/<distribution>`, `noetic` by default or `lyrical`, which the template of a platform on ROS 2 sets with the version.
- `OPENROSDE_ROS_DOMAIN_ID`: Domain of the nodes on ROS 2, `0` by default, which the robot must share.
- `OPENROSDE_BASE_IMAGE_NAME`, `OPENROSDE_ROS_WORKSPACE_FOLDER`, `OPENROSDE_ROS_WORKSPACE_SUFFIX`: Derived by `scripts/load-extension-paths.bash` from `OPENROSDE_ROS_VERSION`: `openrosde-base`, `ros`, and `catkin_ws` on ROS 1, or `openrosde-base-ros2`, `ros2`, and `colcon_ws` on ROS 2.

## Code Style

### Bash Scripts

- Start every script with `#!/bin/bash`.
- Add a header comment block after the shebang describing the script's purpose, usage, and arguments.
- Use 80-character `#` lines as section separators.
- Add a comment before each logical block explaining its purpose.
- Write one sentence per line in comments.
- Use single quotes `' '` around code-related references in comments (e.g., `# Load the default environment variables from the '.env' file:`).
- Use `${VARIABLE}` syntax (with curly braces) for all variable references.
- Prefix all custom variables with `OPENROSDE_` (e.g., `OPENROSDE_ROBOT_PLATFORM`, not `PLATFORM`).
- Use at least 3 words for variable names (including `OPENROSDE_`), e.g., `OPENROSDE_ROBOT_PLATFORM`, not `OPENROSDE_PLATFORM`.
- Do not use fallback default syntax (`${VAR:-default}`) in scripts, since all defaults belong in `.env`.
- Use `source` instead of `.` for sourcing scripts.
- Use `pushd` / `popd` for temporary directory changes in functions.
- Quote variables in paths: `"${OPENROSDE_ROOT_DIR}"` (host scripts) but `${OPENROSDE_CONTAINER_ROOT_DIR}` (container scripts where paths are controlled).
- Top-level entry-point scripts (`BUILD-DOCKER-IMAGE.bash`, `RUN-DOCKER-CONTAINER.bash`, etc.) are `UPPER-CASE-KEBAB.bash`.
- Helper scripts in `scripts/` and `docker/openrosde-base/scripts/` are `lower-case-kebab.bash`.
- Name scripts with exactly three kebab-case words, starting with a verb (e.g., `BUILD-DOCKER-IMAGE`, `initialize-bash-shell`).
- Use `> /dev/null 2>&1` to suppress both stdout and stderr (e.g., cleanup commands, background pre-start).
- Use `2>/dev/null` to suppress only stderr when stdout is still needed (e.g., conditional checks like `docker manifest inspect`).
- Use `& wait $!` to run a command in the background and wait for completion (e.g., pre-starting the Docker container before launching Terminator).

Example header:

```bash
#!/bin/bash

# This script does X for Y purpose.
#
# Usage: bash ./SCRIPT-NAME.bash [arg1] [arg2]
#
# [arg1]: Description of arg1.
#         Default value is '$USER'.
# [arg2]: Description of arg2.

################################################################################
```

Example section:

```bash
################################################################################

# Load the default environment variables from the '.env' file:
source ${OPENROSDE_CONTAINER_ROOT_DIR}/.env

# Overwrite the default environment variables with the user's variables from the '.env.custom' file (if it exists):
if [ -f ${OPENROSDE_CONTAINER_ROOT_DIR}/.env.custom ]; then
  source ${OPENROSDE_CONTAINER_ROOT_DIR}/.env.custom
fi

################################################################################
```

### Dockerfiles

- Use 80-character `#` lines as section separators.
- Add a comment before each `RUN`, `COPY`, `ARG`, or `ENV` instruction.
- Group related `apt-get install` packages into a single `RUN` layer with `\` continuation.
- Always include `&& apt-get clean && rm -rf /var/lib/apt/lists/*` at the end of `apt-get install` layers.
- Use `ARG` for build-time variables and `ENV` for runtime variables.

### Docker Compose

- Use 80-character `#` lines as section separators.
- Add inline comments with `#` to explain non-obvious fields.
- Do not use fallback default syntax (`${VAR:-default}`), since all defaults belong in `.env`.
- Variable interpolation uses `${VAR}` syntax.

### ROS Launch Files

Launch files live in platform-specific `openrosde_<platform>_launch` packages (e.g., `openrosde_turtlebot3_launch`, `openrosde_ur5e_launch`).

File names follow the pattern: `<component>_<variant>_<environment>.launch`

- `<component>`: The subsystem or feature (e.g., `turtlebot3_bringup`, `ur5e_moveit`, `onrobot_rg_control`).
- `<variant>`:
  - `default`: Configured as close as possible to the official documentation by including upstream default launch files.
  - `custom`: Customized launch file for specific OpenRoSDE use cases.
- `<environment>`:
  - `gazebo`: For use in the Gazebo simulator.
  - `realworld`: For use with the real (physical) robot.
  - Omitted when the launch file applies to both environments (e.g., `turtlebot3_mapping_default.launch`).

Formatting conventions:

- Start every launch file with `<?xml version="1.0" encoding="utf-8"?>`.
- Use 2-space indentation (no tabs, no 4-space).
- Add a blank line after `<launch>` and before `</launch>`.
- Use `<!-- comment -->` to describe each logical section, with a blank line before and after.
- Always include a space before `/>` in self-closing tags (e.g., `<arg ... />`, not `<arg .../>`).
- Use `default=` for top-level `<arg>` declarations (interface arguments).
- Use `value=` for `<arg>` tags inside `<include>` blocks (passing values to included files).
- For multi-line element attributes, place continuation attributes on the next line indented by 2 extra spaces (4 total from parent).
- Group related `<arg>` declarations together, separated by blank lines from other groups or elements.
- Use single quotes `' '` around code-related names in `<!-- -->` comments (e.g., `<!-- Start 'robot_state_publisher'. -->`, `<!-- Load 'kinematics.yaml'. -->`). This mirrors the Bash comment convention.
- Add a source comment block at the top of every launch file, immediately after `<launch>`, using this pattern:
  - `<!-- https://github.com/<upstream-repo> -->`: URL of the upstream repository this file is based on or extends.
  - `<!-- Upstream default: $(find <pkg>)/launch/<file>.launch -->`: path to the upstream launch file used as the starting point, when one exists.
  - `<!-- OpenRoSDE-specific: <one-line description> -->`: instead of the upstream line, when the file has no direct upstream counterpart.

RViz launch files use an OpenRoSDE-owned `.rviz` config file stored in `config/rviz/` within the `openrosde_<platform>_launch` package.
These config files are copied from the upstream default and modified to set `Fullscreen: false` under `Window Geometry:`.
All RViz launch nodes use `required="true"` so the layout closes when RViz exits.
Each RViz launch file also includes a `<node name="maximize_rviz" pkg="openrosde_launch" type="maximize-app-window.bash" args="RViz" />` node that maximizes the window via `wmctrl` after it opens.
The corresponding bringup Gazebo launch files include the same pattern with `name="maximize_gazebo"` and `args="Gazebo"` to maximize the Gazebo window.
The `flexbe_app_default.launch` file includes the same pattern with `name="maximize_flexbe"` and `args="FlexBE"` to maximize the FlexBE App window (the `"FlexBE"` substring matches the `"FlexBE App"` window title, and a single word keeps roslaunch from splitting the arg on the space).
The `maximize-app-window.bash` script lives in `ros/openrosde_catkin_ws/src/openrosde_launch/scripts/` and is installed via `openrosde_launch`'s `CMakeLists.txt`.
The script retries for up to 60 seconds to handle slow application startup (e.g. the FlexBE App nwjs window), then runs a short focus-restore loop that re-asserts the maximized state and refocuses the terminal of the `tmux` session or of Terminator, matched by its window title `OpenRoSDE (`, which `RUN-TMUX-SESSION.bash` and `terminator/*.config` set.
A non-blocking `flock` on `/tmp/openrosde_maximize_focus.lock` ensures only one concurrent instance runs the focus-restore loop at a time, which prevents flickering when several maximize nodes run in parallel (e.g. RViz, FlexBE, the rqt suite).
`wmctrl` must be installed in the container (it is included in the `openrosde-base` Dockerfile).

On ROS 2, launch files live in the `openrosde_<platform>_launch` package of a colcon workspace of `ros2/`, an `ament_cmake` package that installs its `launch/` folder, and follow the same names with the extension `.launch.xml`, or `.launch.py` when they need Python, such as a condition on an argument of an included Python launch file:

- Prefer XML, with the same formatting as on ROS 1, `$(find-pkg-share <pkg>)` in place of `$(find <pkg>)`, `exec=` in place of `type=`, and `$(var <name>)` in place of `$(arg <name>)`.
- Start `maximize-app-window.bash` as `<executable cmd="$(find-pkg-prefix openrosde_launch)/lib/openrosde_launch/maximize-app-window.bash RViz" />`, which passes it no ROS argument.
- Set `use_sim_time` on every node that reads the clock of Gazebo, since ROS 2 has no global parameter for it.
- Write the source comments as on ROS 1, with `<!-- Upstream default: $(find-pkg-share <pkg>)/launch/<file> -->`, and with `#` comments at the top of a Python launch file.

### ROS Packages

ROS packages (e.g., `openrosde_ur5e_teleop` in `ur5e_catkin_ws` of `openrosde-platform-ur5e`) extend the standard launch-only pattern with Python nodes and config files.
They follow the same `package.xml` and `README.md` conventions above, and additionally:

- `CMakeLists.txt`: Includes `catkin_install_python` for Python node scripts.

When a `openrosde_<platform>_launch` package itself needs Python helper nodes (e.g., a gripper joint-state publisher), it follows the same `openrosde_<platform>_teleop` extension pattern:

- `scripts/`: Python node scripts (e.g., `publish-gripper-joint-states.py`).
- `CMakeLists.txt`: Includes `catkin_install_python` for the scripts.
- `package.xml`: Adds `rospy` and any message-package exec depends (e.g., `sensor_msgs`, `onrobot_rg_control`).
- The `urdf/` folder holds OpenRoSDE-owned xacro files that extend or replace the upstream robot URDF.
- The `description/` folder holds third-party description fragments (meshes, xacros) vendored into the package.
- A `<component>_description_default_<environment>.launch` adapter file is used when the upstream driver's `robot_description_file` arg requires a launch file that accepts a `kinematics_params` arg.

### FlexBE Behaviors Packages

Each platform has a `openrosde_<platform>_behaviors/` directory in its Catkin workspace containing two ROS packages, plus a shared `README.md` and `.gitignore`:

- `openrosde_<platform>_flexbe_behaviors/`: Contains FlexBE behavior state machines.
  - `src/openrosde_<platform>_flexbe_behaviors/`: Python modules, one `<behavior_name>_sm.py` per behavior.
  - `manifest/<behavior_name>.xml`: FlexBE behavior manifest (loaded by the FlexBE app).
    The `<description>` element must be a single line with no embedded newlines, since multi-line descriptions render as literal whitespace in the FlexBE app.
  - `config/<behavior_name>.yaml`: Behavior parameters (placeholder, since the values are set in the manifest).
  - `setup.py`, `CMakeLists.txt`, `package.xml`: Standard catkin Python package boilerplate.
  - `package.xml` uses `format="2"`, exports `<flexbe_behaviors />`, and lists `flexbe_core`, `flexbe_states`, and any generic state packages (`flexbe_navigation_states`, `flexbe_manipulation_states`) as `exec_depend`.
    `format="2"` requires `<exec_depend>` tags, and `<run_depend>` causes a `catkin_pkg.package.InvalidPackage` error at build time.
- `openrosde_<platform>_flexbe_states/`: Reserved for platform-specific custom FlexBE states (empty by default, so only add states here that cannot be satisfied by `flexbe_behavior_engine` or `flexbe_generic_states`).
  - `src/openrosde_<platform>_flexbe_states/`: Python modules.
  - `setup.py`, `CMakeLists.txt`, `package.xml`: Standard catkin Python package boilerplate.
  - `package.xml` uses `format="2"` and exports `<flexbe_states />`.

Behavior state machine files (`*_sm.py`) follow the code-generation format used by the FlexBE app:
- Header block with `WARNING: Generated code!` comment.
- All state imports at the top.
- `[MANUAL_IMPORT]`, `[MANUAL_INIT]`, `[MANUAL_CREATE]`, `[MANUAL_FUNC]` tags preserved for FlexBE app round-trips.
- Only use states from `flexbe_behavior_engine` (`flexbe_states`) and `flexbe_generic_states` (`flexbe_navigation_states`, `flexbe_manipulation_states`).
  Do not create custom states unless strictly necessary.
- Use descriptive state names with a `MoveTo*` / `WaitAt*` prefix pattern (e.g., `MoveToHome`, `WaitAtHome`).
  Never use auto-generated `_1` / `_2` suffixes (e.g., `MoveBaseState_1`).
- `OperatableStateMachine.add()` calls inside `with _state_machine:` use **3 tabs** for the call itself and **10 tabs** for all continuation argument lines (`state_class`, `transitions=`, `autonomy=`, `remapping=`).
  When manually editing state names, ensure the 3-tab indentation of the `OperatableStateMachine.add(` line is preserved, since dropping it to column 0 causes an `expected an indented block` `SyntaxError` at runtime.

`SrdfStateToMoveit` reads `/robot_description_semantic` once in `__init__` when the FlexBE app instantiates the behavior class.
This means the SRDF parameter must be on the ROS parameter server before the behavior is loaded in the FlexBE app, not just before it executes.
Pre-load the SRDF in the bringup launch file (before MoveIt starts) to avoid a `param_error` on first load.

Platform-specific behavior guidelines:
- Mobile robot platforms (TurtleBot3, Fetch, HSR): looping navigation between two waypoints using `MoveBaseState` and `WaitState`.
  State names: `MoveToWaypoint1`, `WaitAtWaypoint1`, `MoveToWaypoint2`, `WaitAtWaypoint2`.
- Arm robot platforms (UR5e, COBOTTA): looping dance between `home` and `up` SRDF named states using `SrdfStateToMoveit` and `WaitState`.
  State names: `MoveToHome`, `WaitAtHome`, `MoveToUp`, `WaitAtUp`.
- Dual-arm robot platforms (Sciurus17): alternating left/right arm moves to `r_arm_init_pose` / `l_arm_init_pose` SRDF named states using `SrdfStateToMoveit` and `WaitState`.
  State names: `MoveRightArmToInitPose`, `WaitAtRightInitPose`, `MoveLeftArmToInitPose`, `WaitAtLeftInitPose`.

### Markdown (README & Documentation)

- Use [GitHub Flavored Markdown](https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax) (GFM) syntax.
- Follow the [Make a README](https://www.makeareadme.com/) structure for `README.md`: title, badges, description, quick start, directory structure, documentation links, publications, external resources, issues, contributing, authors, license.
- Write no table of contents by hand or with `[[_TOC_]]`, since GitHub shows the outline of every Markdown file in its own menu.
- Use `- ` (dash + space) for unordered list items.
- Use `1. `, `2. `, `3. ` (sequential numbers) for ordered list items.
- Align continuation content (code blocks, paragraphs, nested lists) with the text of the parent list item: 2 spaces after `- `, 4 spaces after `N. `.
- Write one sentence per line for cleaner Git diffs.
- Use backticks `` ` ` `` around inline code, file names, commands, variables, functions, and paths.
- Use GitHub alerts for callout blocks: `> [!NOTE]`, `> [!TIP]`, `> [!IMPORTANT]`, `> [!WARNING]`, `> [!CAUTION]`.
  Each continuation line must be prefixed with `> `.
- Use `shell` as the language identifier for shell code blocks.
- Use `mermaid` fenced code blocks for diagrams (rendered natively by GitHub, by the website `https://openrosde.org/`, and by VS Code with extensions).
  Use the `neutral` theme via a YAML frontmatter config block.
  Use `<br/>` for line breaks inside node labels.
  Wrap code-related names in single quotes `' '` inside labels.
  Use sentence capitalization for labels and edge text.
- Use `#[optional-arg]` and `<required-arg>` syntax in command usage examples.
- Use Title Case for all headers (e.g., `## Adding a New Platform`, `### Step 1: Create the Environment Template`). Articles (`a`, `an`, `the`), short prepositions (`in`, `of`, `at`), and short conjunctions (`and`, `or`, `if`) are lowercase unless they are the first word.
- Do not use em dashes (`—`), en dashes (`–`), or semicolons (`;`) in prose. Use a comma, a period, or a colon (`:`) instead, or rephrase mid-sentence asides as separate clauses or parenthetical notes. The plain ASCII hyphen `-` remains fine for kebab-case identifiers, CLI flags, and bullet markers.
- Do not use thematic breaks (`---`). Use blank lines and heading levels to separate sections instead.
- Keep `README.md` concise with links to detailed guides in `docs/`.
- Platform-specific documentation goes in `docs/robot-platforms/`.
- Use badges following the `[![Label](badge-url)](link-url)` pattern.
- Prefix product names with their maker name (e.g., Universal Robots UR5e, OnRobot RG2, Intel RealSense D435i, Robotis TurtleBot3, 3Dconnexion SpaceMouse).
- Reference the host machine as "Ubuntu development machine".
- Decorate all `##` and `###` headers with a leading emoji in `README.md` and `docs/` files only (not in package-level READMEs or `AGENTS.md`).
  Use a single emoji that reflects the section topic, placed before the header text (e.g., `## 🚀 Quick Start`).
  Reuse the same emoji for semantically equivalent headers across files (e.g., `🔗 External Resources`, `⚙️ Platform Configuration`).

### CI Scripts

- Use 80-character `#` lines as section separators.
- Use `OPENROSDE_` prefix for all custom CI variables.
- Generate the jobs of every platform and every setup in `gitlab-ci/generate-ci-pipeline.bash` rather than listing them by hand.
- Keep the logic of a job in a script of `gitlab-ci/`, so that the YAML only wires the jobs together.
- Give every artifact a retention, and hand images between jobs through the registry, never through the disk of the runner.
- Never publish a GLB file of a robot mesh: the CI generates them only inside the containers of a job, as [Robot Models](docs/robot-models.md) describes, since some meshes may not be redistributed.

### GitHub Actions

- Keep the logic in the scripts of `gitlab-ci/`, which the workflows run, and in `.github/scripts/` only for what GitHub Actions alone needs, so that a workflow only wires the jobs together.
- Take the platforms and the setups from the child pipeline that `gitlab-ci/generate-ci-pipeline.bash` prints, through `.github/scripts/print-ci-matrices.bash`, rather than listing them in a workflow.
- Use only the actions of GitHub and of verified creators, which the organization allows, and pin each to a full commit hash with its version in a comment, looked up with `git ls-remote`.
- Run only on GitHub-hosted runners, and give a job that builds or pulls the base images `.github/actions/free-disk-space` first.
- Set `permissions: contents: read` at the top of every workflow, and give `packages: write` only to a job that pushes images, which runs only on a push to `openrosde/openrosde`.
- Check out every repository with `persist-credentials: false`, since `gitlab-ci/test-catkin-workspaces.bash` copies the checkout into the test container.
- Pass every value of a context to a script through `env`, never inside the text of a `run` script.

### Submodule Patches

- Patch files for Git submodules live in `patches/` mirroring the full submodule path (e.g., `patches/ros/openrosde_catkin_ws/src/flexbe_app/`).
- Name patch files with a numbered prefix and three kebab-case words starting with a verb: `0001-fix-curl-redirect.patch`.
- Patches are applied idempotently by `scripts/apply-submodule-patches.bash`, called via `scripts/update-git-submodules.bash`.
  `scripts/update-git-submodules.bash` is invoked by `SETUP-DEVEL-MACHINE.bash` on first setup and by `SWITCH-ROBOT-PLATFORM.bash` on every platform switch.
  After applying each patch, all files it touches are automatically marked `skip-worktree` so they do not appear as tracked changes in `git status` or VS Code.
- If a submodule pin is updated and `git submodule update` needs to overwrite a patched file, Git will refuse due to `skip-worktree`.
  Clear the flag first with `git -C <submodule-path> update-index --no-skip-worktree <file>`, then re-run `scripts/update-git-submodules.bash`.
- To create a patch: make changes in the submodule, run `git diff > <patch-file>`, then reset the submodule with `git checkout .`.

### Git Submodules

Git submodules provide third-party ROS packages that are not available as Noetic debian packages.
The Dockerfile installs their system dependencies via `apt-get`, and the packages themselves are built from source at `catkin build` time inside the container.
All submodules use `ignore = dirty` in `.gitmodules`.

Current submodules:
- Shared (`openrosde_catkin_ws`): `flexbe_behavior_engine`, `flexbe_app`, `flexbe_generic_states`.
- The platforms and devices in repositories of their own declare their submodules in their own `.gitmodules`: `fetch_gazebo` in `openrosde-platform-fetch`, `sciurus17_ros` and `sciurus17_description` in `openrosde-platform-sciurus17`, `denso_cobotta_ros` in `openrosde-platform-cobotta`, and `onrobot` and `roboticsgroup_upatras_gazebo_plugins` in `openrosde-device-onrobot`, at the commits that this repository pinned.
- UR5e (`openrosde-platform-ur5e`): no submodules, since the plain robot needs only the packages of its image.
- TurtleBot3 on ROS 2 (`openrosde-platform-turtlebot3`): `turtlebot3` of ROBOTIS in `ros2/turtlebot3_colcon_ws/src/`, at the tag `2.3.7`, with a patch for Lyrical, since no distribution releases it for Lyrical.
- HSR (`openrosde-platform-hsr`): no submodules, since its image copies the HSR stack of the Toyota binary image `ghcr.io/hsr-project/tmc_wrs_binary:noetic-latest`, as the documentation of that repository describes.

Current patches:
- `patches/ros/openrosde_catkin_ws/src/flexbe_app/0001-fix-curl-redirect.patch`: Fixes a broken curl redirect in the FlexBE app.
- `patches/ros/openrosde_catkin_ws/src/flexbe_app/0002-set-window-maximized.patch`: Sets `"initial_state": "maximized"` in the nwjs `package.json` so the FlexBE App window opens maximized.
- The four patches of `denso_cobotta_ros` and the Cartesian twist patch of `fetch_gazebo` live in `patches/` of `openrosde-platform-cobotta` and `openrosde-platform-fetch`, which `scripts/update-git-submodules.bash` and the CI apply from `extensions/`.
- The patch of `onrobot` that comments out the `world` link of `onrobot_rg2.xacro` lives in `patches/` of `openrosde-device-onrobot`.
- The patch of `turtlebot3` that builds `turtlebot3_node` on Lyrical, with the headers `.hpp` and the QoS that `message_filters` now asks for, lives in `patches/ros2/turtlebot3_colcon_ws/src/turtlebot3/` of `openrosde-platform-turtlebot3`.

## ROS 2

OpenRoSDE runs ROS 1 and ROS 2 side by side (#2), and `docs/ros2.md` is the guide.

- A platform runs ROS 1 unless its template sets `OPENROSDE_ROS_VERSION=2` and `OPENROSDE_ROS_DISTRO=lyrical`, the two lines of `env/openrosde-ros2.env`, and nothing of ROS 1 changes behavior for a platform that sets neither.
- Keep every script generic: a script branches on `OPENROSDE_ROS_VERSION` and reads `OPENROSDE_ROS_DISTRO`, `OPENROSDE_BASE_IMAGE_NAME`, `OPENROSDE_ROS_WORKSPACE_FOLDER`, and `OPENROSDE_ROS_WORKSPACE_SUFFIX`, and never names a platform.
- The helper scripts of `docker/openrosde-base/scripts/` serve both base images, so a change there keeps the branch of ROS 1 exactly as it was.
- The base image of ROS 2 starts from `ros:lyrical-ros-base`, pinned by digest, with Gazebo Jetty through the vendor packages of `ros_gz`, and builds `file_server2` of ROS# `2.3.1` with the patches of `docker/openrosde-base-ros2/patches/ros-sharp/`.
- On ROS 2, `robot_description` is the transient local topic of `robot_state_publisher`, the file service has the type `file_server2/srv/GetBinaryFile`, and `rosbridge_server_default.launch.xml` sets `max_message_size` to `100000000` and `call_services_in_new_thread` to `true`.
- Colcon workspaces build without `--symlink-install`, since the file service refuses a file whose real path leaves the share folder of its package.
- One repository may hold the same robot on both ROS as two platforms, such as `turtlebot3` and `turtlebot3-ros2` of `openrosde-platform-turtlebot3`, and a platform whose name holds a dash names its launch package in its shell script.
- No FlexBE App is released for Lyrical, and the platforms on ROS 2 have no Terminator layout.

## Adding a New Platform

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for the full step-by-step guide.
The platforms are found by name: `scripts/list-robot-platforms.bash` lists every `env/<platform>.env` that declares `OPENROSDE_ROBOT_PLATFORM=<platform>` alone on its line, with no quotes and no trailing comment, and the rest of the extension system of the [OpenRoSDE Split](#openrosde-split) (#3) changes this section again.
A new platform goes into an extension repository of its own with the layout of the core, cloned into `extensions/` (see `docs/extensions.md`), where it needs no registration at all, rather than into the core.
Start from a copy of a platform repository, such as `https://github.com/openrosde/openrosde-platform-turtlebot3`, with its `LICENSE`, `NOTICE`, `README.md`, `.gitignore`, and `.github/workflows/test-with-openrosde.yml`, which tests it with the core through `extension.yml`.
When adding a platform named `<platform>`, create these files in its repository:

- `env/<platform>.env`: environment template, which declares `OPENROSDE_ROBOT_PLATFORM=<platform>` and `OPENROSDE_ROBOT_SETUP=<platform>`, since it is the default setup of the platform.
- `docker/<platform>-devel/Dockerfile`: platform Docker image.
- `docker/docker-compose-<platform>.yaml`: Docker Compose overlay.
- `ros/<platform>_catkin_ws/src/openrosde_<platform>_launch/`: ROS launch package (5 launch files, `package.xml`, `CMakeLists.txt`, `README.md`, `.gitignore`).
- `ros/<platform>_catkin_ws/src/openrosde_<platform>_behaviors/`: FlexBE behaviors package (two sub-packages: `openrosde_<platform>_flexbe_behaviors/` and `openrosde_<platform>_flexbe_states/`, plus `README.md` and `.gitignore`).
- `tmux/<platform>.panes`: panes of the `tmux` session.
- `terminator/<platform>.config`: Terminator layouts, until `tmux` replaces them.
- `docs/robot-platforms/<platform>.md`: platform documentation.
- `scripts/<platform>/initialize-bash-shell.bash` (optional): shell configuration sourced inside the container by `docker/openrosde-base/scripts/initialize-bash-shell.bash`.
- `scripts/<platform>/bringup-ros-robot.bash` (optional): robot bringup run by `BRINGUP-ROS-ROBOT.bash` with the ROS master host name.
- `scripts/<platform>/restart-chrony-service.bash` (optional): robot Chrony restart run by `RESTART-CHRONY-SERVICE.bash`.
- `ci/check-in-container.bash` (optional): checks that the CI of the core runs in the container of every setup of the platform, such as the check of the Fetch over `rosbridge` in `openrosde-platform-fetch`.

A platform on ROS 2 sets `OPENROSDE_ROS_VERSION=2` and `OPENROSDE_ROS_DISTRO=lyrical` in its template, builds its image on `openrosde-base-ros2`, and holds colcon workspaces in `ros2/<name>_colcon_ws/` and launch files of ROS 2 in its panes, as `docs/ros2.md` describes.

The platform scripts run with every `OPENROSDE_*` variable exported, and the launch package of the panes that name none is `openrosde_<platform>_launch`, unless `scripts/<setup or platform>/initialize-bash-shell.bash` sets another `OPENROSDE_LAUNCH_PACKAGE`, which the shell of the container and the CI both take.
Then list a public platform in the files of this repository that name the public platforms:

- `gitlab-ci/extensions.repos`: the repository, pinned at a commit or a tag of its `main`, so that the CI of the core tests it and publishes its image.
- `README.md`: platform table and third-party table.

## Build Commands

- Build Docker images: `bash ./BUILD-DOCKER-IMAGE.bash`.
  - Default behavior: pulls the `main`, `dev`, or release `vX.Y.Z` images from the registry, as `OPENROSDE_DOCKER_IMAGE_TAG` selects, or builds current platform with cache, as far as `OPENROSDE_DOCKER_BUILD_FALLBACK` allows.
  - `bash ./BUILD-DOCKER-IMAGE.bash local`: builds current platform with cache (fast iteration).
- Build Catkin workspaces (inside container): `openrosde-reset-catkin-workspaces` or `openrosde-build-catkin-workspaces`.
- Switch platform: `bash ./SWITCH-ROBOT-PLATFORM.bash <platform>` (e.g., `bash ./SWITCH-ROBOT-PLATFORM.bash ur5e`).
- Switch setup: `bash ./SWITCH-ROBOT-SETUP.bash <setup>` (clones the repositories of `env/<setup>.repos` with `vcstool`, then selects the setup).
- Run Docker container: `bash ./RUN-DOCKER-CONTAINER.bash`.
- Run `tmux` session: `bash ./RUN-TMUX-SESSION.bash [docker-project] [session-layout]`.
- Run Terminator layout: `bash ./RUN-TERMINATOR-TERMINAL.bash` (until `tmux` replaces it).
- Restart Chrony service: `bash ./RESTART-CHRONY-SERVICE.bash` (resyncs host and robot clocks via Chrony).
- Bringup robot: `bash ./BRINGUP-ROS-ROBOT.bash <rosmaster-hostname>` (SSH into the robot and launch bringup nodes).

## Testing Pipeline

- Verify Docker images build successfully with `bash ./BUILD-DOCKER-IMAGE.bash`.
- Verify Catkin workspaces build inside the container with `openrosde-reset-catkin-workspaces`.
- Check for hardcoded paths: `grep -rn '/root/OpenRoSDE' --include='*.bash' --include='*.yaml' --include='*.yml' --include='Dockerfile' .`
- Run the test suites of the scripts with `bash ./tests/run.bash`, which needs Docker on the Ubuntu development machine, or runs directly inside a Debian container with `tmux` installed, and add a suite to `tests/suites/` for every change of the loader or the entry scripts.

## Real Robots

- Never publish a topic, call a service or an action, or start a node or a launch file that can move a real robot or its gripper, unless a person is with the robot and has asked for it.
- Check a change in Gazebo first, and leave the test on the real robot to a person standing by it.
- The Coarobo UR5e bench runs its demos from `dev`, so a change merged into `dev` reaches a real robot.

## Deployment Considerations

- The CI runs on GitHub Actions, as the section GitHub Actions of `docs/extensions.md` describes, with the scripts of `gitlab-ci/`, which `.github/scripts/run-gitlab-ci-script.bash` runs with the variables of GitLab CI that they read set from those of GitHub Actions, and the ID of the run in place of the ID of the pipeline.
  The parent pipeline `gitlab-ci/gitlab-ci.yml` of the GitLab archive runs nowhere, and #13 renames `gitlab-ci/` and removes what only GitLab CI used.
- `checks.yml` runs for every pull request, forks included, with no secret: ShellCheck through `.github/scripts/check-shell-scripts.bash`, actionlint, `tests/run.bash`, `check-scripts-job`, and `generate-pipeline-job`.
  `generate-pipeline-job` clones the public extensions of `gitlab-ci/extensions.repos` with `gitlab-ci/clone-extensions.bash`, generates one image job per platform and one test job per setup found by name, in the core and in those extensions, and the test jobs of the core alone on ROS 1 and ROS 2, with `gitlab-ci/generate-ci-pipeline.bash`, then prints the matrices of the workflows from them with `.github/scripts/print-ci-matrices.bash`.
  `gitlab-ci/generate-ci-pipeline.bash` fails when `scripts/list-robot-platforms.bash` or `scripts/list-robot-setups.bash` fails, such as for a template that declares its name with quotes, rather than leaving that platform or setup out of the pipeline.
- `ci.yml` calls `checks.yml` on every push to `dev` or `main` and every release tag of `openrosde/openrosde` that changes something that goes into an image or a workspace, then builds or reuses the images in the registry that `OPENROSDE_CI_REGISTRY_IMAGE` names, `ghcr.io/openrosde`, tests every setup and the core alone, and publishes the images.
  A change of the documentation alone runs no image job, and a pull request builds no image, so its images and workspaces are tested once it is merged into `dev`.
- `gitlab-ci/extensions.repos` pins each public extension at a tag or a commit, with an anonymous HTTPS URL, and every job clones it again from the same pins, never with a token of the job, so a public run can never read a private repository.
  A platform enters it in the same pull request that removes it from the core.
  Update its pins by hand, never with `vcs export` of the whole `extensions/` folder, which would add the private clones of the checkout, and keep its layout, which `gitlab-ci/clone-extensions.bash` checks.
- The jobs run on GitHub-hosted runners, and a job that builds or pulls the base images frees disk space first with `.github/actions/free-disk-space`.
- Jobs hand their images to each other through the registry only, so nothing is kept on the runner between jobs.
- A self-managed runner, such as one that runs the CI of a private extension, may set `JOB_CPUS` to the CPUs that a job may use, which `test-catkin-workspaces.bash` passes into the container as `OPENROSDE_BUILD_JOBS`, so that `catkin build` does not start a compiler for every CPU of the machine inside a smaller share.
- An image carries the label `com.coarobo.openrosde.source-hash`, the hash of the folders it is built from, each hashed in the Git repository that holds it, the core or a clone in `extensions/`, and a job retags an identical image on the registry instead of building it again.
  The image of a platform is built from the folder that holds the platform, and `gitlab-ci/build-ci-image.bash` fails when a source folder is missing or not committed, rather than hashing it as a constant.
- Every run of `ci.yml` pushes its images as `pipeline-<run-id>`, and `publish-images-job` publishes them as `dev` and `main` from those branches, or as `vX.Y.Z` from a release tag, by retagging them on the registry once every image job and every test has passed.
  Only the image jobs and `publish-images-job` may write packages, and they run only on a push to `openrosde/openrosde`, so a pull request, a fork, or the workflow of an extension never publishes.
- `extension.yml` is the reusable workflow that an extension calls from its own `.github/workflows/test-with-openrosde.yml`.
  It checks out the core at `core-ref`, clones the extensions of `gitlab-ci/extensions.repos`, checks out the commit under test in place of the pinned clone, and generates the pipeline with `OPENROSDE_CI_EXTENSION_OVERRIDE=<name>=checkout@<commit>`, so that it tests only the setups that activate that extension, with those of `OPENROSDE_CI_EXTRA_EXTENSIONS`, its input `extra-extensions`, added to every setup, and only those that its input `setups` names, when it names any.
  Since the repository of an extension cannot push to the registry of the core, each of its test jobs builds the image of its platform locally on the published images, with `.github/scripts/build-local-platform-image.bash`, and it publishes nothing.
- The test job of a setup copies its template to `.env.custom`, builds its Docker layers with `scripts/build-extension-layers.bash` without pushing them, and builds its Catkin workspaces in a container of the image of its platform, read from `OPENROSDE_CI_IMAGE_REGISTRY` with the tag `OPENROSDE_CI_IMAGE_TAG`, the images of the run by default, which `extension.yml` and the CI of a private extension set to published images, such as `ghcr.io/openrosde` and `v3.0.0`.
  Outside the CI, `gitlab-ci/test-catkin-workspaces.bash` refuses to replace an existing `.env.custom`.
  It then disconnects the container from every network, checks with `gitlab-ci/check-launch-files.bash` that every pane of the setup opens in a standard window, that every launch entry point of its panes resolves with `roslaunch --files`, and that no two panes of one layout start a node of the same name with `roslaunch --nodes`, both of which start no node, and runs `ci/check-in-container.bash` of every active extension that holds one.
  On ROS 2, it builds the colcon workspaces, loads every launch entry point with `ros2 launch --show-args`, which starts no node either, and compares no node names.
- The base image of ROS 2 builds in `build-base-ros2-image-job`, the image of a platform on ROS 2 builds on it, and the core alone is tested on ROS 2 in `test-core-ros2-workspaces-job` and again in `robot-model-fragments-job`, through a `rosbridge` that fragments every message above 1,000,000 bytes, as `docs/ros2.md` describes.
- `check-scripts-job` runs `gitlab-ci/check-no-motion.bash`, which fails on any `roslaunch` beyond `--files`, `--nodes`, or `--dump-params`, and on any `rosrun`, `rostopic pub`, or `rosservice call`, in `gitlab-ci/` and `.github/` of the core and `ci/` of the extensions, apart from the simulations that `allowed-simulation-launches.txt` of their folder names, and allows a `roslaunch` of several launch files only when that list names every one.
  On ROS 2, it fails the same way on any `ros2 launch` beyond `--show-args`, `--show-arguments`, `-s`, `--print`, `--print-description`, or `-p`, and on any `ros2 run`, `ros2 topic pub`, `ros2 service call`, `ros2 action send_goal`, `ros2 bag play`, or `ros2 lifecycle set`.
  Every test job needs it, so no check of an extension runs before it passes.
- Every artifact expires, the logs of a failed test and the reports of the converter after a week, and the generated pipeline after a day.
- Docker images are pushed to `OPENROSDE_DOCKER_REGISTRY`, `ghcr.io/openrosde/` by default, which serves them to anyone without a token, so never write a registry token in a script.
- Image traceability: each image embeds `OPENROSDE_DOCKER_IMAGE_VERSION` from the Dockerfile's Git commit hash, and the labels `org.opencontainers.image.revision` and `org.opencontainers.image.source`.

## Versioning & Commits

- Use [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) for all commit messages and pull request titles.
- Follow [Semantic Versioning](https://semver.org/) for releases.
- Follow [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) for `CHANGELOG.md`.
- Follow the [Make a README](https://www.makeareadme.com/) guidelines for `README.md` structure.

## GitHub Workflow

The project is hosted at <https://github.com/openrosde/openrosde>.
See [`CONTRIBUTING.md`](CONTRIBUTING.md#github-project-organization) for the full human-facing description.

Agent rules:

- Default branch is `main`, which holds the releases.
  `dev` is the protected integration branch, where agents work and from which the Coarobo UR5e bench runs its demos.
- Short-lived branches are named `<type>/<slug>` after the Conventional Commit type (e.g., `feat/extension-parts`, `fix/registry-anonymous-pull`), branch from the latest `dev`, and merge back into `dev` through a PR.
- `dev` merges into `main` through a PR when the maintainers decide that a release is due.
- Ask the maintainer before every `git add`, commit, merge, rebase, reset, push, or branch deletion, and show the diff first.
- Never stash, reset, restore, check out over, or clean work that someone else left in a working tree.
- End every commit an agent writes with a `Co-authored-by: <agent and model> <noreply address>` trailer after a blank line, as [GitHub documents it](https://docs.github.com/en/pull-requests/committing-changes-to-your-project/creating-and-editing-commits/creating-a-commit-with-multiple-authors), while the maintainer stays the author.
- Commit messages and PR titles use Conventional Commits: `type(scope): subject`.
  - Allowed types: `feat`, `fix`, `docs`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.
  - Omit the scope, since this repository holds no platform, and every platform takes its commits in its own repository, apart from `chore(release): vX.Y.Z` of a release.
  - Subject is imperative, lowercase, no trailing period.
- PR descriptions follow the structure documented in [`CONTRIBUTING.md`](CONTRIBUTING.md#pull-requests). Sections: Summary, Changes, Testing, Related, Changelog (which `CHANGELOG.md` subsection the change belongs to: `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security`).
- Issue titles are plain descriptive English, not Conventional Commit format. Categorize issues and PRs with the labels of the repository (`bug`, `enhancement`, `documentation`, `question`, `good first issue`).
- Milestones are long-lived thematic epics with a verb-first descriptive title (e.g., `Refactor OpenRoSDE into a multi-platform reference implementation`), not per-release versions. A release belongs to the epic milestone that contains its work.
- Every PR adds a one-line entry under the matching subsection of `## [Unreleased]` in `CHANGELOG.md`, referencing its PR number (e.g., `- Add HSR platform support (#42).`).
- Releases are tagged `vX.Y.Z` on `main` and published on GitHub via `gh release create`, with notes sourced from the matching `CHANGELOG.md` section, while the epic milestone stays open.
- Never force-push to `main`. Never rewrite published history. PR title and description edits are safe and do not touch Git history.
- Do not use semicolons (`;`), en dashes (`–`), or em dashes (`—`) in any GitHub text: issue titles/descriptions, milestone titles/descriptions, PR titles/descriptions. Use a full stop or a new sentence instead of a semicolon. Use `: ` or a plain hyphen `-` instead of a dash.
- Use backticks for code identifiers (file names, commands, environment variables, functions, ROS packages, paths) in all GitHub text: issue titles/descriptions, milestone titles/descriptions, PR titles/descriptions. Do not use single quotes for code identifiers in GitHub text. Single quotes are reserved for Bash and ROS launch-file comments.
