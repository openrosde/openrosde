# AGENTS.md

This file contains instructions for AI coding agents working on this project.

## Project Overview

This project is the open-source reference implementation of the Software Development Environment (SDE) for collaborative robotics research (see `README.md` for details).
It provides a containerized, multi-platform development environment based on Docker, ROS, and Gazebo that supports multiple robot platforms (TurtleBot3, UR5e, Fetch) through a shared configuration system.

### Tool Chain

- Containerization: [Docker](https://www.docker.com/) (with [Docker Compose](https://github.com/docker/compose)).
- GPU Acceleration: [Nvidia Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/index.html), [CUDA](https://developer.nvidia.com/cuda-toolkit) 11.2.
- Container OS: [Ubuntu](https://ubuntu.com/) 20.04 (Focal Fossa).
- Robotics Framework: [ROS](http://www.ros.org/) Noetic.
- Simulator: [Gazebo](http://gazebosim.org/).
- Visualization: [Rviz](https://github.com/ros-visualization/rviz).
- Behavior Engine: [FlexBE](http://flexbe.github.io/).
- Build System: [catkin](https://wiki.ros.org/catkin) (via `catkin build`).
- Multi-Terminal: [Terminator](https://gnometerminator.blogspot.com/).
- Scripting: [Bash](https://www.gnu.org/software/bash/).
- Configuration: `.env` / `.env.custom` files.
- CI/CD: [GitLab CI](https://docs.gitlab.com/ee/ci/).
- Repository: [Git](https://git-scm.com/) (versioning), [GitLab](https://about.gitlab.com/) (hosting).
- Editor: [VS Code](https://code.visualstudio.com/).
- Agent: [GitHub Copilot](https://github.com/features/copilot).
- License: [MIT](LICENSE).

## Directory Structure

- `docker/`: Docker images and container scripts.
  - `sde-base/`: Shared base image (`Dockerfile`, helper `scripts/`).
  - `turtlebot3-devel/`: TurtleBot3 platform image.
  - `ur5e-devel/`: UR5e platform image.
  - `fetch-devel/`: Fetch platform image.
  - `sciurus17-devel/`: Sciurus17 platform image.
  - `docker-compose.yaml`: Base service definitions.
  - `docker-compose-nvidia.yaml`: Nvidia GPU overlay.
  - `docker-compose-wsl.yaml`: WSL 2 GPU overlay.
  - `docker-compose-turtlebot3.yaml`: TurtleBot3 platform overlay.
  - `docker-compose-ur5e.yaml`: UR5e platform overlay.
  - `docker-compose-fetch.yaml`: Fetch platform overlay.
  - `docker-compose-sciurus17.yaml`: Sciurus17 platform overlay.
- `ros/`: ROS Catkin workspaces.
  - `sde_catkin_ws/`: Shared workspace (FlexBE packages).
  - `turtlebot3_catkin_ws/`: TurtleBot3 workspace.
  - `ur5e_catkin_ws/`: UR5e workspace.
  - `fetch_catkin_ws/`: Fetch workspace.
  - `sciurus17_catkin_ws/`: Sciurus17 workspace.
- `scripts/`: Shared shell scripts (`load-sde-env.bash`).
- `env/`: Per-platform environment templates (`turtlebot3.env`, `ur5e.env`, `fetch.env`, `sciurus17.env`).
- `docs/`: Documentation.
  - `basic-usage.md`: Full setup guide.
  - `advanced-usage.md`: Advanced features and configuration.
  - `robot-platforms/`: Platform-specific documentation (`turtlebot3.md`, `ur5e.md`, `fetch.md`, `sciurus17.md`).
- `terminator/`: Per-platform Terminator layout configuration (`turtlebot3.config`, `ur5e.config`, `fetch.config`, `sciurus17.config`).
- `gitlab-ci/`: GitLab CI/CD pipeline scripts.

## Agent Persona

You are a Robotics Research Engineer assisting in the maintenance of this multi-platform Docker-based ROS development environment.
You have expertise in Docker, ROS, Bash scripting, and Linux system administration.

## Architecture

### Multi-Platform Design

The SDE supports multiple robot platforms through a single codebase controlled by the `SDE_ROBOT_PLATFORM` variable in `.env`:

- A shared base Docker image (`sde-base`) contains common tools and dependencies.
- Platform-specific images (`turtlebot3-devel`, `ur5e-devel`, `fetch-devel`, `sciurus17-devel`) extend the base with robot-specific packages.
- Two Catkin workspaces are sourced in sequence: shared (`sde_catkin_ws`) then platform-specific (`${SDE_ROBOT_PLATFORM}_catkin_ws`).
- All scripts derive their behavior from `SDE_ROBOT_PLATFORM` loaded via `scripts/load-sde-env.bash`.

### Configuration System

- `.env`: Default configuration (committed to Git). Do not add fallback defaults (`:-`) in scripts; all defaults live here.
- `.env.custom`: User overrides (Git-ignored, created from a platform template in `env/`).
- `scripts/load-sde-env.bash`: Shared loader sourced by all top-level `*.bash` scripts. Resolves `SDE_ROOT_DIR`, loads `.env`/`.env.custom`, exports variables for `docker-compose.yaml` interpolation.

### Platform Switching

Switching platforms requires only running `bash ./SWITCH-ROBOT-PLATFORM.bash <platform>` (e.g., `bash ./SWITCH-ROBOT-PLATFORM.bash ur5e`).
`RUN-DOCKER-CONTAINER.bash` automatically detects containers from a different platform under the same Docker project and runs `docker compose down` to cleanly remove them before starting the new platform's container.

### Docker Compose Service Targeting

`docker-compose.yaml` defines two services: `sde-base` (build-only base image) and `sde` (platform-specific runtime container).
Always target the `sde` service explicitly with `docker compose up -d sde` to avoid accidentally starting the `sde-base` service, which has no `container_name` and causes naming conflicts.

### Docker Compose Platform Overlays

Every platform has a Docker Compose overlay file (`docker-compose-<platform>.yaml`) that passes platform-specific environment variables to the container.
`RUN-DOCKER-CONTAINER.bash` automatically includes `docker-compose-${SDE_ROBOT_PLATFORM}.yaml` if the file exists, so new platforms can add their own overlay without modifying the script.
Platforms that do not yet require extra variables still have an overlay file for consistency.

### Terminator Layouts

Terminator configuration files are per-platform in `terminator/` (e.g., `turtlebot3.config`, `ur5e.config`).
Layout names follow the pattern: `sde-<platform>-term-11-<variant>-<environment>`.
`RUN-TERMINATOR-TERMINAL.bash` pre-starts the Docker container with `--no-exec` before launching Terminator to avoid race conditions from multiple panes running `RUN-DOCKER-CONTAINER.bash` simultaneously.
The `sed` command injects `${SDE_DOCKER_PROJECT}` into the config, producing a `.config.tmp` file that is git-ignored.

### Variable Naming Convention

All custom environment variables use the `SDE_` prefix. Examples:
- `SDE_ROBOT_PLATFORM`: Target robot platform (`turtlebot3`, `ur5e`, `fetch`).
- `SDE_CONTAINER_ROOT_DIR`: SDE root path inside the Docker container.
- `SDE_ROOT_DIR`: SDE root path on the host (auto-resolved, not in `.env`).
- `SDE_DOCKER_PROJECT`: Docker project name for container naming.
- `SDE_DOCKER_CONTAINER`: Derived container name (`sde-${SDE_ROBOT_PLATFORM}-${SDE_DOCKER_PROJECT}-1`).
- `SDE_USER_ID` / `SDE_GROUP_ID`: Host user/group IDs passed to the container.
- `SDE_BASE_DOCKERFILE_COMMIT_SHORT_SHA` / `SDE_ROBOT_PLATFORM_DOCKERFILE_COMMIT_SHORT_SHA`: Git commit hashes for image traceability.

## Code Style

### Bash Scripts

- Start every script with `#!/bin/bash`.
- Add a header comment block after the shebang describing the script's purpose, usage, and arguments.
- Use 80-character `#` lines as section separators.
- Add a comment before each logical block explaining its purpose.
- Use single quotes `' '` around code-related references in comments (e.g., `# Load the default environment variables from the '.env' file:`).
- Use `${VARIABLE}` syntax (with curly braces) for all variable references.
- Prefix all custom variables with `SDE_` (e.g., `SDE_ROBOT_PLATFORM`, not `PLATFORM`).
- Do not use fallback default syntax (`${VAR:-default}`) in scripts; all defaults belong in `.env`.
- Use `source` instead of `.` for sourcing scripts.
- Use `pushd` / `popd` for temporary directory changes in functions.
- Quote variables in paths: `"${SDE_ROOT_DIR}"` (host scripts) but `${SDE_CONTAINER_ROOT_DIR}` (container scripts where paths are controlled).
- Top-level entry-point scripts (`BUILD-DOCKER-IMAGE.bash`, `RUN-DOCKER-CONTAINER.bash`, etc.) are `UPPER-CASE-KEBAB.bash`.
- Helper scripts in `scripts/` and `docker/sde-base/scripts/` are `lower-case-kebab.bash`.
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
source ${SDE_CONTAINER_ROOT_DIR}/.env

# Overwrite the default environment variables with the user's variables from the '.env.custom' file (if it exists):
if [ -f ${SDE_CONTAINER_ROOT_DIR}/.env.custom ]; then
  source ${SDE_CONTAINER_ROOT_DIR}/.env.custom
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

Launch files live in platform-specific `sde_<platform>_launch` packages (e.g., `sde_turtlebot3_launch`, `sde_ur5e_launch`).

File names follow the pattern: `<component>_<variant>_<environment>.launch`

- `<component>`: The subsystem or feature (e.g., `turtlebot3_bringup`, `ur5e_moveit`, `onrobot_rg_control`).
- `<variant>`:
  - `default`: Configured as close as possible to the official documentation by including upstream default launch files.
  - `custom`: Customized launch file for specific SDE use cases.
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

### ROS Packages

Custom ROS packages in this project follow these conventions:

- Naming: `sde_launch` for shared launch files (in `sde_catkin_ws`), `sde_<platform>_launch` for platform-specific launch files (in `<platform>_catkin_ws`).
- `package.xml`: Use format 2 (`<package format="2">`), MIT license, `lotfi@coarobo.com` as maintainer/author email, `https://coarobo.com/SDE` as website URL, `https://gitlab.com/coarobo/SDE` as repository URL.
- `CMakeLists.txt`: Minimal template for launch-only packages (no C++ or Python nodes): `cmake_minimum_required`, `find_package(catkin REQUIRED COMPONENTS)`, `catkin_package()`, `include_directories`.
- `README.md`: Title (`# package_name`), one-line description, Maintainer/Author with `- ` list items, optional Gazebo section with recommended startup order and Terminator command, and a `## Launch Files` table listing all `.launch` files with descriptions.
- Include a `.gitignore` file in every package (can be empty).

Packages prefixed with `coarobo_` (e.g., `coarobo_teleop` in `ur5e_catkin_ws`) are proprietary Coarobo GK packages.
They may contain Python nodes, config files, and URDF in addition to launch files.
They follow the same `package.xml` and `README.md` conventions above, except:

- License: `Copyright (c) <year> Coarobo GK` (proprietary, not MIT).
- `CMakeLists.txt`: Includes `catkin_install_python` for Python node scripts.

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
- Keep `README.md` concise with links to detailed guides in `docs/`.
- Platform-specific documentation goes in `docs/robot-platforms/`.
- Use badges following the `[![Label](badge-url)](link-url)` pattern.
- Prefix product names with their maker name (e.g., Universal Robots UR5e, OnRobot RG2, Intel RealSense D435i, Robotis TurtleBot3, 3Dconnexion SpaceNavigator).
- Reference the host machine as "Ubuntu development machine".
- Decorate all `##` and `###` headers with a leading emoji in `README.md` and `docs/` files only (not in package-level READMEs or `AGENTS.md`).
  Use a single emoji that reflects the section topic, placed before the header text (e.g., `## 🚀 Quick Start`).
  Reuse the same emoji for semantically equivalent headers across files (e.g., `🔗 External Resources`, `⚙️ Platform Configuration`).

### GitLab CI

- Use 80-character `#` lines as section separators.
- Use `SDE_` prefix for all custom CI variables.
- Use parallel matrix builds for multi-platform CI jobs.

### Submodule Patches

- Patch files for Git submodules live in `patches/` mirroring the full submodule path (e.g., `patches/ros/sde_catkin_ws/src/flexbe_app/`).
- Name patch files with a numbered prefix and three kebab-case words starting with a verb: `0001-fix-curl-redirect.patch`.
- Patches are applied idempotently by `scripts/apply-submodule-patches.bash` after `git submodule update --init --recursive` in `SETUP-DEVEL-MACHINE.bash`.
- To create a patch: make changes in the submodule, run `git diff > <patch-file>`, then reset the submodule with `git checkout .`.

### Git Submodules

Git submodules provide third-party ROS packages that are not available as Noetic debian packages.
The Dockerfile installs their system dependencies via `apt-get`, and the packages themselves are built from source at `catkin build` time inside the container.
All submodules use `ignore = dirty` in `.gitmodules`.

Current submodules:
- Shared (`sde_catkin_ws`): `flexbe_behavior_engine`, `flexbe_app`, `flexbe_generic_states`.
- UR5e (`ur5e_catkin_ws`): `onrobot`, `roboticsgroup_upatras_gazebo_plugins`.
- Fetch (`fetch_catkin_ws`): `fetch_gazebo` (branch `gazebo11`, provides `fetch_gazebo` and `fetch_gazebo_demo`).
- Sciurus17 (`sciurus17_catkin_ws`): `sciurus17_ros` (branch `master`, ROS 1), `sciurus17_description` (branch `main`, dependency package used by ROS 1 setup).

## Build Commands

- Build Docker images: `bash ./BUILD-DOCKER-IMAGE.bash`.
- Build Catkin workspaces (inside container): `sde-reset-catkin-workspaces` or `sde-build-catkin-workspaces`.
- Switch platform: `bash ./SWITCH-ROBOT-PLATFORM.bash <platform>` (e.g., `bash ./SWITCH-ROBOT-PLATFORM.bash ur5e`).
- Run Docker container: `bash ./RUN-DOCKER-CONTAINER.bash`.
- Run Terminator layout: `bash ./RUN-TERMINATOR-TERMINAL.bash`.
- Restart Chrony service: `bash ./RESTART-CHRONY-SERVICE.bash` (resyncs host and robot clocks via Chrony).
- Bringup robot: `bash ./BRINGUP-ROS-ROBOT.bash <rosmaster-hostname>` (SSH into the robot and launch bringup nodes).
- Push Docker images: `bash gitlab-ci/PUSH-DOCKER-IMAGE.bash` (uses `docker logout`/`docker login` to force re-authentication).

## Testing Pipeline

- Verify Docker images build successfully with `bash ./BUILD-DOCKER-IMAGE.bash`.
- Verify Catkin workspaces build inside the container with `sde-reset-catkin-workspaces`.
- Check for hardcoded paths: `grep -rn '/root/SDE' --include='*.bash' --include='*.yaml' --include='*.yml' --include='Dockerfile' .`

## Deployment Considerations

- The project is configured for GitLab CI/CD (see `gitlab-ci/gitlab-ci.yml`).
- Docker images are pushed to `registry.gitlab.com/coarobo/sde/`.
- CI uses parallel matrix builds for all supported platforms (`turtlebot3`, `ur5e`, `fetch`).
- Image traceability: each image embeds `SDE_DOCKER_IMAGE_VERSION` from the Dockerfile's Git commit hash.

## Versioning & Commits

- Use [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) for all commit messages.
- Follow [Semantic Versioning](https://semver.org/) for releases.
- Follow the [Make a README](https://www.makeareadme.com/) guidelines for `README.md` structure.
