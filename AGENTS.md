# AGENTS.md

This file contains instructions for AI coding agents working on this project.

## Project Overview

This project is OpenRoSDE, read "Open Robotic SDE", the open-source reference implementation of the Software Development Environment (SDE) for collaborative robotics research (see `README.md` for details).
It provides a containerized, multi-platform development environment based on Docker, ROS, and Gazebo that supports multiple robot platforms (TurtleBot3, UR5e, Fetch, Sciurus17, COBOTTA, HSR) through a shared configuration system.
It is being split into a platform-agnostic core with extensions, as [OpenRoSDE Split](#openrosde-split) describes, so read that section before changing anything.

### Tool Chain

- Containerization: [Docker](https://www.docker.com/) (with [Docker Compose](https://github.com/docker/compose)).
- GPU Acceleration: [Nvidia Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/index.html), [CUDA](https://developer.nvidia.com/cuda-toolkit) 11.2.
- Container OS: [Ubuntu](https://ubuntu.com/) 20.04 (Focal Fossa).
- Robotics Framework: [ROS](http://www.ros.org/) Noetic.
- Simulator: [Gazebo](http://gazebosim.org/).
- Visualization: [Rviz](https://github.com/ros-visualization/rviz).
- Behavior Engine: [FlexBE](http://flexbe.github.io/).
- Build System: [catkin](https://wiki.ros.org/catkin) (via `catkin build`).
- Multi-Terminal: [tmux](https://github.com/tmux/tmux/wiki), and [Terminator](https://gnometerminator.blogspot.com/) until `tmux` replaces it.
- Scripting: [Bash](https://www.gnu.org/software/bash/).
- Configuration: `.env` / `.env.custom` files.
- CI/CD: [GitLab CI](https://docs.gitlab.com/ee/ci/).
- Repository: [Git](https://git-scm.com/) (versioning), [GitLab](https://about.gitlab.com/) (hosting).
- Editor: [VS Code](https://code.visualstudio.com/).
- Agents: [Claude Code](https://claude.com/claude-code), [GitHub Copilot](https://github.com/features/copilot).
- License: [MIT](LICENSE), until the move to GitHub as OpenRoSDE under the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0).

## OpenRoSDE Split

On 2026-10-10 the maintainers approved the split of the SDE into OpenRoSDE, read "Open Robotic SDE": a platform-agnostic open core, with platforms, devices, and extensions around it, composed into setups.
The steps are tracked as issues #37 to #42 of the `Split the SDE into the OpenRoSDE core and its extensions` milestone (%5), and the ROS 2 work in the `Run OpenRoSDE on ROS 2 beside ROS 1` milestone (%3).
The reasoning, the full plan, and the state of the work live in the maintainers' note `Shin-Coarobo OpenRoSDE`, which is not public.

### Target Shape

- The core keeps the entry scripts, `scripts/`, `gitlab-ci/`, the `openrosde-base` image, the generic Docker Compose files, and `ros/openrosde_catkin_ws/` with FlexBE and `openrosde_launch`.
- Every file named after a platform (`env/<platform>.env`, `docker/<platform>-devel/`, `docker/docker-compose-<platform>.yaml`, `ros/<platform>_catkin_ws/`, `terminator/<platform>.config`, `docs/robot-platforms/<platform>.md`, and its patches) moves to the repository of that platform, or to a device or a setup where it belongs to one.
- A platform is one robot as sold, with its public drivers, and each canonical robot moves to an `openrosde-platform-<name>` repository: `turtlebot3`, `fetch`, `sciurus17`, `cobotta`, `hsr`, and the plain Universal Robots UR5e.
- A device is one upstream driver of hardware anyone can buy, such as a gripper, a camera, or an input device, with every model that driver supports, which names no robot and moves to a public `openrosde-device-<driver>` repository: first `openrosde-device-onrobot` for the OnRobot RG and VG grippers with the gripper action shim, `openrosde-device-realsense` for the RealSense cameras, and `openrosde-device-spacenav` for the 3Dconnexion SpaceMouse.
- A setup is one installation of a robot: it pins its platform, devices, and extensions, mounts the devices in the robot description, and holds the calibration, addresses, serial numbers, poses, layouts, and runbook of that installation alone.
  Each platform ships a default setup with the plain robot, and the user selects a setup rather than a platform.
- A setup is a template that any extension holds, named `<owner>-<platform>-<place>`, so one private extension of a company can hold its packages and the setups of all its robots.
- The Coarobo UR5e bench becomes the first setup, in the private extension of Coarobo, beside the bindings of Coarobo Sightline and Coarobo Viewport and the FastSAM segmentation, and the setup of a client takes the same shape in a private extension of that client.
- The Unity ROS TCP Endpoint leaves the core once Coarobo Sightline reaches robots through `rosbridge`, and moves with the Sightline bindings until then.
- `openrosde_launch:rosbridge_server_default.launch` stays in the core, since any web or Unity client can use it.
- The user layer stays in the core as the template every extension starts from.
- Terminator gives way to `tmux` sessions built by `RUN-TMUX-SESSION.bash` from the panes each part declares, and leaves once the maintainers have run the `tmux` sessions on a real robot (#38).
- The repository then moves to GitHub as OpenRoSDE under the Apache License 2.0, with a `NOTICE` that keeps the MIT notice of the earlier code, and the GitLab URL keeps resolving, since papers cite it.
- ROS 2 then comes beside ROS 1 and never replaces it, since robots such as the Fetch run only on ROS 1.

### Rules During the Split

- Keep every platform building and running on ROS 1 at every step, since the Coarobo UR5e bench runs its demos from `dev`.
- Add no new Coarobo setup or product binding to the core or to a canonical platform layer.
  Until its repository exists, put it in the user layer, or in the UR5e layer for the bench, and add it to the matching extraction issue.
- Design every mechanism so that a private setup or extension, cloned from a private repository of a client, works exactly as a public one does.
  Hard-code no Git group, registry, or host, and give the setups and extensions of Coarobo no special case.
- Keep `LICENSE` and the `<license>` of every `package.xml` on MIT until the move to GitHub, and change them only as part of that step.
- Keep the interfaces that Coarobo products use working through every step, as [Interfaces Used by Coarobo Products](#interfaces-used-by-coarobo-products) lists.

### Interfaces Used by Coarobo Products

Coarobo Sightline and Coarobo Viewport reach the robot through the interfaces below, started by the files named beside them.
The contract is kept in `Docs/robot-interface.md` of `coarobo/coarobo-sightline`, a private repository, and in the maintainers' `Shin-Coarobo OpenRoSDE` note.
Record a change of a topic name, a message type, a port, or the launch file that starts one of them in both places before making it.

- `/joint_states`, `/tf`, `/tf_static`, and `clock`: the bringup of each platform.
- `/servo_server/delta_twist_cmds`: MoveIt Servo, started by `openrosde_ur5e_teleop/launch/ur5e_teleop.launch`.
- `/gripper_controller/gripper_action`: the bench shim `ur5e_onrobot_rg_control_gripper_action.py` over `/onrobot_rg/set_command`.
- `/wrist_camera/depth/color/points_downsampled` and `/wrist_camera/color/image_raw/compressed_throttled`: `openrosde_ur5e_teleop/launch/ur5e_teleop_sightline.launch`.
- `/cmd_vel` for Coarobo Viewport: `ur5e_moveit_servo_viewport.py` of `ur5e_teleop_viewport.launch`.
- The camera streams of Coarobo Viewport: `openrosde_user_launch/launch/viewport_streams_ur5e.launch` and `viewport_demo_ur5e.launch`.
- `fetch_ee_cmd_vel`, relayed to the Cartesian twist controller of the Fetch: `openrosde_fetch_teleop`, started by `fetch_teleop_default.launch`.
- Port `10000` of the Unity ROS TCP Endpoint `0.7.0`: `openrosde_launch:ros_tcp_endpoint_default.launch`.
- Port `9090` of `rosbridge`: `openrosde_launch:rosbridge_server_default.launch`.

### Parallel Work

- Coarobo Sightline (`coarobo/coarobo-sightline`) and Coarobo Viewport (`coarobo/coarobo-viewport`) are developed in their own repositories, often by other agents at the same time as one working here.
- An agent working here owns this repository and the extension repositories of the split, and leaves those two repositories to their own sessions.
- Coarobo Sightline is moving from the Unity ROS TCP Endpoint to `rosbridge`, which Coarobo Viewport already uses, so that it no longer depends on OpenRoSDE and runs on ROS 1 and ROS 2 alike.

## Directory Structure

- `docker/`: Docker images and container scripts.
  - `openrosde-base/`: Shared base image (`Dockerfile`, helper `scripts/`).
  - `turtlebot3-devel/`: TurtleBot3 platform image.
  - `ur5e-devel/`: UR5e platform image.
  - `fetch-devel/`: Fetch platform image.
  - `sciurus17-devel/`: Sciurus17 platform image.
  - `cobotta-devel/`: COBOTTA platform image.
  - `hsr-devel/`: HSR platform image (Gazebo-only, open-source).
  - `user-devel/`: User overlay image (Layer 3, runtime container; inherits from `${OPENROSDE_ROBOT_PLATFORM}-devel`, built locally only).
  - `docker-compose.yaml`: Base service definitions (defines `openrosde-base`, `openrosde-platform`, and `openrosde`).
  - `docker-compose-nvidia.yaml`: Nvidia GPU overlay.
  - `docker-compose-wsl.yaml`: WSL 2 GPU overlay.
  - `docker-compose-turtlebot3.yaml`: TurtleBot3 platform overlay.
  - `docker-compose-ur5e.yaml`: UR5e platform overlay.
  - `docker-compose-fetch.yaml`: Fetch platform overlay.
  - `docker-compose-sciurus17.yaml`: Sciurus17 platform overlay.
  - `docker-compose-cobotta.yaml`: COBOTTA platform overlay.
  - `docker-compose-hsr.yaml`: HSR platform overlay.
  - `docker-compose-user.yaml`: User overlay (always loaded by `RUN-DOCKER-CONTAINER.bash`).
- `ros/`: ROS Catkin workspaces.
  - `openrosde_catkin_ws/`: Shared workspace (FlexBE packages, `ros_tcp_endpoint`, `openrosde_launch/`).
  - `turtlebot3_catkin_ws/`: TurtleBot3 workspace (`openrosde_turtlebot3_launch/`, `openrosde_turtlebot3_behaviors/`).
  - `ur5e_catkin_ws/`: UR5e workspace (`openrosde_ur5e_launch/`, `openrosde_ur5e_teleop/`, `openrosde_ur5e_behaviors/`).
  - `fetch_catkin_ws/`: Fetch workspace (`openrosde_fetch_launch/`, `openrosde_fetch_teleop/`, `openrosde_fetch_behaviors/`).
  - `sciurus17_catkin_ws/`: Sciurus17 workspace (`openrosde_sciurus17_launch/`, `openrosde_sciurus17_behaviors/`).
  - `cobotta_catkin_ws/`: COBOTTA workspace (`openrosde_cobotta_launch/`, `openrosde_cobotta_behaviors/`).
  - `hsr_catkin_ws/`: HSR workspace (`openrosde_hsr_launch/`, `openrosde_hsr_behaviors/`).
  - `user_catkin_ws/`: User overlay workspace (`openrosde_user_launch/`, `openrosde_user_behaviors/`). Platform-agnostic, apart from the Coarobo demo work (FastSAM and the Coarobo Viewport streams of the UR5e) that waits there for its extraction.
- `scripts/`: Shared shell scripts (`load-openrosde-env.bash`, `load-extension-paths.bash`, `list-robot-platforms.bash`, `list-robot-setups.bash`, `update-git-submodules.bash`, `apply-submodule-patches.bash`), and the optional scripts of each setup or platform in `scripts/<setup or platform>/`.
- `patches/`: Patches of the Git submodules, mirroring the submodule paths.
- `env/`: Per-platform environment templates (`turtlebot3.env`, `ur5e.env`, `fetch.env`, `sciurus17.env`, `cobotta.env`, `hsr.env`) plus `user.env` (user overlay reference template).
- `extensions/`: Extensions, each a Git repository cloned into `extensions/<extension>/` and ignored by the Git of the core, apart from `README.md`.
  An extension of a company may split the units of several robots into parts, `extensions/<extension>/parts/<part>/`, each with the layout of the core and activated by its name.
- `docs/`: Documentation.
  - `basic-usage.md`: Full setup guide.
  - `advanced-usage.md`: Advanced features and configuration.
  - `user-overlay.md`: User overlay (Layer 3) usage and customization.
  - `extensions.md`: Extensions cloned into `extensions/`, and how OpenRoSDE finds their files.
  - `robot-platforms/`: Platform-specific documentation (`turtlebot3.md`, `ur5e.md`, `fetch.md`, `sciurus17.md`, `cobotta.md`, `hsr.md`).
- `tmux/`: Pane files of the `tmux` sessions: `openrosde.panes` for the core and `<platform>.panes` for each platform.
- `terminator/`: Per-platform Terminator layout configuration (`turtlebot3.config`, `ur5e.config`, `fetch.config`, `sciurus17.config`, `cobotta.config`, `hsr.config`).
- `gitlab-ci/`: GitLab CI/CD pipeline: the parent `gitlab-ci.yml`, the shared jobs of the child pipeline (`openrosde-pipeline.yml`), and the scripts that generate it (`generate-ci-pipeline.bash`), build or reuse an image (`build-ci-image.bash`), test the Catkin workspaces (`test-catkin-workspaces.bash`), and publish the images (`publish-ci-images.bash`).

## Agent Persona

You are a Robotics Research Engineer assisting in the maintenance of this multi-platform Docker-based ROS development environment.
You have expertise in Docker, ROS, Bash scripting, and Linux system administration.

## Architecture

### Multi-Platform Design

OpenRoSDE supports multiple robot platforms through a single codebase controlled by the `OPENROSDE_ROBOT_PLATFORM` variable in `.env`:

- A shared base Docker image (`openrosde-base`) contains common tools and dependencies.
- Platform-specific images (`turtlebot3-devel`, `ur5e-devel`, `fetch-devel`, `sciurus17-devel`, `cobotta-devel`, `hsr-devel`) extend the base with robot-specific packages.
- A user overlay image (`user-devel`) extends the selected platform image and is the actual runtime container. It is platform-agnostic and built locally only (never pushed to the registry).
- The active extensions may add Docker layers (`docker/<name>-devel/Dockerfile`, `FROM ${OPENROSDE_PARENT_IMAGE}`) between the platform image and the user overlay, built locally only, in the order of the active folders, and `OPENROSDE_USER_PARENT_IMAGE` names the last one (see `docs/extensions.md`).
- The Catkin workspaces are sourced in sequence: shared (`openrosde_catkin_ws`), platform-specific (`${OPENROSDE_ROBOT_PLATFORM}_catkin_ws`), the workspaces of the active extensions, then user overlay (`user_catkin_ws`).
- All scripts derive their behavior from `OPENROSDE_ROBOT_PLATFORM` and `OPENROSDE_ROBOT_EXTENSIONS` loaded via `scripts/load-openrosde-env.bash`.
- A platform lives in the core, in an extension cloned into `extensions/`, or in a part of an extension, and `scripts/load-extension-paths.bash` resolves where its files are, on the host and inside the container alike (see `docs/extensions.md`).
  An environment template `env/<name>.env` is looked up in the core first, then in every cloned extension followed by its parts.
  A file named after the setup comes from the folder of the setup, and a file named after the platform from the folder of the platform, then from the core, so a clone that is not active never supplies one.
  Workspaces, Docker layers, Docker Compose overlays, and `tmux` panes only come from the core, the platform, the extensions or parts of `OPENROSDE_ROBOT_EXTENSIONS`, and the setup, and an overlay or a pane file named after a platform or a setup that is not active is left out.

### Configuration System

- `.env`: Default configuration (committed to Git). Do not add fallback defaults (`:-`) in scripts; all defaults live here.
- `.env.custom`: User overrides (Git-ignored, created from a platform template in `env/`).
- `scripts/load-openrosde-env.bash`: Shared loader sourced by all top-level `*.bash` scripts. Resolves `OPENROSDE_ROOT_DIR`, loads `.env`/`.env.custom`, and exports every `OPENROSDE_*` variable for Docker Compose interpolation and for the platform scripts.

### Platform Switching

Switching platforms requires only running `bash ./SWITCH-ROBOT-PLATFORM.bash <platform>` (e.g., `bash ./SWITCH-ROBOT-PLATFORM.bash ur5e`), which switches to the default setup of the platform.
A setup is a template `env/<setup>.env` that declares `OPENROSDE_ROBOT_SETUP=<setup>` with its platform and extensions, in the core or in an extension, and `bash ./SWITCH-ROBOT-SETUP.bash <setup>` clones the repositories of its `env/<setup>.repos` with `vcstool` before copying it to `.env.custom` (see `docs/extensions.md`).
The template of every platform is its default setup and declares `OPENROSDE_ROBOT_SETUP=<platform>`.
`scripts/load-extension-paths.bash` falls back to the platform as the setup when the template of `OPENROSDE_ROBOT_SETUP` does not run the active platform, so a `.env.custom` written before setups existed keeps its platform files.
`RUN-DOCKER-CONTAINER.bash` automatically detects containers from a different platform under the same Docker project and runs `docker compose down` to cleanly remove them before starting the new platform's container.

### Docker Compose Service Targeting

`docker-compose.yaml` defines three services:
- `openrosde-base` (build-only shared base image, no `container_name`).
- `openrosde-platform` (build-only platform-specific image, no `container_name`; image is `<platform>-devel:${OPENROSDE_DOCKER_IMAGE_TAG}`, `main` or `dev`).
- `openrosde` (runtime user-overlay container; image is `user-devel:latest`, built locally only, inherits from `openrosde-platform`).

Always target the `openrosde` service explicitly with `docker compose up -d openrosde` to avoid accidentally starting the build-only services, which have no `container_name` and would cause naming conflicts.
`BUILD-DOCKER-IMAGE.bash` builds all three services in order: `openrosde-base` -> `openrosde-platform` -> `openrosde`. The `user-devel` image is always built locally and is not pushed by `gitlab-ci/PUSH-DOCKER-IMAGE.bash`.

### Docker Compose Platform Overlays

Every platform has a Docker Compose overlay file (`docker-compose-<platform>.yaml`) that passes platform-specific environment variables to the container.
`RUN-DOCKER-CONTAINER.bash` automatically includes `docker-compose-${OPENROSDE_ROBOT_PLATFORM}.yaml` if the file exists, so new platforms can add their own overlay without modifying the script.
Platforms that do not yet require extra variables still have an overlay file for consistency.

### User Overlay (Layer 3)

The user overlay is a third Docker stage on top of `<platform>-devel`, intended for end-user customization without forking OpenRoSDE.
It is always built locally by `BUILD-DOCKER-IMAGE.bash`, never pushed to the registry, and platform-agnostic (the same overlay rebuilds on top of whichever `OPENROSDE_ROBOT_PLATFORM` is selected).

Components:
- `docker/user-devel/Dockerfile`: third-stage image. `FROM ${OPENROSDE_PLATFORM_IMAGE}` where `OPENROSDE_PLATFORM_IMAGE` defaults to `registry.gitlab.com/coarobo/sde/${OPENROSDE_ROBOT_PLATFORM}-devel:latest`.
- `docker/docker-compose-user.yaml`: always loaded by `RUN-DOCKER-CONTAINER.bash` (no `if -f` guard). Exposes `OPENROSDE_USER_*` environment variables and is the place to add user-specific volume mounts.
- `ros/user_catkin_ws/`: fourth Catkin workspace, sourced after the platform workspace in `source-catkin-workspaces.bash`, built by `build-catkin-workspaces.bash` and rebuilt by `reset-catkin-workspaces.bash`.
- `ros/user_catkin_ws/src/openrosde_user_launch/`: starter launch package with `user_example_default.launch` and a `config/` directory (`rviz/`, `maps/`) for user assets.
- `ros/user_catkin_ws/src/openrosde_user_behaviors/`: starter FlexBE behaviors package with `User Example Behavior` (uses only `LogState` + `WaitState`, runs on every platform).
- `env/user.env`: reference template documenting `OPENROSDE_USER_*` variables. Not auto-loaded; users add overrides to `.env.custom` instead.

`OPENROSDE_USER_*` defaults live in the top-level `.env` and in every per-platform `env/*.env` template (so platform switching does not erase the user-overlay defaults).
`scripts/load-openrosde-env.bash` exports every `OPENROSDE_*` variable, the `OPENROSDE_USER_*` ones included, so it can be interpolated by `docker-compose-user.yaml`.
The user overlay reuses the platform Terminator layout: `RUN-TERMINATOR-TERMINAL.bash` always opens `terminator/${OPENROSDE_ROBOT_PLATFORM}.config`, and Number 12 (`terminal25`) of every platform layout is pre-wired to the user-overlay starter (`openrosde_user_launch:user_example_default.launch`).
The remaining spare panes (Numbers 8-11) are free shells reserved for additional user-overlay launches.

### Tmux Sessions

`RUN-TMUX-SESSION.bash [docker-project] [session-layout]` runs the terminals in a `tmux` session named `openrosde-<platform>-<docker-project>`, or attaches to it if it already runs.
The session gathers the pane files of the setup (`tmux/<setup>.panes`), or else of the platform (`tmux/<platform>.panes`), of the active extensions and the setup (every other `tmux/*.panes` of their folders not named after a platform or a setup), then of the core (`tmux/openrosde.panes`), and opens a window on the first pane of each window name.
The pane file of a setup replaces that of its platform, as its Terminator layout does, and a device ships no pane file, since its panes belong to each setup.
Each line of a pane file reads `<layouts> <window> <launch-file> [<arg:=value> ...]`, where `<layouts>` is `*` or a comma-separated list of layouts (`default-gazebo`, `default-realworld`, or a layout of a setup), and the words `shell` and `host` open a shell in the container or on the host.
The windows are `robot` (bringup, RViz, MoveIt, and the secondary launches of the platform), `extra` (further launches of the platform), the windows of the extensions and the setup, `tools` (FlexBE app, rqt suite, ROS TCP Endpoint, `rosbridge`), `user` (user overlay starter and a container shell), and `host`.
The session turns the mouse on and titles the terminal `OpenRoSDE (<session>)`, which `maximize-app-window.bash` matches like the Terminator title.
Until Terminator is retired, keep `tmux/<platform>.panes` in step with `terminator/<platform>.config`, since the platform pane files were generated from the Terminator layouts.

### Terminator Layouts

Terminator configuration files are per-platform in `terminator/` (e.g., `turtlebot3.config`, `ur5e.config`).
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
Spare terminals (Numbers: 8-11) are available for additional launches (e.g., `realsense_camera_default_realworld.launch` at Number: 8 and `openrosde_user_launch:viewport_demo_ur5e.launch` at Number: 9 in the UR5e realworld layout).
Number: 12 (`terminal25`) is standardized across all platforms and both environments for `openrosde_user_launch:user_example_default.launch` (user overlay starter).
Number: 13 (`terminal26`) is standardized across all platforms and both environments for `openrosde_launch:rqt_suite_default.launch`.
Number: 14 (`terminal28`) is standardized across all platforms and both environments for `openrosde_launch:ros_tcp_endpoint_default.launch` (Unity ROS TCP Endpoint for Coarobo Sightline).
Number: 15 (`terminal29`) is standardized across all platforms and both environments for `openrosde_launch:rosbridge_server_default.launch`.

### Variable Naming Convention

All custom environment variables use the `OPENROSDE_` prefix. Examples:
- `OPENROSDE_ROBOT_PLATFORM`: Target robot platform (`turtlebot3`, `ur5e`, `fetch`).
- `OPENROSDE_ROBOT_SETUP`: Active setup, named after its template `env/<setup>.env` (the platform name for a default setup).
- `OPENROSDE_ROBOT_EXTENSIONS`: Names of the active extensions in `extensions/` or of their parts in `extensions/<extension>/parts/`, separated by spaces, each held by one folder only.
- `OPENROSDE_DOCKER_REGISTRY`: Registry of the base and platform images (`registry.gitlab.com/coarobo/sde` by default).
- `OPENROSDE_DOCKER_IMAGE_TAG`: Tag of the base and platform images, `main` or `dev`, or `auto` to derive it from the branch.
- `OPENROSDE_CONTAINER_ROOT_DIR`: OpenRoSDE root path inside the Docker container.
- `OPENROSDE_ROOT_DIR`: OpenRoSDE root path on the host (auto-resolved, not in `.env`).
- `OPENROSDE_DOCKER_PROJECT`: Docker project name for container naming.
- `OPENROSDE_DOCKER_CONTAINER`: Derived container name (`openrosde-${OPENROSDE_ROBOT_PLATFORM}-${OPENROSDE_DOCKER_PROJECT}-1`).
- `OPENROSDE_USER_ID` / `OPENROSDE_GROUP_ID`: Host user/group IDs passed to the container.
- `OPENROSDE_BASE_DOCKERFILE_COMMIT_SHORT_SHA` / `OPENROSDE_ROBOT_PLATFORM_DOCKERFILE_COMMIT_SHORT_SHA`: Git commit hashes for image traceability.
- `OPENROSDE_ROBOT_PLATFORM_DOCKERFILE`: Derived path of the platform Dockerfile, relative to the OpenRoSDE root, in the core or in an extension.

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
- Do not use fallback default syntax (`${VAR:-default}`) in scripts; all defaults belong in `.env`.
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
- Do not use fallback default syntax (`${VAR:-default}`); all defaults belong in `.env`.
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
  - `<!-- https://github.com/<upstream-repo> -->` — URL of the upstream repository this file is based on or extends.
  - `<!-- Upstream default: $(find <pkg>)/launch/<file>.launch -->` — path to the upstream launch file used as the starting point, when one exists.
  - `<!-- OpenRoSDE-specific: <one-line description> -->` — instead of the upstream line, when the file has no direct upstream counterpart.

RViz launch files use an OpenRoSDE-owned `.rviz` config file stored in `config/rviz/` within the `openrosde_<platform>_launch` package.
These config files are copied from the upstream default and modified to set `Fullscreen: false` under `Window Geometry:`.
All RViz launch nodes use `required="true"` so the layout closes when RViz exits.
Each RViz launch file also includes a `<node name="maximize_rviz" pkg="openrosde_launch" type="maximize-app-window.bash" args="RViz" />` node that maximizes the window via `wmctrl` after it opens.
The corresponding bringup Gazebo launch files include the same pattern with `name="maximize_gazebo"` and `args="Gazebo"` to maximize the Gazebo window.
The `flexbe_app_default.launch` file includes the same pattern with `name="maximize_flexbe"` and `args="FlexBE"` to maximize the FlexBE App window (the `"FlexBE"` substring matches the `"FlexBE App"` window title; using a single word avoids roslaunch splitting the arg on the space).
The `maximize-app-window.bash` script lives in `ros/openrosde_catkin_ws/src/openrosde_launch/scripts/` and is installed via `openrosde_launch`'s `CMakeLists.txt`.
The script retries for up to 60 seconds to handle slow application startup (e.g. the FlexBE App nwjs window), then runs a short focus-restore loop that re-asserts the maximized state and refocuses Terminator (matched by its window title `OpenRoSDE (` set in `terminator/*.config`).
A non-blocking `flock` on `/tmp/openrosde_maximize_focus.lock` ensures only one concurrent instance runs the focus-restore loop at a time, which prevents flickering when several maximize nodes run in parallel (e.g. RViz, FlexBE, the rqt suite).
`wmctrl` must be installed in the container (it is included in the `openrosde-base` Dockerfile).

### ROS Packages

ROS packages (e.g., `openrosde_ur5e_teleop` in `ur5e_catkin_ws`) extend the standard launch-only pattern with Python nodes and config files.
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
    The `<description>` element must be a single line with no embedded newlines; multi-line descriptions render as literal whitespace in the FlexBE app.
  - `config/<behavior_name>.yaml`: Behavior parameters (placeholder; values are set in the manifest).
  - `setup.py`, `CMakeLists.txt`, `package.xml`: Standard catkin Python package boilerplate.
  - `package.xml` uses `format="2"`, exports `<flexbe_behaviors />`, and lists `flexbe_core`, `flexbe_states`, and any generic state packages (`flexbe_navigation_states`, `flexbe_manipulation_states`) as `exec_depend`.
    `format="2"` requires `<exec_depend>` tags; using `<run_depend>` causes a `catkin_pkg.package.InvalidPackage` error at build time.
- `openrosde_<platform>_flexbe_states/`: Reserved for platform-specific custom FlexBE states (empty by default; only add states here that cannot be satisfied by `flexbe_behavior_engine` or `flexbe_generic_states`).
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
  When manually editing state names, ensure the 3-tab indentation of the `OperatableStateMachine.add(` line is preserved; dropping it to column 0 causes an `expected an indented block` `SyntaxError` at runtime.

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
- Use `[[_TOC_]]` for GitLab auto-generated table of contents (GitLab-specific, harmless on other platforms).
- Use `- ` (dash + space) for unordered list items.
- Use `1. `, `2. `, `3. ` (sequential numbers) for ordered list items.
- Align continuation content (code blocks, paragraphs, nested lists) with the text of the parent list item: 2 spaces after `- `, 4 spaces after `N. `.
- Write one sentence per line for cleaner Git diffs.
- Use backticks `` ` ` `` around inline code, file names, commands, variables, functions, and paths.
- Use GitHub alerts for callout blocks: `> [!NOTE]`, `> [!TIP]`, `> [!IMPORTANT]`, `> [!WARNING]`, `> [!CAUTION]`.
  Each continuation line must be prefixed with `> `.
- Use `shell` as the language identifier for shell code blocks.
- Use `mermaid` fenced code blocks for diagrams (rendered natively by GitHub, GitLab, and VS Code with extensions).
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

### GitLab CI

- Use 80-character `#` lines as section separators.
- Use `OPENROSDE_` prefix for all custom CI variables.
- Generate the jobs of every platform in `gitlab-ci/generate-ci-pipeline.bash` rather than listing the platforms by hand.
- Keep the logic of a job in a script of `gitlab-ci/`, so that the YAML only wires the jobs together.
- Give every artifact an `expire_in`, and hand images between jobs through the registry, never through the disk of the runner.

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
- Shared (`openrosde_catkin_ws`): `flexbe_behavior_engine`, `flexbe_app`, `flexbe_generic_states`, `ros_tcp_endpoint` (Unity ROS TCP Endpoint, branch `main`, wrapped by `openrosde_launch/scripts/ros_tcp_endpoint_server.py`).
- UR5e (`ur5e_catkin_ws`): `onrobot`, `roboticsgroup_upatras_gazebo_plugins`.
- Fetch (`fetch_catkin_ws`): `fetch_gazebo` (branch `gazebo11`, provides `fetch_gazebo` and `fetch_gazebo_demo`).
- Sciurus17 (`sciurus17_catkin_ws`): `sciurus17_ros` (branch `master`, ROS 1), `sciurus17_description` (branch `main`, dependency package used by ROS 1 setup).
- COBOTTA (`cobotta_catkin_ws`): `denso_cobotta_ros` (branch `melodic-devel`, the most up-to-date branch, 2 commits ahead of `master`, latest release v1.2.4).
- HSR (`hsr_catkin_ws`): no submodules. The `hsr-devel` Docker image is built as a multi-stage image whose first stage is the publicly distributed Toyota binary image `ghcr.io/hsr-project/tmc_wrs_binary:noetic-latest` (BSD 3-Clause Clear). The HSR ROS Noetic stack (URDF, SRDF, MoveIt, navigation, controllers, all `hsrb_*` and `tmc_*` packages, and the WRS apartment world) is installed into `/opt/ros/noetic` inside the binary image (via `catkin config --cmake-args -DCMAKE_INSTALL_PREFIX=/opt/ros/noetic`) and COPY-merged into the OpenRoSDE base. No separate workspace overlay is needed; sourcing `/opt/ros/noetic/setup.bash` is sufficient. The corresponding ROS Noetic source code is hosted on the private `git.hsr.io` GitLab and is intentionally not vendored.

Current patches:
- `patches/ros/openrosde_catkin_ws/src/flexbe_app/0001-fix-curl-redirect.patch`: Fixes a broken curl redirect in the FlexBE app.
- `patches/ros/openrosde_catkin_ws/src/flexbe_app/0002-set-window-maximized.patch`: Sets `"initial_state": "maximized"` in the nwjs `package.json` so the FlexBE App window opens maximized.
- `patches/ros/cobotta_catkin_ws/src/denso_cobotta_ros/0001-fix-comments-collada.patch`: Expands self-closing `<comments/>` to `<comments></comments>` in 6 Collada mesh files (`base_link.dae`, `J1.dae`–`J3.dae`, `J5.dae`, `J6.dae`) to fix an RViz/Assimp parse error ("Expected end of `<comments>` element").
- `patches/ros/cobotta_catkin_ws/src/denso_cobotta_ros/0002-fix-gripper-pid-gain.patch`: Uncomments the `joint_gripper` PID gain entry in `gazebo_cobotta_control.yaml` to eliminate a `gazebo_ros_control` error when spawning the robot with `gripper_type:=parallel` in Gazebo.
- `patches/ros/cobotta_catkin_ws/src/denso_cobotta_ros/0003-fix-blender-mesh-materials.patch`: Sets `ambient` to `0.5 0.5 0.5 1` and `emission` to `0.04 0.04 0.04 1` in 6 Blender-exported Collada mesh files (`J4.dae`, `gripper_base.dae`, `left_finger.dae`, `right_finger.dae`, `pad.dae`, `vacuum.dae`) to fix black rendering under OGRE/Mesa caused by explicit `ambient: 0 0 0 1`.
- `patches/ros/cobotta_catkin_ws/src/denso_cobotta_ros/0004-add-srdf-named-states.patch`: Adds `home` (j3=π/2, all others=0) and `up` (j2=−π/4, j3=π/2, j5=π/4) named group states to `cobotta.srdf.xacro` for the `arm` group, enabling `SrdfStateToMoveit` FlexBE states to drive the arm to pre-defined configurations.
- `patches/ros/fetch_catkin_ws/src/fetch_gazebo/0001-add-cartesian-twist-controller.patch`: Adds `arm_controller/cartesian_twist` to `default_controllers.yaml` of `fetch_gazebo` and loads it in Gazebo, for `openrosde_fetch_teleop` to drive from Coarobo Sightline.
- `patches/ros/ur5e_catkin_ws/src/onrobot/0001-fix-duplicate-world.patch`: Comments out the `world` link and its joint in `onrobot_rg2.xacro`, which duplicate the `world` link of the UR5e description.

## Adding a New Platform

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for the full step-by-step guide.
The platforms are found by name: `scripts/list-robot-platforms.bash` lists every `env/<platform>.env` that declares `OPENROSDE_ROBOT_PLATFORM=<platform>` alone on its line, with no quotes and no trailing comment, and the rest of the extension system of the [OpenRoSDE Split](#openrosde-split) (#38) changes this section again.
A new platform goes either into the core or into an extension repository of its own with the same layout, cloned into `extensions/` (see `docs/extensions.md`), where it needs no registration at all.
When adding a platform named `<platform>`, create these files:

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

The platform scripts run with every `OPENROSDE_*` variable exported, and the launch package is always `openrosde_<platform>_launch`.
Then update `<platform>` in the files that still list the platforms:

- `README.md`: platform table, Mermaid diagram, directory structure, docs table.
- `AGENTS.md`: platform lists, directory structure, submodule list, patch list.

## Build Commands

- Build Docker images: `bash ./BUILD-DOCKER-IMAGE.bash`.
  - Default behavior: pulls the `main` or `dev` images from the registry, as `OPENROSDE_DOCKER_IMAGE_TAG` selects, or builds current platform with cache.
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

## Real Robots

- Never publish a topic, call a service or an action, or start a node or a launch file that can move a real robot or its gripper, unless a person is with the robot and has asked for it.
- Check a change in Gazebo first, and leave the test on the real robot to a person standing by it.
- The Coarobo UR5e bench runs its demos from `dev`, so a change merged into `dev` reaches a real robot.

## Deployment Considerations

- The project is configured for GitLab CI/CD (see `gitlab-ci/gitlab-ci.yml`), with a parent pipeline that generates a child pipeline of one image job and one test job per platform found by name.
- The jobs run on the runner whose tag `OPENROSDE_CI_RUNNER_TAG` names, `privileged-docker` by default for a self-managed Docker executor in privileged mode, or the tag of an instance runner of GitLab.com when shared runners are enabled.
- Jobs hand their images to each other through the registry only, with Docker-in-Docker over TLS, so nothing is kept on the runner between jobs.
- An image carries the label `com.coarobo.openrosde.source-hash`, the hash of the folders it is built from, and a job retags an identical `dev` or `main` image on the registry instead of building it again.
- Every pipeline pushes its images as `pipeline-<id>`, and the pipelines of `dev` and `main` publish them as `dev` and `main`, the only tags the cleanup policy of the registry keeps.
- The test job of a platform builds its Catkin workspaces in its image, then checks with `gitlab-ci/check-launch-files.bash` that every launch entry point of its `tmux/<platform>.panes` and of `tmux/openrosde.panes` resolves with `roslaunch --files`, which starts no node.
- Every artifact expires, the Catkin logs of a failed test after a week and the generated child pipeline after a day.
- Docker images are pushed to `OPENROSDE_DOCKER_REGISTRY`, `registry.gitlab.com/coarobo/sde/` by default, which serves them to anyone without a token, so never write a registry token in a script.
- Image traceability: each image embeds `OPENROSDE_DOCKER_IMAGE_VERSION` from the Dockerfile's Git commit hash, and the labels `org.opencontainers.image.revision` and `org.opencontainers.image.source`.

## Versioning & Commits

- Use [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) for all commit messages and merge request titles.
- Follow [Semantic Versioning](https://semver.org/) for releases.
- Follow [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) for `CHANGELOG.md`.
- Follow the [Make a README](https://www.makeareadme.com/) guidelines for `README.md` structure.

## GitLab Workflow

The project is hosted at <https://gitlab.com/coarobo/SDE>.
See [`CONTRIBUTING.md`](CONTRIBUTING.md#gitlab-project-organization) for the full human-facing description.

Agent rules:

- Default branch is `main`, which holds the releases.
  `dev` is the protected integration branch, where agents work and from which the Coarobo UR5e bench runs its demos.
- Short-lived branches are named `<type>/<slug>` after the Conventional Commit type (e.g., `feat/atr-open-house-demo`, `fix/registry-anonymous-pull`), branch from the latest `dev`, and merge back into `dev` through an MR.
- `dev` merges into `main` through an MR when the maintainers decide that a release is due.
- Ask the maintainer before every `git add`, commit, merge, rebase, reset, push, or branch deletion, and show the diff first.
- Never stash, reset, restore, check out over, or clean work that someone else left in a working tree.
- End every commit an agent writes with a `Co-authored-by: <agent and model> <noreply address>` trailer after a blank line, as [GitHub documents it](https://docs.github.com/en/pull-requests/committing-changes-to-your-project/creating-and-editing-commits/creating-a-commit-with-multiple-authors), while the maintainer stays the author.
- Commit messages and MR titles use Conventional Commits: `type(scope): subject`.
  - Allowed types: `feat`, `fix`, `docs`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.
  - Scope is a platform name only: `turtlebot3`, `ur5e`, `fetch`, `sciurus17`, `cobotta`, `hsr`. Omit the scope entirely for cross-platform or repository-wide changes.
  - Subject is imperative, lowercase, no trailing period.
- MR descriptions follow the structure documented in [`CONTRIBUTING.md`](CONTRIBUTING.md#merge-requests). Sections: Summary, Changes, Testing, Related, Changelog (which `CHANGELOG.md` subsection the change belongs to: `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security`).
- Issue titles are plain descriptive English, not Conventional Commit format. Categorize issues and MRs with the labels of the `coarobo` group (`default:bug`, `default:enhancement`, `default:documentation`, `default:discussion`, `default:critical`, `default:suggestion`, `default:support`, `default:confirmed`, `custom:hardware`, `custom:administration`).
- Milestones are long-lived thematic epics with a verb-first descriptive title (e.g., `Refactor OpenRoSDE into a multi-platform reference implementation`), not per-release versions. A release belongs to the epic milestone that contains its work.
- Every MR adds a one-line entry under the matching subsection of `## [Unreleased]` in `CHANGELOG.md`, referencing its MR number (e.g., `- Add HSR platform support (!42).`).
- Releases are tagged `vX.Y.Z` on `main` and published on GitLab via `glab release create`, with notes sourced from the matching `CHANGELOG.md` section and linked to their epic milestone. Note that `glab release create --milestone` closes the linked milestone, so reopen the epic afterward with `glab api -X PUT "projects/:id/milestones/:milestone_id" -f "state_event=activate"`.
- Never force-push to `main`. Never rewrite published history. MR title and description edits are safe and do not touch Git history.
- Do not use semicolons (`;`), en dashes (`–`), or em dashes (`—`) in any GitLab text: issue titles/descriptions, milestone titles/descriptions, MR titles/descriptions. Use a full stop or a new sentence instead of a semicolon. Use `: ` or a plain hyphen `-` instead of a dash.
- Use backticks for code identifiers (file names, commands, environment variables, functions, ROS packages, paths) in all GitLab text: issue titles/descriptions, milestone titles/descriptions, MR titles/descriptions. Do not use single quotes for code identifiers in GitLab text. Single quotes are reserved for Bash and ROS launch-file comments.
