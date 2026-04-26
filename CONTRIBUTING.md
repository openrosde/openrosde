# Contributing to the SDE

Thank you for your interest in contributing to the Software Development Environment (SDE)!
This guide describes how to contribute to the project, with a focus on the most common contribution: **adding support for a new robot platform**.

[[_TOC_]]

## General Contribution Guidelines

- Follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) for all commit messages and merge request titles.
- Follow [Semantic Versioning](https://semver.org/) for releases.
- Follow [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) for `CHANGELOG.md` updates.
- Keep commits focused: one logical change per commit.
- Open a GitLab issue before starting non-trivial work so the maintainers can give early feedback.
- Submit changes via a merge request (MR) from a feature branch into `main`.
- Read [`AGENTS.md`](AGENTS.md) for coding conventions, code style rules, and architecture details: these apply to both human contributors and AI agents.

## GitLab Project Organization

The project is hosted at <https://gitlab.com/coarobo/SDE> and follows a single-trunk workflow centered on the `main` branch.

### Branches

- `main`: the default and only long-lived branch.
  All releases are tagged on `main`.
  Direct pushes are not allowed. All changes land via merge requests.
- Feature branches: short-lived, named with a kebab-case verb-first slug that mirrors the Conventional Commit type when practical.
  Examples: `add-myrobot-platform`, `fix-cobotta-gripper-pid`, `docs-update-readme`.
  Always branch from the latest `main` and rebase before merging.

### Merge Requests

- **Title**: Conventional Commits format `type(scope): subject`.
  Allowed types: `feat`, `fix`, `docs`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.
  Scope is a platform name only: `turtlebot3`, `ur5e`, `fetch`, `sciurus17`, `cobotta`, or `hsr`.
  Omit the scope entirely when the change is not specific to a single platform (cross-platform refactors, shared docs, CI, base Docker image, repository-wide changes).
  Subject is imperative, lowercase, no trailing period.
  Example: `feat(hsr): add HSR platform support`.
  Example without scope: `docs: adopt Keep a Changelog and document GitLab workflow`.
- **Description**: use the following structure. Cover each section when relevant. Omit sections that do not apply.
  1. **Summary**: one paragraph explaining what changes and why.
  2. **Changes**: bullet list of notable file or behavior changes.
  3. **Testing**: commands run and platforms verified.
  4. **Related**: `Closes #N`, `Refs #N`, or `None`.
  5. **Changelog**: which `CHANGELOG.md` subsection the change belongs to (`Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security`), and the one-line entry being added.
- Merge commits are preserved (no squash) so the per-commit history of the feature branch lands on `main`.
- After merging, delete the source branch.

### Issues

- Use plain descriptive titles, not Conventional Commit format.
  Issues describe a problem or request. Commits describe a change.
  Example: `Gripper does not respond on COBOTTA realworld bringup` (good), `fix(cobotta): gripper does not respond` (avoid).
- Categorize with labels rather than title prefixes.
  Recommended labels: `bug`, `feature`, `docs`, `chore`, `question`, plus a per-platform label (`platform::turtlebot3`, etc.).
- Link issues to the milestone of the release that will include the fix or feature.
- Close issues automatically by referencing them from the merging MR's `## Related` section with `Closes #N`. Use `Refs #N` to link without closing.

### Style for GitLab Text

These rules apply to all GitLab issue, milestone, and merge request titles and descriptions:

- Use backticks for code identifiers: file names, commands, environment variables, functions, ROS packages, paths. Do not use single quotes for code identifiers (single quotes are reserved for Bash and ROS launch-file comments inside the repository).
- Do not use semicolons (`;`), en dashes (`–`), or em dashes (`—`). Use a full stop or a new sentence instead of a semicolon. Use `: ` or a plain hyphen `-` instead of a dash.

### Milestones

- Name milestones after the target release version: `v2.8.0`, `v3.0.0`.
  This matches the convention expected by GitLab's changelog generator and by `release-please`-style automation.
- Close a milestone immediately after its release is published.

### Changelog

- The `CHANGELOG.md` file at the repository root follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
- Maintain an `## [Unreleased]` section at the top with subsections `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security` (omit empty subsections).
- Each MR should add a one-line entry to the appropriate subsection of `[Unreleased]` referencing its MR number, e.g. `- Add HSR platform support (!42).`.
- At release time, the `[Unreleased]` section is renamed to `[X.Y.Z] - YYYY-MM-DD` and a fresh `[Unreleased]` section is created.

### Releases

Releases are created on GitLab from annotated `vX.Y.Z` tags on `main`.
The release notes mirror the corresponding `CHANGELOG.md` section.

Release procedure (per release):

1. On a release branch (`release-vX.Y.Z`), update `CHANGELOG.md`: rename `[Unreleased]` to `[X.Y.Z] - YYYY-MM-DD` and add a new empty `[Unreleased]` section.
2. Open an MR titled `chore(release): vX.Y.Z`, get it reviewed, and merge to `main`.
3. Tag the merge commit:

   ```shell
   git checkout main && git pull
   git tag -a vX.Y.Z -m "Release vX.Y.Z"
   git push origin vX.Y.Z
   ```

4. Create the GitLab release with `glab`, sourcing the notes from the changelog section and linking the milestone:

   ```shell
   glab release create vX.Y.Z \
     --name "vX.Y.Z" \
     --milestone "vX.Y.Z" \
     --notes-file <(awk '/^## \[X.Y.Z\]/{p=1;next} p&&/^## \[/{exit} p' CHANGELOG.md)
   ```

5. Close the `vX.Y.Z` milestone on GitLab.

## Reporting Issues

Please report bugs or request features using the [GitLab issue tracker](https://gitlab.com/coarobo/SDE/issues).
Include the platform name, host OS, and the output of the failing command.

## Adding a New Robot Platform

> [!NOTE]
> If you only need to add your own ROS packages, system dependencies, environment variables, or Terminator panes, **do not add a new platform**.
> Use the [User Overlay](docs/user-overlay.md) (Layer 3) instead. It lives in [docker/user-devel/Dockerfile](docker/user-devel/Dockerfile), [ros/user_catkin_ws/](ros/user_catkin_ws/), and [docker/docker-compose-user.yaml](docker/docker-compose-user.yaml), and works on top of any selected `SDE_ROBOT_PLATFORM` without any of the steps below.

The SDE is designed to make adding a new platform straightforward.
All platform-specific behavior is controlled by the `SDE_ROBOT_PLATFORM` variable.
Adding a new platform named `<platform>` (e.g., `myrobot`) requires creating a small set of files and adding `<platform>` to a fixed list of platform-aware locations.

The steps below use `<platform>` as a placeholder.
Replace it with your actual platform name (lowercase kebab-case, e.g., `myrobot`).

### Step 1: Create the Environment Template

Create `env/<platform>.env` by copying the closest existing platform template:

```shell
cp env/cobotta.env env/<platform>.env
```

Edit the file to set:

```shell
SDE_ROBOT_PLATFORM=<platform>
```

Update the `SDE_ROBOT_HOSTNAME` comment and value to match your platform's connectivity (SSH hostname, or empty if USB/local).
Leave all defaults in this file: do not add `${VAR:-default}` fallback syntax in scripts.

### Step 2: Create the Docker Image

Create `docker/<platform>-devel/Dockerfile`:

```shell
mkdir docker/<platform>-devel
```

Use any existing platform Dockerfile as a template (e.g., `docker/cobotta-devel/Dockerfile`).
Follow the Dockerfile code style from [`AGENTS.md`](AGENTS.md#dockerfiles):

- Start from the `sde-base` image via `ARG SDE_BASE_IMAGE`.
- Install platform-specific ROS packages with `apt-get install`.
- Set `SDE_ROBOT_PLATFORM` via `ARG`/`ENV`.
- Pass `SDE_DOCKERFILE_COMMIT_SHORT_SHA` via `ARG`/`ENV SDE_DOCKER_IMAGE_VERSION`.

### Step 3: Create the Docker Compose Overlay

Create `docker/docker-compose-<platform>.yaml`.
If no extra environment variables are needed beyond what `docker-compose.yaml` already provides, use the minimal pattern from `docker/docker-compose-cobotta.yaml`.

### Step 4: Create the Catkin Workspace and Launch Package

Create the platform Catkin workspace and launch package skeleton:

```shell
mkdir -p ros/<platform>_catkin_ws/src/sde_<platform>_launch/launch
touch ros/<platform>_catkin_ws/src/sde_<platform>_launch/.gitignore
```

Create the following files following the conventions in [`AGENTS.md`](AGENTS.md#ros-packages):

- `ros/<platform>_catkin_ws/src/sde_<platform>_launch/package.xml`: use format 2, MIT license.
- `ros/<platform>_catkin_ws/src/sde_<platform>_launch/CMakeLists.txt`: minimal launch-only template.
- `ros/<platform>_catkin_ws/src/sde_<platform>_launch/README.md`: package README.

Create launch files following the naming convention `<component>_<variant>_<environment>.launch`:

- `<platform>_bringup_default_gazebo.launch`: simulation bringup (no MoveIt, no RViz).
- `<platform>_bringup_default_realworld.launch`: real robot bringup (no MoveIt, no RViz).
- `<platform>_moveit_default_gazebo.launch`: MoveIt for Gazebo.
- `<platform>_moveit_default_realworld.launch`: MoveIt for the real robot.
- `<platform>_rviz_default.launch`: RViz (environment-agnostic).

Each launch file must wrap the upstream official launch files as closely as possible.
See [`AGENTS.md`](AGENTS.md#ros-launch-files) for formatting conventions.

### Step 5: Add Git Submodules (if needed)

If the platform requires third-party ROS packages not available as Noetic Debian packages, add them as Git submodules:

```shell
git submodule add <upstream-url> ros/<platform>_catkin_ws/src/<package>
```

Then in `.gitmodules`, set `branch` and `ignore = dirty` for the new submodule.

If the upstream packages need source-level fixes (e.g., broken XML, missing PID configs), create patch files under `patches/ros/<platform>_catkin_ws/src/<package>/` following the naming convention `NNNN-verb-noun-noun.patch`.
See [`AGENTS.md`](AGENTS.md#submodule-patches) for the patch workflow.

### Step 6: Create the Terminator Layout

Create `terminator/<platform>.config` by copying the closest existing config:

```shell
cp terminator/cobotta.config terminator/<platform>.config
```

Update the layout name pattern to `sde-<platform>-term-11-<variant>-<environment>` and update the `roslaunch` commands in each terminal pane.

### Step 7: Create the Platform Documentation

Create `docs/robot-platforms/<platform>.md` following the structure of an existing platform doc (e.g., `docs/robot-platforms/cobotta.md`).
Required sections:

- External Resources
- Hardware Overview
- Platform Configuration
- Network Configuration
- Gazebo Simulation
- Real Robot Operation
- Launch Files Reference

### Step 8: Register the Platform in All Platform-Aware Files

Add `<platform>` to every location in the table below.
Search for an existing platform name (e.g., `cobotta`) to find the exact lines to update:

| File | What to add |
| --- | --- |
| `.env` | Add `<platform>` to the `# Platform to use:` comment |
| `env/turtlebot3.env`, `env/ur5e.env`, `env/fetch.env`, `env/sciurus17.env`, `env/cobotta.env`, `env/hsr.env` | Same comment update |
| `BUILD-DOCKER-IMAGE.bash` | Add `<platform>` to the `for SDE_PLATFORM in ...` loop |
| `gitlab-ci/PUSH-DOCKER-IMAGE.bash` | Add `<platform>` to the `for SDE_PLATFORM in ...` loop |
| `gitlab-ci/gitlab-ci.yml` | Add `<platform>` to the `SDE_ROBOT_PLATFORM:` matrix list |
| `docker/sde-base/scripts/initialize-bash-shell.bash` | Add `<platform>)` case setting `SDE_LAUNCH_PACKAGE=sde_<platform>_launch` |
| `BRINGUP-ROS-ROBOT.bash` | Add `<platform>)` case (SSH bringup command, or a "not applicable" message) |
| `RESTART-CHRONY-SERVICE.bash` | Add `<platform>)` case (Chrony restart command, or a "not applicable" message) |
| `README.md` | Update the platform table, Mermaid diagram, directory structure, and docs table |
| `AGENTS.md` | Update all platform lists, directory structure, submodule list, and patch list |

### Step 9: Test

```shell
# 1. Rebuild the Docker images:
bash ./BUILD-DOCKER-IMAGE.bash

# 2. Switch to the new platform:
bash ./SWITCH-ROBOT-PLATFORM.bash <platform>

# 3. Start the container:
bash ./RUN-DOCKER-CONTAINER.bash

# 4. Build the Catkin workspaces inside the container:
sde-reset-catkin-workspaces

# 5. Launch Gazebo simulation (in three terminals inside the container):
roslaunch sde_<platform>_launch <platform>_bringup_default_gazebo.launch
roslaunch sde_<platform>_launch <platform>_moveit_default_gazebo.launch
roslaunch sde_<platform>_launch <platform>_rviz_default.launch

# 6. Check for hardcoded paths:
grep -rn '/root/SDE' --include='*.bash' --include='*.yaml' --include='*.yml' --include='Dockerfile' .
```

### Step 10: Submit a Merge Request

1. Commit your changes on a branch named `add-<platform>-support`.
2. Push the branch and open a merge request targeting `main`.
3. The MR title should follow Conventional Commits: `feat(<platform>): add <Platform Name> platform support`.
4. The MR description should follow the structure documented in [Merge Requests](#merge-requests): Summary, Changes (list new and updated platform-aware files), Testing (commands run and platforms verified), Related, Changelog.
5. Add a `- Add <Platform Name> platform support (!N).` entry under `### Added` in the `## [Unreleased]` section of `CHANGELOG.md`.

## Code Style Quick Reference

See [`AGENTS.md`](AGENTS.md#code-style) for the full style guide.
