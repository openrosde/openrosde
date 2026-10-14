# Extensions

[[_TOC_]]

An **extension** is a Git repository cloned into `extensions/<extension>/` that adds a robot platform, a device, or any other package to the SDE without forking it.
Extensions are how the SDE becomes OpenRoSDE, a platform-agnostic core with everything specific to a robot or a product around it, as the [OpenRoSDE Split](../AGENTS.md#openrosde-split) describes.

A private extension, cloned from a private repository of a company or a lab, works exactly as a public one.
The SDE never needs to know where an extension comes from.

## 🧩 Kinds of Extensions

The SDE treats every extension the same way, and only what an extension holds gives it its role.

| Kind | What it holds | Example name |
| --- | --- | --- |
| Platform | One robot as sold, with its public drivers: `env/<platform>.env`, `docker/<platform>-devel/`, `ros/<platform>_catkin_ws/` | `openrosde-platform-ur5e` |
| Device | One piece of hardware anyone can buy, such as a gripper, a camera, or an input device, which names no robot | `openrosde-device-realsense` |
| Extension | Anything else added beside a platform, such as a product binding or packages of a project | `coarobo-extension-sightline` |

Setups, which pin one platform with its devices and extensions for one installation of a robot, come next in [#38](https://gitlab.com/coarobo/SDE/-/issues/38).

## 📁 Layout

An extension shares the layout of the core, so that the SDE finds its files with the same rules:

```
extensions/<extension>/
  env/<platform>.env                     # Platform template, which declares 'SDE_ROBOT_PLATFORM=<platform>' (platforms only).
  docker/<platform>-devel/Dockerfile     # Platform image, built on 'sde-base' (platforms only).
  docker/docker-compose-<name>.yaml      # Docker Compose overlay: environment variables, volumes, devices.
  ros/<name>_catkin_ws/src/              # One or more Catkin workspaces.
  scripts/<platform>/                    # Optional platform scripts (shell, bringup, Chrony), as for the core.
  terminator/<platform>.config           # Terminator layouts of the platform (platforms only).
  patches/                               # Patches of the Git submodules of this extension.
  docs/                                  # Documentation of the extension.
```

> [!TIP]
> Give the extension a `.gitignore` for the `build/`, `devel/`, `logs/`, and `.catkin_tools/` folders of its Catkin workspaces, since the `.gitignore` of the core does not reach into another repository.

## 🔎 How the SDE Finds Files

- A file named after a platform, such as `env/<platform>.env`, `docker/<platform>-devel/Dockerfile`, `terminator/<platform>.config`, or `scripts/<platform>/bringup-ros-robot.bash`, is looked up in the core first, then in every cloned extension in alphabetical order.
- `bash ./SWITCH-ROBOT-PLATFORM.bash` lists the platforms of the core and of every cloned extension, so a platform extension needs no registration.
- The extensions listed in `SDE_ROBOT_EXTENSIONS` are the active ones, and the extension that holds the active platform is always active.
- The Catkin workspaces are built and sourced in this order: `ros/sde_catkin_ws` of the core, the workspace of the platform, every other workspace of the active extensions in the order of `SDE_ROBOT_EXTENSIONS`, then `ros/user_catkin_ws` of the core.
- `RUN-DOCKER-CONTAINER.bash` adds every `docker/docker-compose*.yaml` of the active extensions after the overlay of the platform.
- `bash ./scripts/update-git-submodules.bash` updates the Git submodules of the core and of every cloned extension, and applies the `patches/` of each repository to its own submodules.

> [!NOTE]
> Docker Compose resolves the relative paths of every overlay against `docker/` of the core, so an overlay of an extension writes its paths from there, such as `../extensions/<extension>/config:/root/config`.

`scripts/load-extension-paths.bash` holds these rules, on the host and inside the Docker container alike.

## 🚀 Using an Extension

1. Clone the extension into `extensions/`, with your own credentials if it is private:

    ```shell
    git clone <repository-url> extensions/<extension>
    bash ./scripts/update-git-submodules.bash
    ```

2. For a platform extension, switch to its platform, which it lists like a platform of the core:

    ```shell
    bash ./SWITCH-ROBOT-PLATFORM.bash <platform>
    ```

3. For any other extension, add its folder name to `SDE_ROBOT_EXTENSIONS` in `.env.custom`, separated by spaces, in the order its workspaces build:

    ```shell
    SDE_ROBOT_EXTENSIONS="openrosde-device-realsense my-lab-packages"
    ```

4. Build the images and the workspaces as usual:

    ```shell
    bash ./BUILD-DOCKER-IMAGE.bash
    bash ./RUN-DOCKER-CONTAINER.bash
    sde-reset-catkin-workspaces
    ```

## ⚙️ Configuration

| Variable | Default | Purpose |
| --- | --- | --- |
| `SDE_ROBOT_EXTENSIONS` | Empty | Folder names of the active extensions in `extensions/`, separated by spaces, in the order their workspaces build |
| `SDE_DOCKER_REGISTRY` | `registry.gitlab.com/coarobo/sde` | Registry where the base and platform images are pulled from and pushed to |

A platform image that the registry does not hold, such as the image of a private platform, is built locally by `BUILD-DOCKER-IMAGE.bash`, which falls back to a build when the pull fails.
Set `SDE_DOCKER_REGISTRY` in `.env.custom` to use a registry of your own.

## 🛣️ What Comes Next

The rest of [#38](https://gitlab.com/coarobo/SDE/-/issues/38) builds on these rules:

- Setups, which pin one platform, its devices, and its extensions in a `.repos` file for `vcstool`, and which `SWITCH-ROBOT-PLATFORM.bash` clones and selects in one command.
- Docker layers of devices and extensions between the platform image and the user overlay.
- `tmux` sessions built from the panes each part declares, in place of Terminator.
