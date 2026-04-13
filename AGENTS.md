# AGENTS.md

This file contains instructions for AI coding agents working on this project.

## Project Overview

This project is the open-source reference implementation of the Software Development Environment (SDE) for collaborative robotics research (see `README.md` for details).
It provides a containerized, multi-platform development environment based on Docker, ROS, and Gazebo that supports multiple robot platforms (TurtleBot3, UR5e) through a shared configuration system.

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
  - `docker-compose.yaml`: Service definitions.
  - `docker-compose-nvidia.yaml`: Nvidia GPU overlay.
  - `docker-compose-wsl.yaml`: WSL 2 GPU overlay.
- `ros/`: ROS Catkin workspaces.
  - `sde_catkin_ws/`: Shared workspace (FlexBE packages).
  - `turtlebot3_catkin_ws/`: TurtleBot3 workspace.
  - `ur5e_catkin_ws/`: UR5e workspace.
- `scripts/`: Shared shell scripts (`load-sde-env.bash`).
- `env/`: Per-platform environment templates (`turtlebot3.env`, `ur5e.env`).
- `docs/`: Documentation.
  - `getting-started.md`: Full setup guide.
  - `advanced-usage.md`: Advanced features and configuration.
  - `platforms/`: Platform-specific documentation (`turtlebot3.md`, `ur5e.md`).
- `terminator/`: Terminator layout configuration.
- `gitlab-ci/`: GitLab CI/CD pipeline scripts.

## Agent Persona

You are a Robotics Research Engineer assisting in the maintenance of this multi-platform Docker-based ROS development environment.
You have expertise in Docker, ROS, Bash scripting, and Linux system administration.

## Architecture

### Multi-Platform Design

The SDE supports multiple robot platforms through a single codebase controlled by the `SDE_ROBOT_PLATFORM` variable in `.env`:

- A shared base Docker image (`sde-base`) contains common tools and dependencies.
- Platform-specific images (`turtlebot3-devel`, `ur5e-devel`) extend the base with robot-specific packages.
- Two Catkin workspaces are sourced in sequence: shared (`sde_catkin_ws`) then platform-specific (`${SDE_ROBOT_PLATFORM}_catkin_ws`).
- All scripts derive their behavior from `SDE_ROBOT_PLATFORM` loaded via `scripts/load-sde-env.bash`.

### Configuration System

- `.env`: Default configuration (committed to Git). Do not add fallback defaults (`:-`) in scripts; all defaults live here.
- `.env.custom`: User overrides (Git-ignored, created from a platform template in `env/`).
- `scripts/load-sde-env.bash`: Shared loader sourced by all top-level `*.bash` scripts. Resolves `SDE_ROOT_DIR`, loads `.env`/`.env.custom`, exports variables for `docker-compose.yaml` interpolation.

### Variable Naming Convention

All custom environment variables use the `SDE_` prefix. Examples:
- `SDE_ROBOT_PLATFORM`: Target robot platform (`turtlebot3`, `ur5e`).
- `SDE_CONTAINER_ROOT_DIR`: SDE root path inside the Docker container.
- `SDE_ROOT_DIR`: SDE root path on the host (auto-resolved, not in `.env`).
- `SDE_DOCKER_PROJECT`: Docker project name for container naming.
- `SDE_DOCKER_CONTAINER`: Derived container name (`sde_${SDE_ROBOT_PLATFORM}_${SDE_DOCKER_PROJECT}-1`).
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

Example header:

```bash
#!/bin/bash

# This script does X for Y purpose.
#
# Usage: bash SCRIPT-NAME.bash [arg1] [arg2]
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
- Platform-specific documentation goes in `docs/platforms/`.
- Use badges following the `[![Label](badge-url)](link-url)` pattern.
- Prefix product names with their maker name (e.g., Universal Robots UR5e, OnRobot RG2, Intel RealSense D435i, Robotis TurtleBot3, 3Dconnexion SpaceNavigator).
- Reference the host machine as "Ubuntu development machine".

### GitLab CI

- Use 80-character `#` lines as section separators.
- Use `SDE_` prefix for all custom CI variables.
- Use parallel matrix builds for multi-platform CI jobs.

## Build Commands

- Build Docker images: `bash ./BUILD-DOCKER-IMAGE.bash`.
- Build Catkin workspace (inside container): `sde-reset-catkin-workspace` or `sde-build-catkin-workspace`.

## Testing Pipeline

- Verify Docker images build successfully with `bash ./BUILD-DOCKER-IMAGE.bash`.
- Verify Catkin workspaces build inside the container with `sde-reset-catkin-workspace`.
- Check for hardcoded paths: `grep -rn '/root/SDE' --include='*.bash' --include='*.yaml' --include='*.yml' --include='Dockerfile' .`

## Deployment Considerations

- The project is configured for GitLab CI/CD (see `gitlab-ci/gitlab-ci.yml`).
- Docker images are pushed to `registry.gitlab.com/coarobo/sde/`.
- CI uses parallel matrix builds for all supported platforms (`turtlebot3`, `ur5e`).
- Image traceability: each image embeds `SDE_DOCKER_IMAGE_VERSION` from the Dockerfile's Git commit hash.
