# Contributing to OpenRoSDE

Thank you for your interest in contributing to OpenRoSDE!
This guide describes how to contribute to the project, with a focus on the most common contribution: **adding support for a new robot platform**.

[[_TOC_]]

## General Contribution Guidelines

- Follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) for all commit messages and merge request titles.
- Follow [Semantic Versioning](https://semver.org/) for releases.
- Follow [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) for `CHANGELOG.md` updates.
- Keep commits focused: one logical change per commit.
- Open a GitLab issue before starting non-trivial work so the maintainers can give early feedback.
- Submit changes via a merge request (MR) from a feature branch into `dev`.
- Read [`AGENTS.md`](AGENTS.md) for coding conventions, code style rules, and architecture details: these apply to both human contributors and AI agents.

## GitLab Project Organization

The project is hosted at <https://gitlab.com/coarobo/SDE> and works on two long-lived branches: `dev` for the work in progress, and `main` for the releases.

### Branches

- `main`: the default branch, which holds the releases.
  All releases are tagged on `main`, and `dev` merges into it for each release.
- `dev`: the integration branch, which every change targets.
  The CI publishes its images as `dev`, and the robots of the maintainers run their demonstrations from it.
- Both are protected: direct pushes are not allowed, and all changes land via merge requests.
- Feature branches: short-lived, named `<type>/<slug>` after the Conventional Commit type, with a kebab-case slug.
  Examples: `feat/add-myrobot-platform`, `fix/cobotta-gripper-pid`, `docs/update-readme`.
  Always branch from the latest `dev`.
  A change that builds on another one still in review branches from it, and its merge request targets that branch until it is merged.

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
- Merge commits are preserved (no squash) so the per-commit history of the feature branch lands on `dev`.
- After merging, delete the source branch.

### Issues

- Use plain descriptive titles, not Conventional Commit format.
  Issues describe a problem or request. Commits describe a change.
  Example: `Gripper does not respond on COBOTTA realworld bringup` (good), `fix(cobotta): gripper does not respond` (avoid).
- Categorize with the labels of the `coarobo` group rather than title prefixes: `default:bug`, `default:enhancement`, `default:documentation`, `default:discussion`, `default:critical`, `default:suggestion`, `default:support`, `default:confirmed`, `custom:hardware`, and `custom:administration`.
- Link issues to the milestone of the release that will include the fix or feature.
- Close issues automatically by referencing them from the merging MR's `## Related` section with `Closes #N`. Use `Refs #N` to link without closing.

### Style for GitLab Text

These rules apply to all GitLab issue, milestone, and merge request titles and descriptions:

- Use backticks for code identifiers: file names, commands, environment variables, functions, ROS packages, paths. Do not use single quotes for code identifiers (single quotes are reserved for Bash and ROS launch-file comments inside the repository).
- Do not use semicolons (`;`), en dashes (`–`), or em dashes (`—`). Use a full stop or a new sentence instead of a semicolon. Use `: ` or a plain hyphen `-` instead of a dash.

### Milestones

- Name milestones as long-lived thematic epics with a verb-first descriptive title (e.g., `Port OpenRoSDE to ROS 2 on Ubuntu 26.04 LTS`), not after individual release versions.
- A release belongs to the epic milestone that contains its work. Link the release and its merge requests to that epic.
- Keep epic milestones open until the epic itself is complete. Do not close an epic when one of its releases is published.

### Changelog

- The `CHANGELOG.md` file at the repository root follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
- Maintain an `## [Unreleased]` section at the top with subsections `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security` (omit empty subsections).
- Each MR should add a one-line entry to the appropriate subsection of `[Unreleased]` referencing its MR number, e.g. `- Add HSR platform support (!42).`.
- At release time, the `[Unreleased]` section is renamed to `[X.Y.Z] - YYYY-MM-DD` and a fresh `[Unreleased]` section is created.

### Releases

Releases are created on GitLab from annotated `vX.Y.Z` tags on `main`.
The release notes mirror the corresponding `CHANGELOG.md` section.

Release procedure (per release):

1. On a release branch (`release/vX.Y.Z`) from `dev`, update `CHANGELOG.md`: rename `[Unreleased]` to `[X.Y.Z] - YYYY-MM-DD` and add a new empty `[Unreleased]` section, then merge it into `dev`.
2. Open an MR from `dev` to `main` titled `chore(release): vX.Y.Z`, get it reviewed, and merge it, which makes the CI publish the images as `main`.
3. Tag the merge commit:

   ```shell
   git checkout main && git pull
   git tag -a vX.Y.Z -m "Release vX.Y.Z"
   git push origin vX.Y.Z
   ```

4. Create the GitLab release with `glab`, sourcing the notes from the changelog section and linking the epic milestone:

   ```shell
   glab release create vX.Y.Z \
     --name "vX.Y.Z" \
     --milestone "<epic milestone title>" \
     --notes-file <(awk '/^## \[X.Y.Z\]/{p=1;next} p&&/^## \[/{exit} p' CHANGELOG.md)
   ```

5. `glab release create --milestone` closes the linked milestone. Because epics span many releases, reopen it right after so it stays active:

   ```shell
   glab api -X PUT "projects/:id/milestones/:milestone_id" -f "state_event=activate"
   ```

## Reporting Issues

Please report bugs or request features using the [GitLab issue tracker](https://gitlab.com/coarobo/SDE/issues).
Include the platform name, host OS, and the output of the failing command.

## Adding a New Robot Platform

> [!NOTE]
> If you only need to add your own ROS packages, system dependencies, environment variables, or Terminator panes, **do not add a new platform**.
> Use the [User Overlay](docs/user-overlay.md) (Layer 3) instead. It lives in [docker/user-devel/Dockerfile](docker/user-devel/Dockerfile), [ros/user_catkin_ws/](ros/user_catkin_ws/), and [docker/docker-compose-user.yaml](docker/docker-compose-user.yaml), and works on top of any selected `OPENROSDE_ROBOT_PLATFORM` without any of the steps below.

OpenRoSDE is designed to make adding a new platform straightforward.
A platform can live in the core or in an extension repository of its own, cloned into `extensions/`, with the same files in the same places (see [docs/extensions.md](docs/extensions.md)).
An extension platform needs no change of the core at all, so it suits a robot that is private, or that the maintainers do not merge upstream.
All platform-specific behavior is controlled by the `OPENROSDE_ROBOT_PLATFORM` variable.
Adding a new platform named `<platform>` (e.g., `myrobot`) requires creating a small set of files, which OpenRoSDE finds by that name, and adding `<platform>` to the few lists that remain.

The steps below use `<platform>` as a placeholder.
Replace it with your actual platform name (lowercase kebab-case, e.g., `myrobot`).

### Step 1: Create the Environment Template

Create `env/<platform>.env` by copying the closest existing platform template:

```shell
cp env/cobotta.env env/<platform>.env
```

Edit the file to set:

```shell
OPENROSDE_ROBOT_PLATFORM=<platform>
OPENROSDE_ROBOT_SETUP=<platform>
```

The template of a platform is its default setup, so it declares its own name as the setup too.
The first line is how OpenRoSDE finds the platform: `scripts/list-robot-platforms.bash` lists every `env/<platform>.env` that declares its own name, and `SWITCH-ROBOT-PLATFORM.bash` and the CI pipeline use that list.

Update the `OPENROSDE_ROBOT_HOSTNAME` comment and value to match your platform's connectivity (SSH hostname, or empty if USB/local).
Leave all defaults in this file: do not add `${VAR:-default}` fallback syntax in scripts.

### Step 2: Create the Docker Image

Create `docker/<platform>-devel/Dockerfile`:

```shell
mkdir docker/<platform>-devel
```

Use any existing platform Dockerfile as a template (e.g., `docker/cobotta-devel/Dockerfile`).
Follow the Dockerfile code style from [`AGENTS.md`](AGENTS.md#dockerfiles):

- Start from the `openrosde-base` image via `ARG OPENROSDE_BASE_IMAGE`.
- Install platform-specific ROS packages with `apt-get install`.
- Set `OPENROSDE_ROBOT_PLATFORM` via `ARG`/`ENV`.
- Pass `OPENROSDE_DOCKERFILE_COMMIT_SHORT_SHA` via `ARG`/`ENV OPENROSDE_DOCKER_IMAGE_VERSION`.

### Step 3: Create the Docker Compose Overlay

Create `docker/docker-compose-<platform>.yaml`.
If no extra environment variables are needed beyond what `docker-compose.yaml` already provides, use the minimal pattern from `docker/docker-compose-cobotta.yaml`.

### Step 4: Create the Catkin Workspace and Launch Package

Create the platform Catkin workspace and launch package skeleton:

```shell
mkdir -p ros/<platform>_catkin_ws/src/openrosde_<platform>_launch/launch
touch ros/<platform>_catkin_ws/src/openrosde_<platform>_launch/.gitignore
```

Create the following files following the conventions in [`AGENTS.md`](AGENTS.md#ros-packages):

- `ros/<platform>_catkin_ws/src/openrosde_<platform>_launch/package.xml`: use format 2, MIT license.
- `ros/<platform>_catkin_ws/src/openrosde_<platform>_launch/CMakeLists.txt`: minimal launch-only template.
- `ros/<platform>_catkin_ws/src/openrosde_<platform>_launch/README.md`: package README.

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

### Step 6: Create the Tmux Panes and the Terminator Layout

Create `tmux/<platform>.panes` with the panes of the platform in its `tmux` session, one per line, following `tmux/ur5e.panes`:

```shell
default-gazebo     robot  <platform>_bringup_default_gazebo.launch
default-gazebo     robot  <platform>_rviz_default.launch
default-realworld  robot  <platform>_bringup_default_realworld.launch
```

The core adds its own windows (`tools`, `user`, `host`) from `tmux/openrosde.panes`.
Until `tmux` replaces Terminator, also create the matching Terminator layout, `terminator/<platform>.config`, by copying the closest existing config:

```shell
cp terminator/cobotta.config terminator/<platform>.config
```

Update the layout name pattern to `openrosde-<platform>-term-11-<variant>-<environment>` and update the `roslaunch` commands in each terminal pane.
For a platform of the core, `tests/suites/test-terminator-parity.bash` checks that each layout runs the same launch files and arguments as the panes of that layout.

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

### Step 8: Add the Platform Scripts (if needed)

The core scripts run the optional scripts of a platform from `scripts/<platform>/`, named after the core script that runs them, and print that nothing is configured when a script is missing:

| Script | Run by | Purpose |
| --- | --- | --- |
| `scripts/<platform>/initialize-bash-shell.bash` | `docker/openrosde-base/scripts/initialize-bash-shell.bash`, inside the container | Shell configuration of the platform, such as `TURTLEBOT3_MODEL` in `scripts/turtlebot3/` |
| `scripts/<platform>/bringup-ros-robot.bash` | `BRINGUP-ROS-ROBOT.bash`, with the ROS master host name | Bringup of the real robot by SSH |
| `scripts/<platform>/restart-chrony-service.bash` | `RESTART-CHRONY-SERVICE.bash` | Chrony restart on the robot computer |

Each script runs with every `OPENROSDE_*` variable that `scripts/load-openrosde-env.bash` exports.
The launch package of the platform is always `openrosde_<platform>_launch`, so it needs no registration.

### Step 9: Add the Platform to the Documentation

The scripts and the CI pipeline find the platform by name, so only the documentation lists it by hand.
Add `<platform>` to every location in the table below.
Search for an existing platform name (e.g., `cobotta`) to find the exact lines to update:

| File | What to add |
| --- | --- |
| `README.md` | Update the platform table, Mermaid diagram, directory structure, and docs table |
| `AGENTS.md` | Update all platform lists, directory structure, submodule list, and patch list |

### Step 10: Test

```shell
# 1. Rebuild the Docker images:
bash ./BUILD-DOCKER-IMAGE.bash

# 2. Switch to the new platform:
bash ./SWITCH-ROBOT-PLATFORM.bash <platform>

# 3. Start the container:
bash ./RUN-DOCKER-CONTAINER.bash

# 4. Build the Catkin workspaces inside the container:
openrosde-reset-catkin-workspaces

# 5. Launch Gazebo simulation (in three terminals inside the container):
roslaunch openrosde_<platform>_launch <platform>_bringup_default_gazebo.launch
roslaunch openrosde_<platform>_launch <platform>_moveit_default_gazebo.launch
roslaunch openrosde_<platform>_launch <platform>_rviz_default.launch

# 6. Check for hardcoded paths:
grep -rn '/root/OpenRoSDE' --include='*.bash' --include='*.yaml' --include='*.yml' --include='Dockerfile' .

# 7. Run the test suites on the host, which also check that the 'tmux' panes match the Terminator layouts:
bash ./tests/run.bash
```

### Step 11: Submit a Merge Request

1. Commit your changes on a branch named `feat/add-<platform>-support`, from the latest `dev`.
2. Push the branch and open a merge request targeting `dev`.
3. The MR title should follow Conventional Commits: `feat(<platform>): add <Platform Name> platform support`.
4. The MR description should follow the structure documented in [Merge Requests](#merge-requests): Summary, Changes (list new and updated platform-aware files), Testing (commands run and platforms verified), Related, Changelog.
5. Add a `- Add <Platform Name> platform support (!N).` entry under `### Added` in the `## [Unreleased]` section of `CHANGELOG.md`.

## Code Style Quick Reference

See [`AGENTS.md`](AGENTS.md#code-style) for the full style guide.
