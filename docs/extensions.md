# Extensions

[[_TOC_]]

An **extension** is a Git repository cloned into `extensions/<extension>/` that adds a robot platform, a device, or any other package to OpenRoSDE without forking it.
Extensions keep OpenRoSDE a platform-agnostic core, with everything specific to a robot or a product around it, as the [OpenRoSDE Split](../AGENTS.md#openrosde-split) describes.

A private extension, cloned from a private repository of a company or a lab, works exactly as a public one.
OpenRoSDE never needs to know where an extension comes from.

## 🧩 Kinds of Extensions

OpenRoSDE treats every extension the same way, and only what an extension holds gives it its role.

| Kind | What it holds | Named after | Example name |
| --- | --- | --- | --- |
| Platform | One robot as sold, with its public drivers: `env/<platform>.env`, `docker/<platform>-devel/`, `ros/<platform>_catkin_ws/` | The robot, lowercase, without its maker | `openrosde-platform-ur5e` |
| Device | One upstream driver of hardware anyone can buy, such as a gripper, a camera, or an input device, with every model that driver supports, and naming no robot | The driver | `openrosde-device-realsense` |
| Extension | Anything else added beside a platform, such as the bindings of a product, the packages of a lab, or the setups of a company | Its owner or its purpose | `my-lab-packages` |

A device covers a family rather than one model, since one driver usually supports a whole product line: `openrosde-device-onrobot` covers the OnRobot RG and VG grippers, and `openrosde-device-spacenav` every 3Dconnexion device that `spacenavd` supports.
A device ships no `tmux/*.panes`, since which of its launch files run, and with which arguments, is the choice of each setup, whose panes start them.

A **setup** is one installation of a robot: the platform, devices, and extensions it pins, the description that mounts the devices, and the calibration, addresses, serial numbers, layouts, and runbook of that installation alone.
A setup is a template that any extension holds rather than a repository of its own, so one private extension of a company or a lab can hold its packages and the setups of all its robots.
A setup is named `<owner>-<platform>-<place>`, such as `my-lab-ur5e-bench`, so that the setups of the core, of a company, and of its clients never share a name, and platforms and devices anyone can buy are usually public, while setups are usually private.

## 📁 Layout

An extension shares the layout of the core, so that OpenRoSDE finds its files with the same rules:

```
extensions/<extension>/
  env/<platform>.env                     # Platform template, the default setup, which declares 'OPENROSDE_ROBOT_PLATFORM=<platform>' and 'OPENROSDE_ROBOT_SETUP=<platform>' (platforms only).
  env/<setup>.env                        # Setup template, which declares 'OPENROSDE_ROBOT_SETUP=<setup>', its platform, and its extensions (optional).
  env/<setup>.repos                      # Repositories of the setup for 'vcstool' (optional).
  docker/<platform>-devel/Dockerfile     # Platform image, built on 'openrosde-base' (platforms only).
  docker/<name>-devel/Dockerfile         # Docker layer of a device or an extension, built on the image below it (optional).
  docker/docker-compose-<name>.yaml      # Docker Compose overlay: environment variables, volumes, devices.
  ros/<name>_catkin_ws/src/              # One or more Catkin workspaces.
  scripts/<platform>/                    # Optional platform scripts (shell, bringup, Chrony), as for the core.
  tmux/<name>.panes                      # Panes of the 'tmux' session, in windows of their own.
  terminator/<platform>.config           # Terminator layouts of the platform, until 'tmux' replaces them (platforms only).
  patches/                               # Patches of the Git submodules of this extension.
  ci/check-in-container.bash             # Checks that the CI runs in the container of every setup that activates the extension (optional).
  ci/allowed-duplicate-nodes.txt         # Nodes that two panes of one layout may both start on purpose (optional).
  ci/allowed-simulation-launches.txt     # Launch files of simulations that the scripts of 'ci/' may start (optional).
  docs/                                  # Documentation of the extension.
```

> [!TIP]
> Give the extension a `.gitignore` for the files that `catkin build` and `catkin_init_workspace` create in its Catkin workspaces, since the `.gitignore` of the core does not reach into another repository.
> The `**/` prefix also covers the workspaces of its parts:
>
> ```gitignore
> **/ros/*_catkin_ws/CMakeLists.txt
> **/ros/*_catkin_ws/.catkin_tools/
> **/ros/*_catkin_ws/build/
> **/ros/*_catkin_ws/devel/
> **/ros/*_catkin_ws/logs/
> **/ros/*_catkin_ws/src/CMakeLists.txt
> ```

## 🧱 Parts

A company or a lab with several robots can keep the units of all of them in one extension, split into parts.
A part is a folder `parts/<part>/` of the extension with the layout of the core, such as the setup of one robot, the bindings of a product, or a private platform, and it is activated by its name alone, like an extension:

```
extensions/<extension>/
  README.md                              # Files that OpenRoSDE never reads, such as 'README.md', 'LICENSE', 'docs/', and the tools of the extension.
  .gitmodules                            # Git submodules of every part.
  parts/acme-bench/                      # Setup of one robot: 'env/acme-ur5e-lab.env', 'env/acme-ur5e-lab.repos', 'tmux/acme-ur5e-lab.panes', and its workspaces and layers.
  parts/acme-binding/                    # Packages added beside a platform, such as the bindings of a product: 'ros/', 'docker/', and 'tmux/'.
  parts/acme-robot/                      # Private platform with its setups: 'env/<platform>.env', 'docker/<platform>-devel/', and 'ros/<platform>_catkin_ws/'.
```

- OpenRoSDE looks up the templates of every part right after those of its extension, so the platforms and setups of a part are listed and selected like any other.
- `OPENROSDE_ROBOT_EXTENSIONS` takes the name of an extension in `extensions/<name>/` or of a part in `extensions/<extension>/parts/<name>/`, which must be the only folder of that name, so name each part after its owner and its purpose, such as `acme-binding`.
- A setup lists the parts it needs in `OPENROSDE_ROBOT_EXTENSIONS`, such as `"acme-binding"`, while the part that holds the setup and the part that holds the platform are active without being listed.
- An active part counts as one unit: all its Catkin workspaces and Docker layers are used, and its files named after a platform or a setup only when that platform or setup is active.
- The Git submodules of a part belong to the repository of the extension, which declares them in its `.gitmodules`, and each part keeps its own `patches/`, which mirror the submodule paths from the folder of the part.
- Keep `env/`, `docker/`, `ros/`, and `tmux/` out of the folder of the extension itself, so that every unit lives in a part.

## 🔎 How OpenRoSDE Finds Files

- An environment template `env/<name>.env` is looked up in the core first, then in every cloned extension followed by its parts, in alphabetical order.
- A file named after the setup, such as `scripts/<setup>/bringup-ros-robot.bash`, `terminator/<setup>.config`, or `tmux/<setup>.panes`, comes from the folder that holds the setup.
- A file named after the platform, such as `docker/<platform>-devel/Dockerfile`, `docker/docker-compose-<platform>.yaml`, or `tmux/<platform>.panes`, comes from the folder that holds the platform, then from the core, so a clone that is not active never supplies one.
- An active folder may still add an overlay or a pane file named after the active platform or setup, such as a device with an overlay for each platform it supports, which comes after the file of the platform.
- `bash ./SWITCH-ROBOT-PLATFORM.bash` lists the platforms of the core, of every cloned extension, and of every part, so a platform extension needs no registration.
- The extensions and parts listed in `OPENROSDE_ROBOT_EXTENSIONS` are the active ones, and the folders that hold the active platform and the active setup are always active.
- The Catkin workspaces are built and sourced in this order: `ros/openrosde_catkin_ws` of the core, the workspace of the platform, every other workspace of the active extensions in the order of `OPENROSDE_ROBOT_EXTENSIONS`, the workspaces of the setup, then `ros/user_catkin_ws` of the core.
- `RUN-DOCKER-CONTAINER.bash` adds the overlay of the platform, then every `docker/docker-compose*.yaml` of the active folders, apart from those named after a platform or a setup that is not active.
- `RUN-TMUX-SESSION.bash` opens the panes of the setup, or else of the platform, whose own `tmux/<platform>.panes` the panes of the setup replace, then those of every `tmux/*.panes` of the active folders, apart from those named after a platform or a setup that is not active, then those of the core, and a setup can declare a layout of its own, such as `lab-demo`, for its demo.
- `BUILD-DOCKER-IMAGE.bash` builds the image of the platform from the folder that holds the platform, so that the `COPY` instructions of its `docker/<platform>-devel/Dockerfile` read from there, as those of a layer do.
- `BUILD-DOCKER-IMAGE.bash` builds every `docker/<name>-devel/Dockerfile` of the active extensions whose `<name>` is not a platform, each on top of the previous one, between the platform image and the user overlay, as the section on Docker layers below shows.
- `bash ./scripts/update-git-submodules.bash` updates the Git submodules of the core and of every cloned extension, and applies the `patches/` of each repository and of each part to its own submodules.

> [!NOTE]
> Docker Compose resolves the relative paths of every overlay against `docker/` of the core, so an overlay of an extension writes its paths from there, such as `../extensions/<extension>/config:/root/config`.

`scripts/load-extension-paths.bash` holds these rules, on the host and inside the Docker container alike.

## 🧭 Setups

A setup is an environment template `env/<setup>.env` that declares its own name, its platform, and its extensions:

```shell
OPENROSDE_ROBOT_PLATFORM=ur5e
OPENROSDE_ROBOT_SETUP=my-lab-ur5e-bench
OPENROSDE_ROBOT_EXTENSIONS="openrosde-device-onrobot openrosde-device-realsense"
```

OpenRoSDE finds platforms and setups by reading the lines `OPENROSDE_ROBOT_PLATFORM=<platform>` and `OPENROSDE_ROBOT_SETUP=<setup>` of each template as they are, without running it.
Write each of them alone on its line, with no quotes, no spaces, and no trailing comment, while `OPENROSDE_ROBOT_EXTENSIONS` takes quotes around several names.
`scripts/list-robot-platforms.bash` and `scripts/list-robot-setups.bash` name every template that breaks this rule with an error, and warn when two templates declare the same name, in which case OpenRoSDE uses the first one in the order of the core, then of every extension followed by its parts.
Name a setup in lowercase letters and digits separated by dashes, as `my-lab-ur5e-bench` is, since the name of the setup also names its local Docker images, `openrosde-local/<setup>/`, where Docker takes no uppercase letter.
OpenRoSDE lowercases the names of the setup and of its layers in those images, and `scripts/load-openrosde-env.bash` prints an error for a setup name that Docker refuses even so.

The template of every platform is its default setup, named after the platform, so `bash ./SWITCH-ROBOT-PLATFORM.bash <platform>` and `bash ./SWITCH-ROBOT-SETUP.bash <platform>` do the same.

Beside the template, `env/<setup>.repos` lists where to clone the repositories the setup needs, in the format of [`vcstool`](https://github.com/dirk-thomas/vcstool), the tool ROS projects use for the same purpose:

```yaml
repositories:
  openrosde-device-onrobot:
    type: git
    url: https://gitlab.com/coarobo/openrosde/openrosde-device-onrobot.git
    version: v1.0.0
  openrosde-device-realsense:
    type: git
    url: https://gitlab.com/coarobo/openrosde/openrosde-device-realsense.git
    version: v1.2.0
```

The versions of this example only show the format, so pin each repository at a tag or a branch that it publishes.
`bash ./SWITCH-ROBOT-SETUP.bash <setup>` clones the repositories that are missing from `extensions/`, at the versions the file pins, leaves the ones already cloned as they are, then copies the template to `.env.custom`.
Run `vcs import --input <setup>.repos extensions` to bring the cloned ones to the pinned versions as well.
The switch warns about a clone whose `origin` points to another repository than the URL that the file lists, which `vcs import` would leave as it is, and prints a `git remote set-url` command that would point it there.
A clone over SSH of a repository that the file lists over HTTPS, or the reverse, is the same repository and raises no warning.
It fails, and leaves the setup unchanged, when the platform of the setup or a name of its `OPENROSDE_ROBOT_EXTENSIONS` is still missing once the repositories are cloned.

A setup may also pin the version of OpenRoSDE it was tested with, as a release tag or a branch:

```shell
OPENROSDE_CORE_VERSION=v3.0.0
```

`bash ./SWITCH-ROBOT-SETUP.bash <setup>` then warns when OpenRoSDE is checked out at another version, neither a tag of the checked out commit nor the checked out branch, and prints the `git checkout` command of the pinned version.
The switch still succeeds, since the setup may well run on another version.
A checkout of a release tag still pulls the `main` images by default.
The CI publishes the images of a release under its tag, such as `v3.0.0`, from the release pipeline on, so set `OPENROSDE_DOCKER_IMAGE_TAG` to that tag in `.env.custom` to pull them, or build the images of an older release locally with `bash ./BUILD-DOCKER-IMAGE.bash local`.

The folder that holds the setup is always active, after the extensions of `OPENROSDE_ROBOT_EXTENSIONS`, so its workspace builds last, before the user workspace.
A file named after the setup takes precedence over the file named after its platform, such as `scripts/<setup>/bringup-ros-robot.bash` over `scripts/<platform>/bringup-ros-robot.bash`, `terminator/<setup>.config` over `terminator/<platform>.config`, or `tmux/<setup>.panes` over `tmux/<platform>.panes`, whose panes it replaces.

> [!NOTE]
> A `.env.custom` written before setups existed declares no setup, so OpenRoSDE uses its platform as the setup and keeps its platform files.

## 🐳 Docker Layers

A device or an extension that needs system packages, such as the driver of a camera, holds a Docker layer in `docker/<name>-devel/Dockerfile`, built on the image below it:

```dockerfile
# Inherit from the image below this layer, given by 'BUILD-DOCKER-IMAGE.bash'.
ARG OPENROSDE_PARENT_IMAGE
FROM ${OPENROSDE_PARENT_IMAGE}

# Install the system dependencies of the extension.
RUN apt-get update && apt-get install -y --no-install-recommends \
  ros-noetic-realsense2-camera \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Embed the commit hash of this Dockerfile for traceability.
ARG OPENROSDE_DOCKERFILE_COMMIT_SHORT_SHA
```

The layers stack in the order of the active folders, so the image of a setup reads from the bottom up:

```
openrosde-base  ->  <platform>-devel  ->  <device>-devel  ->  <extension>-devel  ->  <setup>-devel  ->  user-devel
```

- Each layer is built from the folder of its extension, so its `COPY` instructions read from there.
- The layers are always built locally by `scripts/build-extension-layers.bash`, which `BUILD-DOCKER-IMAGE.bash` runs in both its default and `local` modes, and never pushed, like the user overlay, so the layers of a private extension never leave the machine.
- Each layer is tagged `openrosde-local/<setup>/<name>-devel:latest`, and the user overlay `openrosde-local/<setup>/user-devel:latest`, rather than with the name of the registry.
  A name without a registry host points to Docker Hub, where a repository has a namespace and a name without `/`, so no repository of three components can exist there, and a `docker push` of a private layer fails with `push access denied` rather than publishing it.
  Two setups that share a device also never overwrite the layer of each other.
- A CI job builds the layers of a setup with the same script in its Docker-in-Docker daemon, on top of the platform image that it pulls, and pushes none of them, as the CI of OpenRoSDE does for every setup it tests.

## 🚀 Using an Extension

1. For a setup, clone the extension that holds it, then switch to it, which clones the rest:

    ```shell
    git clone <repository-url> extensions/<extension>
    bash ./SWITCH-ROBOT-SETUP.bash <setup>
    ```

    Otherwise, clone the extension into `extensions/`, with your own credentials if it is private:

    ```shell
    git clone <repository-url> extensions/<extension>
    bash ./scripts/update-git-submodules.bash
    ```

2. For a platform extension, switch to its platform, which `SWITCH-ROBOT-PLATFORM.bash` lists like a platform of the core:

    ```shell
    bash ./SWITCH-ROBOT-PLATFORM.bash <platform>
    ```

3. For any other extension or part, add its folder name to `OPENROSDE_ROBOT_EXTENSIONS` in `.env.custom`, separated by spaces, in the order its workspaces build:

    ```shell
    OPENROSDE_ROBOT_EXTENSIONS="openrosde-device-realsense my-lab-packages"
    ```

4. Build the images and the workspaces as usual:

    ```shell
    bash ./BUILD-DOCKER-IMAGE.bash
    bash ./RUN-DOCKER-CONTAINER.bash
    openrosde-reset-catkin-workspaces
    ```

## 🤖 Canonical Platforms

The canonical platforms of OpenRoSDE live in public repositories of their own, under the Apache License 2.0, each with the layout of the core:

| Platform | Robot | Repository |
| --- | --- | --- |
| `cobotta` | Denso COBOTTA | [https://gitlab.com/coarobo/openrosde/openrosde-platform-cobotta](https://gitlab.com/coarobo/openrosde/openrosde-platform-cobotta) |
| `fetch` | Fetch Robotics Fetch | [https://gitlab.com/coarobo/openrosde/openrosde-platform-fetch](https://gitlab.com/coarobo/openrosde/openrosde-platform-fetch) |
| `hsr` | Toyota HSR (Human Support Robot) | [https://gitlab.com/coarobo/openrosde/openrosde-platform-hsr](https://gitlab.com/coarobo/openrosde/openrosde-platform-hsr) |
| `sciurus17` | RT Sciurus17 | [https://gitlab.com/coarobo/openrosde/openrosde-platform-sciurus17](https://gitlab.com/coarobo/openrosde/openrosde-platform-sciurus17) |
| `turtlebot3` | Robotis TurtleBot3 (Waffle Pi) | [https://gitlab.com/coarobo/openrosde/openrosde-platform-turtlebot3](https://gitlab.com/coarobo/openrosde/openrosde-platform-turtlebot3) |
| `ur5e` | Universal Robots UR5e | [https://gitlab.com/coarobo/openrosde/openrosde-platform-ur5e](https://gitlab.com/coarobo/openrosde/openrosde-platform-ur5e) |

Clone one into `extensions/`, then switch to it, as for any platform extension:

```shell
git clone https://gitlab.com/coarobo/openrosde/openrosde-platform-fetch.git extensions/openrosde-platform-fetch
bash ./SWITCH-ROBOT-PLATFORM.bash fetch
```

- `gitlab-ci/extensions.repos` pins each of them at a commit of its `main`, so the CI of the core clones them, builds or reuses their images, and publishes them as `registry.gitlab.com/coarobo/sde/<platform>-devel`, as it did when the core held them.
- Each platform repository tests its own changes with the trigger that the section below describes, and a merge request of the core moves the pin once a change of the platform is merged.
- The `NOTICE` of each platform repository records the licenses of its third-party software, some of which allow no commercial use.
- The UR5e in `openrosde-platform-ur5e` is the plain robot as sold, and a setup that mounts a gripper or cameras on it names its own description package in `OPENROSDE_UR5E_DESCRIPTION_PACKAGE`, as `docs/robot-platforms/ur5e.md` of that repository describes.

## 🧪 Testing an Extension

The CI of OpenRoSDE tests every setup it finds, in the core and in the public extensions that `gitlab-ci/extensions.repos` pins, in the format of `vcstool`:

```yaml
repositories:
  openrosde-platform-foo:
    type: git
    url: https://gitlab.com/coarobo/openrosde/openrosde-platform-foo.git
    version: v1.0.0
```

Keep that layout, with each name indented by two spaces and its keys by four, since `gitlab-ci/clone-extensions.bash` refuses any other rather than testing nothing.
Update a `version` by hand, and never write the file with `vcs export` of the whole `extensions/` folder, which would add every clone of the checkout, private ones included.

- The generate job and every other job clone these repositories with `gitlab-ci/clone-extensions.bash`, anonymously over HTTPS, and never with a token of the job, so a pipeline of OpenRoSDE, which anyone can read, never reaches a private repository.
- The image job of a platform builds its image from the folder that holds it, and reuses an image whose folders hash the same, each folder hashed in the Git repository that holds it.
- The test job of a setup selects the setup as `bash ./SWITCH-ROBOT-SETUP.bash <setup>` does, builds its Docker layers and its Catkin workspaces in the image of its platform, then disconnects the container from every network before any check runs.
- It then checks that every launch entry point of the panes of the setup resolves with `roslaunch --files`, and that no two panes of one layout start a node of the same name with `roslaunch --nodes`, both of which start no node, and fails when neither the setup nor its platform has a pane file.
- It then runs `ci/check-in-container.bash` of every active extension that holds one, with the setup as its argument, in the container where the workspaces of the setup are built and sourced, once `check-scripts-job` has passed.
- The panes that name no package run the launch package of the platform, `openrosde_<platform>_launch`, unless `scripts/<setup or platform>/initialize-bash-shell.bash` sets another `OPENROSDE_LAUNCH_PACKAGE`, as it does in a shell of the container.

Two panes of one layout that start a node of the same name shut each other down, so the check names both.
An extension that does this on purpose lists the node in `ci/allowed-duplicate-nodes.txt`, one `<layout> <node-name> [<launch-file> ...]` per line, where `<layout>` is `*` for every layout.
A line that names launch files, as written in the panes, allows the node only when every pane that starts it runs one of them, such as two panes that a session runs one at a time:

```
default-gazebo /robot_state_publisher foo_navigation_default_gazebo.launch foo_mapping_default.launch
```

A check in `ci/` never moves a robot: `gitlab-ci/check-no-motion.bash` fails on any `roslaunch` beyond `--files`, `--nodes`, or `--dump-params`, and on any `rosrun`, `rostopic pub`, or `rosservice call`, even after a path such as `/opt/ros/noetic/bin/`, and an option in a trailing comment does not count.
It lets a script of `ci/` start only the launch files of simulations that `ci/allowed-simulation-launches.txt` names, one file name per line, such as `foo_bringup_default_gazebo.launch`.

A public extension tests one of its branches against the core with a job that triggers a pipeline of OpenRoSDE on `dev`, once `gitlab-ci/extensions.repos` lists it:

```yaml
test-with-openrosde-job:
  trigger:
    project: coarobo/SDE
    branch: dev
    strategy: depend
  variables:
    OPENROSDE_CI_EXTENSION_OVERRIDE: ${CI_PROJECT_NAME}=${CI_COMMIT_REF_NAME}@${CI_COMMIT_SHA}
```

- That pipeline checks out the commit in place of the pinned version, then tests only the setups that activate the extension, with their platforms, and never publishes its images.
- A device that no setup of OpenRoSDE lists yet also sets `OPENROSDE_CI_EXTRA_EXTENSIONS: ${CI_PROJECT_NAME}`, which adds it to every setup.
- The name of the project must be the name that `gitlab-ci/extensions.repos` lists, and a pipeline of a fork cannot trigger one of OpenRoSDE.

A private extension runs the same scripts in a pipeline of its own, in a private project, with OpenRoSDE checked out at the version it pins, since OpenRoSDE never clones a private repository.
It reads the public base and platform images by setting `OPENROSDE_CI_IMAGE_REGISTRY` to `registry.gitlab.com/coarobo/sde` and `OPENROSDE_CI_IMAGE_TAG` to the tag of that version, `dev` or a release such as `v3.0.0`, and keeps its own images in its own registry.
Both are needed, since the default tag, `pipeline-<id>` with the ID of the running pipeline, names only the images that a pipeline of OpenRoSDE pushes for itself.
It may instead pass the image to `gitlab-ci/test-catkin-workspaces.bash` as its second argument, such as `registry.gitlab.com/coarobo/sde/ur5e-devel:v3.0.0`.
Outside the CI, the script refuses to replace an existing `.env.custom`, so move it aside before running the script by hand.

## ⚙️ Configuration

| Variable | Default | Purpose |
| --- | --- | --- |
| `OPENROSDE_ROBOT_SETUP` | The platform | Active setup, named after its template `env/<setup>.env` |
| `OPENROSDE_ROBOT_EXTENSIONS` | Empty | Folder names of the active extensions in `extensions/` or of their parts, separated by spaces, in the order their workspaces build |
| `OPENROSDE_DOCKER_REGISTRY` | `registry.gitlab.com/coarobo/sde` | Registry where the base and platform images are pulled from and pushed to |
| `OPENROSDE_DOCKER_BUILD_FALLBACK` | `true` | Images that `BUILD-DOCKER-IMAGE.bash` builds locally when their pull fails: `true` for the base and platform images, `platform` for the platform image alone, or `false` for neither |
| `OPENROSDE_QUIET` | `false` | Leaves out the list of every `OPENROSDE_*` variable that the entry scripts print, whose passwords, tokens, and secrets always print as `<redacted>` |
| `OPENROSDE_CORE_VERSION` | Empty | Version of OpenRoSDE that a setup template pins, as a release tag or a branch, which `SWITCH-ROBOT-SETUP.bash` compares with the checkout |

A platform image that the registry does not hold, such as the image of a private platform, is built locally by `BUILD-DOCKER-IMAGE.bash`, which falls back to a build when the pull fails.
A CI job sets `OPENROSDE_DOCKER_BUILD_FALLBACK=platform` in `.env.custom` to build a private platform but never the base image, which takes hours, or `false` to fail as soon as a pull fails.
Set `OPENROSDE_DOCKER_REGISTRY` in `.env.custom` to use a registry of your own.

## 🛣️ What Comes Next

Terminator leaves OpenRoSDE once the `tmux` sessions have run on a real robot, which closes [#38](https://gitlab.com/coarobo/SDE/-/issues/38).
