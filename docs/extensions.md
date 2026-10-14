# Extensions

[[_TOC_]]

An **extension** is a Git repository cloned into `extensions/<extension>/` that adds a robot platform, a device, or any other package to OpenRoSDE without forking it.
Extensions are how the SDE becomes OpenRoSDE, a platform-agnostic core with everything specific to a robot or a product around it, as the [OpenRoSDE Split](../AGENTS.md#openrosde-split) describes.

A private extension, cloned from a private repository of a company or a lab, works exactly as a public one.
OpenRoSDE never needs to know where an extension comes from.

## 🧩 Kinds of Extensions

OpenRoSDE treats every extension the same way, and only what an extension holds gives it its role.

| Kind | What it holds | Example name |
| --- | --- | --- |
| Platform | One robot as sold, with its public drivers: `env/<platform>.env`, `docker/<platform>-devel/`, `ros/<platform>_catkin_ws/` | `openrosde-platform-ur5e` |
| Device | One piece of hardware anyone can buy, such as a gripper, a camera, or an input device, which names no robot | `openrosde-device-realsense` |
| Extension | Anything else added beside a platform, such as a product binding or packages of a project | `coarobo-extension-sightline` |
| Setup | One installation of a robot: the platform, devices, and extensions it pins, the description that mounts the devices, the calibration, addresses, serial numbers, layouts, and runbook of that installation alone | `coarobo-setup-ur5e-office` |

The setup of a company and the setup of its client take the same shape, and both are usually private, while platforms and devices anyone can buy are usually public.

## 📁 Layout

An extension shares the layout of the core, so that OpenRoSDE finds its files with the same rules:

```
extensions/<extension>/
  env/<platform>.env                     # Platform template, the default setup, which declares 'OPENROSDE_ROBOT_PLATFORM=<platform>' and 'OPENROSDE_ROBOT_SETUP=<platform>' (platforms only).
  env/<setup>.env                        # Setup template, which declares 'OPENROSDE_ROBOT_SETUP=<setup>', its platform, and its extensions (setups only).
  env/<setup>.repos                      # Repositories of the setup for 'vcstool' (setups only).
  docker/<platform>-devel/Dockerfile     # Platform image, built on 'openrosde-base' (platforms only).
  docker/<name>-devel/Dockerfile         # Docker layer of a device or an extension, built on the image below it (optional).
  docker/docker-compose-<name>.yaml      # Docker Compose overlay: environment variables, volumes, devices.
  ros/<name>_catkin_ws/src/              # One or more Catkin workspaces.
  scripts/<platform>/                    # Optional platform scripts (shell, bringup, Chrony), as for the core.
  tmux/<name>.panes                      # Panes of the 'tmux' session, in windows of their own.
  terminator/<platform>.config           # Terminator layouts of the platform, until 'tmux' replaces them (platforms only).
  patches/                               # Patches of the Git submodules of this extension.
  docs/                                  # Documentation of the extension.
```

> [!TIP]
> Give the extension a `.gitignore` for the `build/`, `devel/`, `logs/`, and `.catkin_tools/` folders of its Catkin workspaces, since the `.gitignore` of the core does not reach into another repository.

## 🔎 How OpenRoSDE Finds Files

- A file named after a setup or a platform, such as `env/<platform>.env`, `docker/<platform>-devel/Dockerfile`, `terminator/<platform>.config`, or `scripts/<platform>/bringup-ros-robot.bash`, is looked up in the core first, then in every cloned extension in alphabetical order.
- `bash ./SWITCH-ROBOT-PLATFORM.bash` lists the platforms of the core and of every cloned extension, so a platform extension needs no registration.
- The extensions listed in `OPENROSDE_ROBOT_EXTENSIONS` are the active ones, and the extensions that hold the active platform and the active setup are always active.
- The Catkin workspaces are built and sourced in this order: `ros/openrosde_catkin_ws` of the core, the workspace of the platform, every other workspace of the active extensions in the order of `OPENROSDE_ROBOT_EXTENSIONS`, the workspaces of the setup, then `ros/user_catkin_ws` of the core.
- `RUN-DOCKER-CONTAINER.bash` adds every `docker/docker-compose*.yaml` of the active extensions after the overlay of the platform.
- `RUN-TMUX-SESSION.bash` opens the panes of the platform, then those of every `tmux/*.panes` of the active extensions and the setup, then those of the core, and a setup can declare a layout of its own, such as `lab-demo`, for its demo.
- `BUILD-DOCKER-IMAGE.bash` builds every `docker/<name>-devel/Dockerfile` of the active extensions whose `<name>` is not a platform, each on top of the previous one, between the platform image and the user overlay, as the next section shows.
- `bash ./scripts/update-git-submodules.bash` updates the Git submodules of the core and of every cloned extension, and applies the `patches/` of each repository to its own submodules.

> [!NOTE]
> Docker Compose resolves the relative paths of every overlay against `docker/` of the core, so an overlay of an extension writes its paths from there, such as `../extensions/<extension>/config:/root/config`.

`scripts/load-extension-paths.bash` holds these rules, on the host and inside the Docker container alike.

## 🧭 Setups

A setup is an environment template `env/<setup>.env` that declares its own name, its platform, and its extensions:

```shell
OPENROSDE_ROBOT_PLATFORM=ur5e
OPENROSDE_ROBOT_SETUP=my-lab-ur5e
OPENROSDE_ROBOT_EXTENSIONS="openrosde-device-onrobot-rg openrosde-device-realsense"
```

The template of every platform is its default setup, named after the platform, so `bash ./SWITCH-ROBOT-PLATFORM.bash <platform>` and `bash ./SWITCH-ROBOT-SETUP.bash <platform>` do the same.

Beside the template, `env/<setup>.repos` lists where to clone the repositories the setup needs, in the format of [`vcstool`](https://github.com/dirk-thomas/vcstool), the tool ROS projects use for the same purpose:

```yaml
repositories:
  openrosde-device-onrobot-rg:
    type: git
    url: https://github.com/<organization>/openrosde-device-onrobot-rg.git
    version: v1.0.0
  openrosde-device-realsense:
    type: git
    url: https://github.com/<organization>/openrosde-device-realsense.git
    version: v1.2.0
```

`bash ./SWITCH-ROBOT-SETUP.bash <setup>` clones the repositories that are missing from `extensions/`, at the versions the file pins, leaves the ones already cloned as they are, then copies the template to `.env.custom`.
Run `vcs import --input <setup>.repos extensions` to bring the cloned ones to the pinned versions as well.

The folder that holds the setup is always active, after the extensions of `OPENROSDE_ROBOT_EXTENSIONS`, so its workspace builds last, before the user workspace.
A file named after the setup takes precedence over the file named after its platform, such as `scripts/<setup>/bringup-ros-robot.bash` over `scripts/<platform>/bringup-ros-robot.bash`, or `terminator/<setup>.config` over `terminator/<platform>.config`.

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
- The layers are always built locally by `BUILD-DOCKER-IMAGE.bash`, in both its default and `local` modes, and never pushed, like the user overlay, so the layers of a private extension never leave the machine.
- The CI of OpenRoSDE builds no layer, since layers belong to a setup.

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

3. For any other extension, add its folder name to `OPENROSDE_ROBOT_EXTENSIONS` in `.env.custom`, separated by spaces, in the order its workspaces build:

    ```shell
    OPENROSDE_ROBOT_EXTENSIONS="openrosde-device-realsense my-lab-packages"
    ```

4. Build the images and the workspaces as usual:

    ```shell
    bash ./BUILD-DOCKER-IMAGE.bash
    bash ./RUN-DOCKER-CONTAINER.bash
    openrosde-reset-catkin-workspaces
    ```

## ⚙️ Configuration

| Variable | Default | Purpose |
| --- | --- | --- |
| `OPENROSDE_ROBOT_SETUP` | The platform | Active setup, named after its template `env/<setup>.env` |
| `OPENROSDE_ROBOT_EXTENSIONS` | Empty | Folder names of the active extensions in `extensions/`, separated by spaces, in the order their workspaces build |
| `OPENROSDE_DOCKER_REGISTRY` | `registry.gitlab.com/coarobo/sde` | Registry where the base and platform images are pulled from and pushed to |

A platform image that the registry does not hold, such as the image of a private platform, is built locally by `BUILD-DOCKER-IMAGE.bash`, which falls back to a build when the pull fails.
Set `OPENROSDE_DOCKER_REGISTRY` in `.env.custom` to use a registry of your own.

## 🛣️ What Comes Next

Terminator leaves OpenRoSDE once the `tmux` sessions have run on a real robot, which closes [#38](https://gitlab.com/coarobo/SDE/-/issues/38).
