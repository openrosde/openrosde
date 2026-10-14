# User Overlay

[[_TOC_]]

The **user overlay** is Layer 3 of the OpenRoSDE image stack:

- **Layer 1** — `openrosde-base`: shared Ubuntu 20.04 / ROS Noetic / Gazebo / FlexBE toolchain, built once and shared by all platforms.
- **Layer 2** — `<platform>-devel`: robot-specific packages for the platform selected by `OPENROSDE_ROBOT_PLATFORM`, pulled from the registry.
- **Layer 3** — `user-devel`: your customization layer, always built locally on top of Layer 2.

```
openrosde-base (L1)  ->  <platform>-devel (L2)  ->  user-devel (L3, this layer)
```

It lets you add your own ROS packages, system dependencies, environment variables, and Terminator panes without forking OpenRoSDE or touching any platform files.

The user overlay is platform-agnostic: the same overlay rebuilds on top of whichever `OPENROSDE_ROBOT_PLATFORM` you currently have selected.

## 🗂️ File Map

| Path | Purpose |
| --- | --- |
| [docker/user-devel/Dockerfile](../docker/user-devel/Dockerfile) | User Docker layer. Add your `apt-get` / `pip3` dependencies here. |
| [docker/docker-compose-user.yaml](../docker/docker-compose-user.yaml) | User Docker Compose overlay. Add extra `environment:` and `volumes:` here. |
| [ros/user_catkin_ws/](../ros/user_catkin_ws/) | User Catkin workspace. Drop your packages under `src/`. |
| [ros/user_catkin_ws/src/openrosde_user_launch/](../ros/user_catkin_ws/src/openrosde_user_launch/) | Starter launch package with `user_example_default.launch` and a `config/` directory (`rviz/`, `maps/`) for your assets. |
| [ros/user_catkin_ws/src/openrosde_user_behaviors/](../ros/user_catkin_ws/src/openrosde_user_behaviors/) | Starter FlexBE behaviors package with `User Example Behavior`. |
| [env/user.env](../env/user.env) | User overlay environment template (reference only). |

## 🚀 Quick Start

The user overlay ships with working starter content. To verify it on the currently selected platform:

```shell
bash ./BUILD-DOCKER-IMAGE.bash local
bash ./RUN-DOCKER-CONTAINER.bash
```

Inside the container, build all three workspaces:

```shell
openrosde-reset-catkin-workspaces
```

Then check that the user package is discoverable:

```shell
rospack find openrosde_user_launch
roslaunch openrosde_user_launch user_example_default.launch
```

To run your user-overlay launches alongside the full platform stack, use the standard platform Terminator layout:

```shell
bash ./RUN-TERMINATOR-TERMINAL.bash
```

Number 13 (`terminal26`) of every platform layout is pre-wired to `openrosde_user_launch:user_example_default.launch`, so the starter launch runs automatically.
The other spare panes (Numbers 8-12) are free shells where you can run any additional user-overlay command.
To replace the pre-wired entry, edit your platform's `terminator/<platform>.config` and update the `command =` line under `[[[terminal26]]]`.

In the FlexBE App, load and execute `User Example Behavior` to confirm the FlexBE setup.

## ➕ Adding Your Own ROS Package

1. Create your package under [ros/user_catkin_ws/src/](../ros/user_catkin_ws/src/) (you can also `git clone` an existing package there).
2. Inside the container, rebuild the user workspace:

    ```shell
    openrosde-build-catkin-workspaces
    ```

3. Source the new package and run it:

    ```shell
    source ~/SDE/ros/user_catkin_ws/devel/setup.bash
    rosrun <your_package> <your_node>
    ```

The user workspace is automatically:

- Sourced at container startup ([source-catkin-workspaces.bash](../docker/openrosde-base/scripts/source-catkin-workspaces.bash)).
- Rebuilt by `openrosde-reset-catkin-workspaces` ([reset-catkin-workspaces.bash](../docker/openrosde-base/scripts/reset-catkin-workspaces.bash)).
- Added to `ROS_PACKAGE_PATH` ([initialize-bash-shell.bash](../docker/openrosde-base/scripts/initialize-bash-shell.bash)).

## ➕ Adding a System Dependency

1. Edit [docker/user-devel/Dockerfile](../docker/user-devel/Dockerfile) and add your `apt-get install` or `pip3 install` block.
2. Rebuild only the user image (the platform image is reused from cache):

    ```shell
    bash ./BUILD-DOCKER-IMAGE.bash local
    ```

3. Restart the container:

    ```shell
    bash ./RUN-DOCKER-CONTAINER.bash
    ```

## ➕ Adding an Environment Variable

1. Add a default in [.env](../.env) under the `User overlay configuration` section (example: `OPENROSDE_USER_MY_VAR=default-value`).
2. Override it in `.env.custom` if needed.
3. Expose it to the container by editing [docker/docker-compose-user.yaml](../docker/docker-compose-user.yaml):

    ```yaml
    services:
      openrosde:
        environment:
          - OPENROSDE_USER_MY_VAR=${OPENROSDE_USER_MY_VAR}
    ```

[scripts/load-openrosde-env.bash](../scripts/load-openrosde-env.bash) exports every `OPENROSDE_*` variable, so Docker Compose interpolates it with no further step.

## 🆚 User Overlay vs. New Platform

| | User overlay | New platform |
| --- | --- | --- |
| Use case | Project-specific or personal customization | Upstream contribution adding support for a new robot |
| Where it lives | Local fork/branch, not pushed to `coarobo/sde` | Merge request to `coarobo/sde` `main` |
| Files touched | This page only | The step-by-step list in [CONTRIBUTING.md](../CONTRIBUTING.md#adding-a-new-robot-platform) |
| CI/CD | None (built locally) | Full GitLab CI matrix |
| Image registry | Local-only (`user-devel:latest`) | Published by the CI to `registry.gitlab.com/coarobo/sde/<platform>-devel` as `main` and `dev` |

If you need anything beyond the user overlay (custom Gazebo worlds for an existing platform, additional FlexBE behaviors, etc.), keep it in the user overlay first; only promote it to a platform package or a new platform when it stabilizes and is ready to be shared upstream.
