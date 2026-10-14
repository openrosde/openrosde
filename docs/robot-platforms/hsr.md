# HSR

Platform-specific documentation for the [Toyota HSR (Human Support Robot)](https://www.toyota-global.com/innovation/partner_robot/family_2.html) within OpenRoSDE.

## 🔗 External Resources

- HSR project on GitHub: [https://github.com/hsr-project](https://github.com/hsr-project)
- WRS Docker reference: [https://github.com/hsr-project/tmc_wrs_docker](https://github.com/hsr-project/tmc_wrs_docker)
- Binary Docker image: [`ghcr.io/hsr-project/tmc_wrs_binary:noetic-latest`](https://github.com/hsr-project/tmc_wrs_docker/pkgs/container/tmc_wrs_binary)

## ⚠️ Hybrid Distribution Model

The HSR platform image in OpenRoSDE is built as a **multi-stage Docker image** that combines two BSD 3-Clause Clear Licensed sources both publicly distributed by Toyota Motor Corporation:

- **Stage 1 (`hsr_binary`):** `ghcr.io/hsr-project/tmc_wrs_binary:noetic-latest`, the WRS competition binary image that ships the full HSR ROS Noetic stack (URDF, SRDF, MoveIt configuration, navigation stack, controllers, all `tmc_*` and `hsrb_*` packages, and the WRS competition worlds).
- **Stage 2 (main):** the OpenRoSDE base image (`openrosde-base`), which provides CUDA, ROS Noetic desktop-full, Terminator, FlexBE, `wmctrl`, and the OpenRoSDE helper scripts.

The build COPY-merges the additional `/opt/ros/noetic/` entries (HSR-specific packages built with `--cmake-args -DCMAKE_INSTALL_PREFIX=/opt/ros/noetic`) from the binary image into the OpenRoSDE base without clobbering any existing files. Sourcing `/opt/ros/noetic/setup.bash` is sufficient — no separate workspace overlay is needed.

This approach was chosen because:

- Toyota has migrated the source-code HSR stack (`hsrb_launch`, `hsrb_common`, `hsrb_moveit`, `hsrb_rosnav`, `tmc_gazebo`) to ROS 2 Humble.
- The corresponding ROS Noetic source remains on the private `git.hsr.io` GitLab and is not publicly accessible.
- The binary image is the only practical way to obtain a functional HSR Noetic simulator and is freely distributed by Toyota under the BSD 3-Clause Clear License.

## 🔩 Hardware Overview

The Toyota HSR platform consists of the following components:

- **Robot:** [Toyota HSR (Human Support Robot)](https://www.toyota-global.com/innovation/partner_robot/family_2.html) mobile manipulator.
- **On-board computer:** Intel-based computer running Ubuntu with ROS.
- **Arm:** 5-DOF arm with parallel-jaw gripper and suction.
- **Base:** Omnidirectional base with two laser range finders.
- **Camera:** Head-mounted RGB-D camera.

## ⚙️ Platform Configuration

Switch to the Toyota HSR platform:

```shell
bash ./SWITCH-ROBOT-PLATFORM.bash hsr
```

> [!NOTE]
> The default `.env` configuration is pre-configured for the Robotis TurtleBot3 platform.
> Run `SWITCH-ROBOT-PLATFORM.bash hsr` to create the `.env.custom` file with the Toyota HSR configuration.

> [!IMPORTANT]
> The first build of `hsr-devel` downloads `ghcr.io/hsr-project/tmc_wrs_binary:noetic-latest` (several GB).
> Ensure a stable, high-speed internet connection.

## 🌐 Network Configuration

The Toyota HSR robot uses mDNS host names for network discovery.

| Device | Host Name | Notes |
| --- | --- | --- |
| Toyota HSR | `hsrb.local` | Default mDNS hostname |

To connect to the real robot, update the ROS master hostname in `.env.custom`:

```shell
OPENROSDE_ROS_MASTER_HOSTNAME=hsrb.local
```

## 🚀 Gazebo Simulation

Start the Toyota HSR Gazebo simulation using the predefined Terminator layout:

```shell
bash ./RUN-TERMINATOR-TERMINAL.bash #[docker-project] default-gazebo
```

Or start the launch files manually in the Docker container:

```shell
roslaunch openrosde_hsr_launch hsr_bringup_default_gazebo.launch
roslaunch openrosde_hsr_launch hsr_rviz_default.launch
```

> [!NOTE]
> `hsr_bringup_default_gazebo.launch` spawns the HSR-B in the WRS apartment world with all controllers loaded.
> Start MoveIt and the navigation stack separately via the Terminator panes using `hsr_moveit_default.launch` and `hsr_navigation_default_gazebo.launch`.
> Click **2D Nav Goal** in RViz to send autonomous navigation goals.

## 🕐 Clock Synchronization

Clock synchronization is not configured for the Toyota HSR.

## 🤖 Real Robot Operation

Real robot bringup is not configured: Toyota's `tmc_wrs_binary` image only ships the simulation stack.
The real HSR driver is hosted on the private `git.hsr.io` GitLab and requires a Toyota HSR Community account.

## 📋 Launch Files Reference

The following launch files are available for the Toyota HSR platform (package: `openrosde_hsr_launch`):

| Launch File | Description |
| --- | --- |
| `hsr_bringup_default_gazebo.launch` | Spawns the HSR in the WRS 2020 Gazebo world with open-source controllers. |
| `hsr_rviz_default.launch` | RViz with the OpenRoSDE-owned `config/rviz/hsr_rviz_default.rviz` layout. |
| `hsr_moveit_default.launch` | MoveIt `move_group` for arm motion planning. |
| `hsr_navigation_default_gazebo.launch` | Navigation stack (AMCL + `move_base`) with the WRS 2020 pre-built map. |

## 🧪 FlexBE Behavior

The `openrosde_hsr_flexbe_behaviors` package provides an example behavior that loops navigation between two waypoints in the WRS 2020 apartment world using `MoveBaseState` and `WaitState`.

To start the FlexBE behavior engine and app:

```shell
roslaunch openrosde_launch flexbe_app_default.launch
```

Load the `HSR Example Behavior` behavior in the FlexBE App and press **Start**.

## 📜 Third-Party Software and Licensing

OpenRoSDE itself is distributed under the [MIT License](../../LICENSE).
The HSR platform image bundles third-party software whose licenses apply to the resulting Docker image:

| Component | Source | License |
| --- | --- | --- |
| `tmc_wrs_binary` (HSR ROS Noetic stack: URDF, SRDF, MoveIt, navigation, controllers, all `hsrb_*` and `tmc_*` packages, WRS apartment world) | [`ghcr.io/hsr-project/tmc_wrs_binary`](https://github.com/hsr-project/tmc_wrs_docker) | [BSD 3-Clause Clear](https://spdx.org/licenses/BSD-3-Clause-Clear.html) (Toyota Motor Corporation) |
| `tmc_wrs_docker` reference (build recipes and helpers) | [hsr-project/tmc_wrs_docker](https://github.com/hsr-project/tmc_wrs_docker) | [BSD 3-Clause Clear](https://spdx.org/licenses/BSD-3-Clause-Clear.html) (Toyota Motor Corporation) |
| `openrosde_hsr_launch`, `openrosde_hsr_behaviors` (this repository) | [coarobo/SDE](https://gitlab.com/coarobo/SDE) | [MIT](../../LICENSE) (Coarobo GK) |

> [!IMPORTANT]
> The corresponding ROS Noetic source code for the HSR stack is hosted on the private [`git.hsr.io`](https://git.hsr.io/) GitLab and is intentionally not vendored in this repository.
> Access requires a Toyota HSR Community account.
> The publicly distributed binary image is the only practical way to obtain a functional HSR Noetic simulator and is sufficient for the OpenRoSDE workflow.
