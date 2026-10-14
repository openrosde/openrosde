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
- `bash ./SWITCH-ROBOT-PLATFORM.bash` lists the platforms of the core, of every cloned extension, and of every part, so a platform extension needs no registration.
- The extensions and parts listed in `OPENROSDE_ROBOT_EXTENSIONS` are the active ones, and the folders that hold the active platform and the active setup are always active.
- The Catkin workspaces are built and sourced in this order: `ros/openrosde_catkin_ws` of the core, the workspace of the platform, every other workspace of the active extensions in the order of `OPENROSDE_ROBOT_EXTENSIONS`, the workspaces of the setup, then `ros/user_catkin_ws` of the core.
- `RUN-DOCKER-CONTAINER.bash` adds the overlay of the platform, then every `docker/docker-compose*.yaml` of the active folders, apart from those named after a platform or a setup that is not active.
- `RUN-TMUX-SESSION.bash` opens the panes of the setup, or else of the platform, then those of every `tmux/*.panes` of the active folders, apart from those named after a platform or another setup, then those of the core, and a setup can declare a layout of its own, such as `lab-demo`, for its demo.
- `BUILD-DOCKER-IMAGE.bash` builds every `docker/<name>-devel/Dockerfile` of the active extensions whose `<name>` is not a platform, each on top of the previous one, between the platform image and the user overlay, as the next section shows.
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

The template of every platform is its default setup, named after the platform, so `bash ./SWITCH-ROBOT-PLATFORM.bash <platform>` and `bash ./SWITCH-ROBOT-SETUP.bash <platform>` do the same.

Beside the template, `env/<setup>.repos` lists where to clone the repositories the setup needs, in the format of [`vcstool`](https://github.com/dirk-thomas/vcstool), the tool ROS projects use for the same purpose:

```yaml
repositories:
  openrosde-device-onrobot:
    type: git
    url: https://github.com/openrosde/openrosde-device-onrobot.git
    version: v1.0.0
  openrosde-device-realsense:
    type: git
    url: https://github.com/openrosde/openrosde-device-realsense.git
    version: v1.2.0
```

`bash ./SWITCH-ROBOT-SETUP.bash <setup>` clones the repositories that are missing from `extensions/`, at the versions the file pins, leaves the ones already cloned as they are, then copies the template to `.env.custom`.
Run `vcs import --input <setup>.repos extensions` to bring the cloned ones to the pinned versions as well.
The switch warns about a clone whose `origin` is not the URL that the file lists, which `vcs import` would leave as it is, and prints the `git remote set-url` command that fixes it.
It fails, and leaves the setup unchanged, when the platform of the setup or a name of its `OPENROSDE_ROBOT_EXTENSIONS` is still missing once the repositories are cloned.

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

## ⚙️ Configuration

| Variable | Default | Purpose |
| --- | --- | --- |
| `OPENROSDE_ROBOT_SETUP` | The platform | Active setup, named after its template `env/<setup>.env` |
| `OPENROSDE_ROBOT_EXTENSIONS` | Empty | Folder names of the active extensions in `extensions/` or of their parts, separated by spaces, in the order their workspaces build |
| `OPENROSDE_DOCKER_REGISTRY` | `registry.gitlab.com/coarobo/sde` | Registry where the base and platform images are pulled from and pushed to |

A platform image that the registry does not hold, such as the image of a private platform, is built locally by `BUILD-DOCKER-IMAGE.bash`, which falls back to a build when the pull fails.
Set `OPENROSDE_DOCKER_REGISTRY` in `.env.custom` to use a registry of your own.

## 🛣️ What Comes Next

Terminator leaves OpenRoSDE once the `tmux` sessions have run on a real robot, which closes [#38](https://gitlab.com/coarobo/SDE/-/issues/38).
