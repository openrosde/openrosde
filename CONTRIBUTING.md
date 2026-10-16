# Contributing to OpenRoSDE

Thank you for your interest in contributing to OpenRoSDE!
This guide describes how to contribute to the project, with a focus on the most common contribution: **adding support for a new robot platform**.

## General Contribution Guidelines

- Follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) for all commit messages and pull request titles.
- Follow [Semantic Versioning](https://semver.org/) for releases.
- Follow [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) for `CHANGELOG.md` updates.
- Keep commits focused: one logical change per commit.
- Open a GitHub issue before starting non-trivial work so the maintainers can give early feedback.
- Submit changes via a pull request (PR) from a feature branch into `dev`.
- Read [`AGENTS.md`](AGENTS.md) for coding conventions, code style rules, and architecture details: these apply to both human contributors and AI agents.

## GitHub Project Organization

The project is hosted at <https://github.com/openrosde/openrosde> and works on two long-lived branches: `dev` for the work in progress, and `main` for the releases.

### Branches

- `main`: the default branch, which holds the releases.
  All releases are tagged on `main`, and `dev` merges into it for each release.
- `dev`: the integration branch, which every change targets.
  The CI publishes its images as `dev`, and the robots of the maintainers run their demonstrations from it.
- Both are protected: direct pushes are not allowed, and all changes land via pull requests.
- Feature branches: short-lived, named `<type>/<slug>` after the Conventional Commit type, with a kebab-case slug.
  Examples: `feat/extension-parts`, `fix/registry-anonymous-pull`, `docs/update-readme`.
  Always branch from the latest `dev`.
  A change that builds on another one still in review branches from it, and its pull request targets that branch until it is merged.

### Pull Requests

- **Title**: Conventional Commits format `type(scope): subject`.
  Allowed types: `feat`, `fix`, `docs`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.
  Omit the scope, since this repository holds no platform, and every platform takes its changes in its own repository, apart from `chore(release): vX.Y.Z` of a release.
  Subject is imperative, lowercase, no trailing period.
  Example: `docs: adopt Keep a Changelog and document the GitHub workflow`.
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
  Example: `Gripper does not respond on UR5e realworld bringup` (good), `fix(ur5e): gripper does not respond` (avoid).
  Report an issue of a platform in its own repository, such as https://github.com/openrosde/openrosde-platform-fetch/issues for the Fetch.
- Categorize with the labels of the repository rather than title prefixes, such as `bug`, `enhancement`, `documentation`, `question`, and `good first issue`.
- Link issues to the milestone of the release that will include the fix or feature.
- Close issues automatically by referencing them from the `## Related` section of the merging PR with `Closes #N`. Use `Refs #N` to link without closing.

### Style for GitHub Text

These rules apply to all GitHub issue, milestone, and pull request titles and descriptions:

- Use backticks for code identifiers: file names, commands, environment variables, functions, ROS packages, paths. Do not use single quotes for code identifiers (single quotes are reserved for Bash and ROS launch-file comments inside the repository).
- Do not use semicolons (`;`), en dashes (`–`), or em dashes (`—`). Use a full stop or a new sentence instead of a semicolon. Use `: ` or a plain hyphen `-` instead of a dash.

### Milestones

- Name milestones as long-lived thematic epics with a verb-first descriptive title (e.g., `Port OpenRoSDE to ROS 2 on Ubuntu 26.04 LTS`), not after individual release versions.
- A release belongs to the epic milestone that contains its work. Link the release and its pull requests to that epic.
- Keep epic milestones open until the epic itself is complete. Do not close an epic when one of its releases is published.

### Changelog

- The `CHANGELOG.md` file at the repository root follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
- Maintain an `## [Unreleased]` section at the top with subsections `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security` (omit empty subsections).
- Each PR should add a one-line entry to the appropriate subsection of `[Unreleased]` referencing its PR number, e.g. `- Add the setups of extensions (#23).`.
- At release time, the `[Unreleased]` section is renamed to `[X.Y.Z] - YYYY-MM-DD` and a fresh `[Unreleased]` section is created.

### Releases

Releases are created on GitHub from annotated `vX.Y.Z` tags on `main`.
The release notes mirror the corresponding `CHANGELOG.md` section.

Release procedure (per release):

1. On a release branch (`release/vX.Y.Z`) from `dev`, update `CHANGELOG.md`: rename `[Unreleased]` to `[X.Y.Z] - YYYY-MM-DD` and add a new empty `[Unreleased]` section, then merge it into `dev`.
2. Open a PR from `dev` to `main` titled `chore(release): vX.Y.Z`, get it reviewed, and merge it, which makes the CI publish the images as `main`.
3. Tag the merge commit, which makes the CI publish the images of the release as `vX.Y.Z`, retagged from the `main` images whose sources are identical:

   ```shell
   git checkout main && git pull
   git tag -a vX.Y.Z -m "Release vX.Y.Z"
   git push origin vX.Y.Z
   ```

4. Create the GitHub release with `gh`, sourcing the notes from the changelog section, and keep the epic milestone open, since epics span many releases:

   ```shell
   gh release create vX.Y.Z \
     --title "vX.Y.Z" \
     --notes-file <(awk '/^## \[X.Y.Z\]/{p=1;next} p&&/^## \[/{exit} p' CHANGELOG.md)
   ```

## Reporting Issues

Please report bugs or request features using the [GitHub issue tracker](https://github.com/openrosde/openrosde/issues).
Include the platform name, host OS, and the output of the failing command.
Report a security vulnerability privately, with **Report a vulnerability** in the **Security** tab of the repository, as the [security policy](https://github.com/openrosde/.github/blob/main/SECURITY.md) of the organization describes, and never in a public issue.

## Adding a New Robot Platform

> [!NOTE]
> If you only need to add your own ROS packages, system dependencies, or environment variables, **do not add a new platform**.
> Use the [User Overlay](docs/user-overlay.md) (Layer 3) instead. It lives in [docker/user-devel/Dockerfile](docker/user-devel/Dockerfile), [ros/user_catkin_ws/](ros/user_catkin_ws/), and [docker/docker-compose-user.yaml](docker/docker-compose-user.yaml), and works on top of any selected `OPENROSDE_ROBOT_PLATFORM` without any of the steps below.

OpenRoSDE is designed to make adding a new platform straightforward.
A platform lives in an extension repository of its own, `openrosde-platform-<platform>`, cloned into `extensions/`, with the files of the platform at the same places as in the core (see [docs/extensions.md](docs/extensions.md)).
The core needs no change at all to find it, so a platform suits a robot that is private as well as a public one.
All platform-specific behavior is controlled by the `OPENROSDE_ROBOT_PLATFORM` variable.
Adding a new platform named `<platform>` (e.g., `myrobot`) requires creating a small set of files in its repository, which OpenRoSDE finds by that name.

The steps below use `<platform>` as a placeholder.
Replace it with your actual platform name (lowercase kebab-case, e.g., `myrobot`).
They copy the files of the canonical platform closest to your robot, such as the COBOTTA for an arm, cloned beside it:

```shell
git clone https://github.com/openrosde/openrosde-platform-cobotta.git extensions/openrosde-platform-cobotta
```

> [!TIP]
> The steps below describe a platform on ROS 1.
> A platform on ROS 2 follows them with the differences that [docs/ros2.md](docs/ros2.md) lists: two more lines in its template, an image on `openrosde-base-ros2`, colcon workspaces in `ros2/`, and launch files of ROS 2, as `turtlebot3-ros2` of `openrosde-platform-turtlebot3` shows.

### Step 1: Create the Platform Repository

Create an empty repository named `openrosde-platform-<platform>` and clone it into `extensions/`:

```shell
git clone <repository-url> extensions/openrosde-platform-<platform>
cd extensions/openrosde-platform-<platform>
```

Copy the repository files of the closest platform, then adapt them to your platform:

```shell
cp ../openrosde-platform-cobotta/{LICENSE,NOTICE,README.md,.gitignore} .
mkdir -p .github/workflows && cp ../openrosde-platform-cobotta/.github/workflows/test-with-openrosde.yml .github/workflows/
```

- `LICENSE`: the Apache License 2.0 of the public platforms, or the license of your choice.
- `NOTICE`: the copyright line of the platform and the notices of the third-party software it fetches or its image installs.
- `README.md`: what the platform holds, how to clone it, how the CI tests it, and its third-party software, in the structure that every platform repository shares.
- `.gitignore`: the files that `catkin build` creates in the workspace, which the `.gitignore` of the core does not reach.
- `.github/workflows/test-with-openrosde.yml`: the workflow that tests the platform with the core on every push to `main` and every pull request, through the reusable workflow `extension.yml` of the core, as [docs/extensions.md](docs/extensions.md#-testing-an-extension) describes.

The commands of the steps below run in the folder of the platform repository.

### Step 2: Create the Environment Template

Create `env/<platform>.env` by copying the template of the closest platform:

```shell
mkdir -p env && cp ../openrosde-platform-cobotta/env/cobotta.env env/<platform>.env
```

Edit the file to set:

```shell
OPENROSDE_ROBOT_PLATFORM=<platform>
OPENROSDE_ROBOT_SETUP=<platform>
```

The template of a platform is its default setup, so it declares its own name as the setup too.
The first line is how OpenRoSDE finds the platform: `scripts/list-robot-platforms.bash` lists every `env/<platform>.env` of the core and of the clones that declares its own name, and `SWITCH-ROBOT-PLATFORM.bash` and the CI pipeline use that list.

Update the `OPENROSDE_ROBOT_HOSTNAME` comment and value to match your platform's connectivity (SSH hostname, or empty if USB/local).
Leave all defaults in this file: do not add `${VAR:-default}` fallback syntax in scripts.

### Step 3: Create the Docker Image

Create `docker/<platform>-devel/Dockerfile`, using the Dockerfile of the closest platform as a template, such as `docker/cobotta-devel/Dockerfile` of `openrosde-platform-cobotta`.
The image is built from the folder of the platform repository, so its `COPY` instructions read from there.
Follow the Dockerfile code style from [`AGENTS.md`](AGENTS.md#dockerfiles):

- Start from the `openrosde-base` image via `ARG OPENROSDE_BASE_IMAGE`.
- Install platform-specific ROS packages with `apt-get install`.
- Set `OPENROSDE_ROBOT_PLATFORM` via `ARG`/`ENV`.
- Pass `OPENROSDE_DOCKERFILE_COMMIT_SHORT_SHA` via `ARG`/`ENV OPENROSDE_DOCKER_IMAGE_VERSION`.

### Step 4: Create the Docker Compose Overlay

Create `docker/docker-compose-<platform>.yaml`.
If no extra environment variables are needed beyond what `docker-compose.yaml` of the core already provides, use the minimal pattern of `docker/docker-compose-cobotta.yaml` of `openrosde-platform-cobotta`.
Docker Compose resolves the relative paths of the overlay against `docker/` of the core.

### Step 5: Create the Catkin Workspace and Launch Package

Create the platform Catkin workspace and launch package skeleton:

```shell
mkdir -p ros/<platform>_catkin_ws/src/openrosde_<platform>_launch/launch
touch ros/<platform>_catkin_ws/src/openrosde_<platform>_launch/.gitignore
```

Create the following files following the conventions in [`AGENTS.md`](AGENTS.md#ros-packages):

- `ros/<platform>_catkin_ws/src/openrosde_<platform>_launch/package.xml`: use format 2, with the license and the URLs of the platform repository.
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

### Step 6: Add Git Submodules (if needed)

If the platform requires third-party ROS packages not available as Noetic Debian packages, add them as Git submodules of the platform repository:

```shell
git submodule add <upstream-url> ros/<platform>_catkin_ws/src/<package>
```

Then in `.gitmodules` of the platform repository, set `branch` and `ignore = dirty` for the new submodule.

If the upstream packages need source-level fixes (e.g., broken XML, missing PID configs), create patch files under `patches/ros/<platform>_catkin_ws/src/<package>/` of the platform repository following the naming convention `NNNN-verb-noun-noun.patch`.
`bash ./scripts/update-git-submodules.bash` of the core updates the submodules of every clone and applies its patches.
Name in `NOTICE` the license of each submodule, and of each patch that modifies files under a license such as the GPL.
See [`AGENTS.md`](AGENTS.md#submodule-patches) for the patch workflow.

### Step 7: Create the Tmux Panes and the Terminator Layout

Create `tmux/<platform>.panes` with the panes of the platform in its `tmux` session, one per line, following `tmux/cobotta.panes` of `openrosde-platform-cobotta`:

```shell
default-gazebo     robot  <platform>_bringup_default_gazebo.launch
default-gazebo     robot  <platform>_rviz_default.launch
default-realworld  robot  <platform>_bringup_default_realworld.launch
```

Put every pane of the platform in the standard window `robot`, which holds its bringup, visualization, planning, and drivers, and leave the standard window `extra` to the optional processes of a setup or an extension, such as cameras or a demo.
The core adds its own windows `tools`, `user`, and `host` from `tmux/openrosde.panes`, and every session opens the standard windows in the order `robot`, `extra`, `tools`, `user`, `host`, whatever order the pane files declare them in, as [Advanced Usage](docs/advanced-usage.md) describes.
`gitlab-ci/check-launch-files.bash` fails on a pane in any other window.
Until [#3](https://github.com/openrosde/openrosde/issues/3) removes Terminator, also create the matching Terminator layout, `terminator/<platform>.config`, by copying the closest existing config:

```shell
mkdir -p terminator && cp ../openrosde-platform-cobotta/terminator/cobotta.config terminator/<platform>.config
```

Update the layout name pattern to `openrosde-<platform>-term-11-<variant>-<environment>` and update the `roslaunch` commands in each terminal pane.
`tests/suites/test-terminator-parity.bash` of the core checks that each layout of a platform cloned into `extensions/` runs the same launch files and arguments as the panes of that layout.

### Step 8: Create the Platform Documentation

Create `docs/robot-platforms/<platform>.md` following the structure of an existing platform doc (e.g., `docs/robot-platforms/cobotta.md` of `openrosde-platform-cobotta`).
Required sections:

- External Resources
- Hardware Overview
- Platform Configuration, with the clone of the platform repository into `extensions/`
- Network Configuration
- Gazebo Simulation
- Real Robot Operation
- Launch Files Reference
- Third-Party Software and Licensing, where it applies

### Step 9: Add the Platform Scripts and Checks (if needed)

The core scripts run the optional scripts of a platform from `scripts/<platform>/` of the platform repository, named after the core script that runs them, and print that nothing is configured when a script is missing:

| Script | Run by | Purpose |
| --- | --- | --- |
| `scripts/<platform>/initialize-bash-shell.bash` | `docker/openrosde-base/scripts/initialize-bash-shell.bash`, inside the container | Shell configuration of the platform, such as `TURTLEBOT3_MODEL` in `scripts/turtlebot3/` of `openrosde-platform-turtlebot3` |
| `scripts/<platform>/bringup-ros-robot.bash` | `BRINGUP-ROS-ROBOT.bash`, with the ROS master host name | Bringup of the real robot by SSH |
| `scripts/<platform>/restart-chrony-service.bash` | `RESTART-CHRONY-SERVICE.bash` | Chrony restart on the robot computer |
| `ci/check-in-container.bash` | The CI of the core, in the container of every setup of the platform, with no network | Checks of the platform beyond the build and the launch entry points, such as `ci/check-rosbridge.bash` of `openrosde-platform-fetch` |

Each script runs with every `OPENROSDE_*` variable that `scripts/load-openrosde-env.bash` exports.
The launch package of the platform is always `openrosde_<platform>_launch`, so it needs no registration.

### Step 10: List a Public Platform in the Core

The scripts and the CI pipeline find the platform by name, so a private platform needs nothing in the core.
A public platform is listed in the core, in a pull request of the core, so that its CI tests it and publishes its image:

| File | What to add |
| --- | --- |
| `gitlab-ci/extensions.repos` | The repository, with an anonymous HTTPS URL, pinned at a commit or a tag of its `main`, which the workflows of GitHub Actions clone |
| `README.md` | The platform table, with the URL of the repository, and the third-party table, with its `NOTICE` |

### Step 11: Test

```shell
# 1. Switch to the new platform, from the folder of the core:
bash ./SWITCH-ROBOT-PLATFORM.bash <platform>

# 2. Rebuild the Docker images:
bash ./BUILD-DOCKER-IMAGE.bash

# 3. Start the container:
bash ./RUN-DOCKER-CONTAINER.bash

# 4. Build the Catkin workspaces inside the container:
openrosde-reset-catkin-workspaces

# 5. Launch Gazebo simulation (in three terminals inside the container):
roslaunch openrosde_<platform>_launch <platform>_bringup_default_gazebo.launch
roslaunch openrosde_<platform>_launch <platform>_moveit_default_gazebo.launch
roslaunch openrosde_<platform>_launch <platform>_rviz_default.launch

# 6. Check for hardcoded paths:
grep -rn '/root/OpenRoSDE' --include='*.bash' --include='*.yaml' --include='*.yml' --include='Dockerfile' extensions/openrosde-platform-<platform>

# 7. Run the test suites of the core on the host, which also check that the 'tmux' panes of the clones match their Terminator layouts:
bash ./tests/run.bash
```

### Step 12: Publish the Platform

1. Commit the platform on `main` of its repository, and push it.
2. For a public platform, open a pull request of the core that lists it, as Step 10 describes, with the title `feat: add the <Platform Name> platform` and the structure documented in [Pull Requests](#pull-requests).
3. Add a `- Add the <Platform Name> platform from its own repository (#N).` entry under `### Added` in the `## [Unreleased]` section of `CHANGELOG.md` of the core.

## Code Style Quick Reference

See [`AGENTS.md`](AGENTS.md#code-style) for the full style guide.
