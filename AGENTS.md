# AGENTS.md

This file contains instructions for AI coding agents working on this project.

## Project Overview

This project is the open-source reference implementation of the Software Development Environment (SDE) for collaborative robotics research (see `README.md` for details).
It provides a containerized, multi-platform development environment based on Docker, ROS, and Gazebo that supports multiple robot platforms (TurtleBot3, UR5e, Fetch, Sciurus17, COBOTTA) through a shared configuration system.

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
  - `cobotta-devel/`: COBOTTA platform image.
  - `docker-compose.yaml`: Base service definitions.
  - `docker-compose-nvidia.yaml`: Nvidia GPU overlay.
  - `docker-compose-wsl.yaml`: WSL 2 GPU overlay.
  - `docker-compose-turtlebot3.yaml`: TurtleBot3 platform overlay.
  - `docker-compose-ur5e.yaml`: UR5e platform overlay.
  - `docker-compose-fetch.yaml`: Fetch platform overlay.
  - `docker-compose-sciurus17.yaml`: Sciurus17 platform overlay.
  - `docker-compose-cobotta.yaml`: COBOTTA platform overlay.
- `ros/`: ROS Catkin workspaces.
  - `sde_catkin_ws/`: Shared workspace (FlexBE packages).
  - `turtlebot3_catkin_ws/`: TurtleBot3 workspace (`sde_turtlebot3_launch/`, `sde_turtlebot3_behaviors/`).
  - `ur5e_catkin_ws/`: UR5e workspace (`sde_ur5e_launch/`, `sde_ur5e_teleop/`, `sde_ur5e_behaviors/`).
  - `fetch_catkin_ws/`: Fetch workspace (`sde_fetch_launch/`, `sde_fetch_behaviors/`).
  - `sciurus17_catkin_ws/`: Sciurus17 workspace (`sde_sciurus17_launch/`, `sde_sciurus17_behaviors/`).
  - `cobotta_catkin_ws/`: COBOTTA workspace (`sde_cobotta_launch/`, `sde_cobotta_behaviors/`).
- `scripts/`: Shared shell scripts (`load-sde-env.bash`).
- `env/`: Per-platform environment templates (`turtlebot3.env`, `ur5e.env`, `fetch.env`, `sciurus17.env`, `cobotta.env`).
- `docs/`: Documentation.
  - `basic-usage.md`: Full setup guide.
  - `advanced-usage.md`: Advanced features and configuration.
  - `robot-platforms/`: Platform-specific documentation (`turtlebot3.md`, `ur5e.md`, `fetch.md`, `sciurus17.md`, `cobotta.md`).
- `terminator/`: Per-platform Terminator layout configuration (`turtlebot3.config`, `ur5e.config`, `fetch.config`, `sciurus17.config`, `cobotta.config`).
- `gitlab-ci/`: GitLab CI/CD pipeline scripts.

## Agent Persona

You are a Robotics Research Engineer assisting in the maintenance of this multi-platform Docker-based ROS development environment.
You have expertise in Docker, ROS, Bash scripting, and Linux system administration.

## Architecture

### Multi-Platform Design

The SDE supports multiple robot platforms through a single codebase controlled by the `SDE_ROBOT_PLATFORM` variable in `.env`:

- A shared base Docker image (`sde-base`) contains common tools and dependencies.
- Platform-specific images (`turtlebot3-devel`, `ur5e-devel`, `fetch-devel`, `sciurus17-devel`, `cobotta-devel`) extend the base with robot-specific packages.
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

All platform configs share an identical 15-terminal tree structure.
The bottom-left 4 terminals are standardized across all platforms and both environments:
- `terminal6` (Number: 4): bringup launch (or empty if no realworld bringup exists, e.g., TurtleBot3 realworld and Sciurus17 realworld).
- `terminal7` (Number: 5): RViz launch.
- `terminal9` (Number: 6): MoveIt (or navigation, depending on platform).
- `terminal10` (Number: 7): FlexBE app (`sde_launch:flexbe_app_default.launch`), on all platforms and in both gazebo and realworld layouts.
The top-right pair (`terminal13` / `terminal14`, Numbers: 2 / 3) is used for platform-specific secondary launches (e.g., gripper control, teleop, mapping).
Spare terminals (`terminal18`–`terminal29`, Numbers: 8–15) are available for additional launches (e.g., `realsense_camera_default_realworld.launch` at Number: 8 in the UR5e realworld layout).
Number: 14 (`terminal28`) is standardized across all platforms and both environments for `sde_launch:rqt_suite_default.launch`.
Number: 15 (`terminal29`) is standardized across all platforms and both environments for `sde_launch:rosbridge_server_default.launch`.

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
- Write one sentence per line in comments.
- Use single quotes `' '` around code-related references in comments (e.g., `# Load the default environment variables from the '.env' file:`).
- Use `${VARIABLE}` syntax (with curly braces) for all variable references.
- Prefix all custom variables with `SDE_` (e.g., `SDE_ROBOT_PLATFORM`, not `PLATFORM`).
- Use at least 3 words for variable names (including `SDE_`), e.g., `SDE_ROBOT_PLATFORM`, not `SDE_PLATFORM`.
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
- Use single quotes `' '` around code-related names in `<!-- -->` comments (e.g., `<!-- Start 'robot_state_publisher'. -->`, `<!-- Load 'kinematics.yaml'. -->`). This mirrors the Bash comment convention.
- Add a source comment block at the top of every launch file, immediately after `<launch>`, using this pattern:
  - `<!-- https://github.com/<upstream-repo> -->` — URL of the upstream repository this file is based on or extends.
  - `<!-- Upstream default: $(find <pkg>)/launch/<file>.launch -->` — path to the upstream launch file used as the starting point, when one exists.
  - `<!-- SDE-specific: <one-line description> -->` — instead of the upstream line, when the file has no direct upstream counterpart.

RViz launch files use an SDE-owned `.rviz` config file stored in `config/rviz/` within the `sde_<platform>_launch` package.
These config files are copied from the upstream default and modified to set `Fullscreen: false` under `Window Geometry:`.
All RViz launch nodes use `required="true"` so the layout closes when RViz exits.
Each RViz launch file also includes a `<node name="maximize_rviz" pkg="sde_launch" type="maximize-app-window.bash" args="RViz" />` node that maximizes the window via `wmctrl` after it opens.
The corresponding bringup Gazebo launch files include the same pattern with `name="maximize_gazebo"` and `args="Gazebo"` to maximize the Gazebo window.
The `flexbe_app_default.launch` file includes the same pattern with `name="maximize_flexbe"` and `args="FlexBE"` to maximize the FlexBE App window (the `"FlexBE"` substring matches the `"FlexBE App"` window title; using a single word avoids roslaunch splitting the arg on the space).
The `maximize-app-window.bash` script lives in `ros/sde_catkin_ws/src/sde_launch/scripts/` and is installed via `sde_launch`'s `CMakeLists.txt`.
The script retries for up to 60 seconds to handle slow application startup (e.g. the FlexBE App nwjs window), then restores focus to Terminator using `wmctrl -xa terminator` (matches by WM_CLASS, reliable regardless of tab title).
`wmctrl` must be installed in the container (it is included in the `sde-base` Dockerfile).

### ROS Packages

ROS packages (e.g., `sde_ur5e_teleop` in `ur5e_catkin_ws`) extend the standard launch-only pattern with Python nodes and config files.
They follow the same `package.xml` and `README.md` conventions above, and additionally:

- `CMakeLists.txt`: Includes `catkin_install_python` for Python node scripts.

When a `sde_<platform>_launch` package itself needs Python helper nodes (e.g., a gripper joint-state publisher), it follows the same `sde_<platform>_teleop` extension pattern:

- `scripts/`: Python node scripts (e.g., `publish-gripper-joint-states.py`).
- `CMakeLists.txt`: Includes `catkin_install_python` for the scripts.
- `package.xml`: Adds `rospy` and any message-package exec depends (e.g., `sensor_msgs`, `onrobot_rg_control`).
- The `urdf/` folder holds SDE-owned xacro files that extend or replace the upstream robot URDF.
- The `description/` folder holds third-party description fragments (meshes, xacros) vendored into the package.
- A `<component>_description_default_<environment>.launch` adapter file is used when the upstream driver's `robot_description_file` arg requires a launch file that accepts a `kinematics_params` arg.

### FlexBE Behaviors Packages

Each platform has a `sde_<platform>_behaviors/` directory in its Catkin workspace containing two ROS packages, plus a shared `README.md` and `.gitignore`:

- `sde_<platform>_flexbe_behaviors/`: Contains FlexBE behavior state machines.
  - `src/sde_<platform>_flexbe_behaviors/`: Python modules, one `<behavior_name>_sm.py` per behavior.
  - `manifest/<behavior_name>.xml`: FlexBE behavior manifest (loaded by the FlexBE app).
    The `<description>` element must be a single line with no embedded newlines; multi-line descriptions render as literal whitespace in the FlexBE app.
  - `config/<behavior_name>.yaml`: Behavior parameters (placeholder; values are set in the manifest).
  - `setup.py`, `CMakeLists.txt`, `package.xml`: Standard catkin Python package boilerplate.
  - `package.xml` uses `format="2"`, exports `<flexbe_behaviors />`, and lists `flexbe_core`, `flexbe_states`, and any generic state packages (`flexbe_navigation_states`, `flexbe_manipulation_states`) as `exec_depend`.
    `format="2"` requires `<exec_depend>` tags; using `<run_depend>` causes a `catkin_pkg.package.InvalidPackage` error at build time.
- `sde_<platform>_flexbe_states/`: Reserved for platform-specific custom FlexBE states (empty by default; only add states here that cannot be satisfied by `flexbe_behavior_engine` or `flexbe_generic_states`).
  - `src/sde_<platform>_flexbe_states/`: Python modules.
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
- Mobile robot platforms (TurtleBot3, Fetch): looping navigation between two waypoints using `MoveBaseState` and `WaitState`.
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
- Do not use em dashes (`—`). Use `: ` as the separator in list items (e.g., `- \`file.txt\`: description`) and rephrase mid-sentence asides as separate clauses or parenthetical notes.
- Do not use thematic breaks (`---`). Use blank lines and heading levels to separate sections instead.
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
- Shared (`sde_catkin_ws`): `flexbe_behavior_engine`, `flexbe_app`, `flexbe_generic_states`.
- UR5e (`ur5e_catkin_ws`): `onrobot`, `roboticsgroup_upatras_gazebo_plugins`.
- Fetch (`fetch_catkin_ws`): `fetch_gazebo` (branch `gazebo11`, provides `fetch_gazebo` and `fetch_gazebo_demo`).
- Sciurus17 (`sciurus17_catkin_ws`): `sciurus17_ros` (branch `master`, ROS 1), `sciurus17_description` (branch `main`, dependency package used by ROS 1 setup).
- COBOTTA (`cobotta_catkin_ws`): `denso_cobotta_ros` (branch `melodic-devel`, the most up-to-date branch, 2 commits ahead of `master`, latest release v1.2.4).

Current patches:
- `patches/ros/sde_catkin_ws/src/flexbe_app/0001-fix-curl-redirect.patch`: Fixes a broken curl redirect in the FlexBE app.
- `patches/ros/sde_catkin_ws/src/flexbe_app/0002-set-window-maximized.patch`: Sets `"initial_state": "maximized"` in the nwjs `package.json` so the FlexBE App window opens maximized.
- `patches/ros/cobotta_catkin_ws/src/denso_cobotta_ros/0001-fix-comments-collada.patch`: Expands self-closing `<comments/>` to `<comments></comments>` in 6 Collada mesh files (`base_link.dae`, `J1.dae`–`J3.dae`, `J5.dae`, `J6.dae`) to fix an RViz/Assimp parse error ("Expected end of `<comments>` element").
- `patches/ros/cobotta_catkin_ws/src/denso_cobotta_ros/0002-fix-gripper-pid-gain.patch`: Uncomments the `joint_gripper` PID gain entry in `gazebo_cobotta_control.yaml` to eliminate a `gazebo_ros_control` error when spawning the robot with `gripper_type:=parallel` in Gazebo.
- `patches/ros/cobotta_catkin_ws/src/denso_cobotta_ros/0003-fix-blender-mesh-materials.patch`: Sets `ambient` to `0.5 0.5 0.5 1` and `emission` to `0.04 0.04 0.04 1` in 6 Blender-exported Collada mesh files (`J4.dae`, `gripper_base.dae`, `left_finger.dae`, `right_finger.dae`, `pad.dae`, `vacuum.dae`) to fix black rendering under OGRE/Mesa caused by explicit `ambient: 0 0 0 1`.
- `patches/ros/cobotta_catkin_ws/src/denso_cobotta_ros/0004-add-srdf-named-states.patch`: Adds `home` (j3=π/2, all others=0) and `up` (j2=−π/4, j3=π/2, j5=π/4) named group states to `cobotta.srdf.xacro` for the `arm` group, enabling `SrdfStateToMoveit` FlexBE states to drive the arm to pre-defined configurations.

## Adding a New Platform

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for the full step-by-step guide.
When adding a platform named `<platform>`, create these files:

- `env/<platform>.env`: environment template.
- `docker/<platform>-devel/Dockerfile`: platform Docker image.
- `docker/docker-compose-<platform>.yaml`: Docker Compose overlay.
- `ros/<platform>_catkin_ws/src/sde_<platform>_launch/`: ROS launch package (5 launch files, `package.xml`, `CMakeLists.txt`, `README.md`, `.gitignore`).
- `ros/<platform>_catkin_ws/src/sde_<platform>_behaviors/`: FlexBE behaviors package (two sub-packages: `sde_<platform>_flexbe_behaviors/` and `sde_<platform>_flexbe_states/`, plus `README.md` and `.gitignore`).
- `terminator/<platform>.config`: Terminator layouts.
- `docs/robot-platforms/<platform>.md`: platform documentation.

And update `<platform>` in every platform-aware file:

- `.env` and all `env/*.env`: platform list comment.
- `BUILD-DOCKER-IMAGE.bash`: platform loop.
- `gitlab-ci/PUSH-DOCKER-IMAGE.bash`: platform loop.
- `gitlab-ci/gitlab-ci.yml`: CI matrix.
- `docker/sde-base/scripts/initialize-bash-shell.bash`: `<platform>)` case for `SDE_LAUNCH_PACKAGE`.
- `BRINGUP-ROS-ROBOT.bash`: `<platform>)` case.
- `RESTART-CHRONY-SERVICE.bash`: `<platform>)` case.
- `README.md`: platform table, Mermaid diagram, directory structure, docs table.
- `AGENTS.md`: platform lists, directory structure, submodule list, patch list.

## Build Commands

- Build Docker images: `bash ./BUILD-DOCKER-IMAGE.bash`.
  - Default behavior: pulls from registry or builds current platform with cache.
  - `bash ./BUILD-DOCKER-IMAGE.bash local`: builds current platform with cache (fast iteration).
  - `bash ./BUILD-DOCKER-IMAGE.bash gitlab-ci`: builds all platforms from scratch without cache (CI/CD).
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
- CI uses parallel matrix builds for all supported platforms (`turtlebot3`, `ur5e`, `fetch`, `sciurus17`, `cobotta`).
- Image traceability: each image embeds `SDE_DOCKER_IMAGE_VERSION` from the Dockerfile's Git commit hash.

## Versioning & Commits

- Use [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) for all commit messages.
- Follow [Semantic Versioning](https://semver.org/) for releases.
- Follow the [Make a README](https://www.makeareadme.com/) guidelines for `README.md` structure.
