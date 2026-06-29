# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.11.0] - 2026-06-29

### Added

- Coarobo Viewport teleop input for the UR5e, bridging `/cmd_vel` (`geometry_msgs/Twist`) to MoveIt Servo with per-axis exponential moving average smoothing and input-timeout deceleration (`ur5e_moveit_servo_viewport.py`, `ur5e_teleop_viewport.launch`) (!17).
- `input_source` argument on `ur5e_teleop.launch` and the `sde_ur5e_launch` teleop wrappers to select `spacemouse` (3Dconnexion SpaceMouse) or `viewport` (Coarobo Viewport panel), starting exactly one input bridge so the two never contend for the shared MoveIt Servo command topic (!17).

### Changed

- Reorganized and renamed the `sde_ur5e_teleop` launch files and scripts to a consistent `ur5e_<subsystem>_<qualifier>` scheme (`ur5e_teleop_spacenav_node.launch`, `ur5e_teleop_viewport.launch`, `ur5e_moveit_servo_spacenav_node.py`, `ur5e_moveit_servo_viewport.py`, `ur5e_onrobot_rg_control_spacenav_node.py`, `ur5e_controller_manager_switch.py`, `ur5e_spacenavd_daemon.bash`) (!17).
- Restructured the `sde_ur5e_teleop` README into mirrored SpaceMouse and Coarobo Viewport sections and standardized the human-facing device name to SpaceMouse (!17).

### Fixed

- SpaceMouse `spacenav_node` driver startup race: the driver is now started with `respawn` and `spacenavd` is started before MoveIt Servo, so the driver reliably connects on a cold start instead of exiting with "Could not open the space navigator device" (!17).
- `frame_id` default in the SpaceMouse bridge launch aligned to `base_link`, matching the rest of the teleop stack and its documentation (!17).

## [2.10.0] - 2026-05-08

### Added

- Dual Intel RealSense D435i camera support for the UR5e platform: wrist-mounted and external cameras integrated into URDF (Gazebo and real-world), with environment variables `SDE_UR5E_WRIST_CAMERA_SERIAL_NO`, `SDE_UR5E_EXTERNAL_CAMERA_SERIAL_NO`, `SDE_UR5E_ENABLE_EXTERNAL_CAMERA`, and external camera pose `SDE_UR5E_EXTERNAL_CAMERA_X/Y/Z/ROLL/PITCH/YAW` (!16).

### Fixed

- Duplicate `<link name="world"/>` in `onrobot_rg2.xacro` removed via a Git submodule patch, eliminating a TF warning at bringup (!16).
- MoveIt Servo collision proximity thresholds tightened to prevent unsafe high-velocity arm motions (!16).
- `RUN-TERMINATOR-TERMINAL.bash` layout argument now accepts the user-facing form (e.g. `default-gazebo`) and prepends `11-` internally (!16).

## [2.9.0] - 2026-04-26

### Added

- User overlay (Layer 3) on top of `<platform>-devel`, with `user-devel` Docker image, `docker/docker-compose-user.yaml`, `ros/user_catkin_ws/` Catkin workspace, and starter packages `sde_user_launch` and `sde_user_behaviors` (!15, closes #29).
- `env/user.env` reference template documenting `SDE_USER_*` variables and the example `SDE_USER_EXAMPLE_VAR` default in every per-platform `env/*.env`.
- `User Example Behavior` FlexBE behavior using `LogState` and `WaitState`, runnable on every platform.
- Standardized Number 13 (`terminal26`) in all platform Terminator layouts pre-wired to `sde_user_launch:user_example_default.launch`.
- `docs/user-overlay.md` user-facing guide and pointer note in `CONTRIBUTING.md` distinguishing the user overlay from adding a new platform.

### Changed

- Split `docker-compose.yaml` into three services: `sde-base` (build-only), `sde-platform` (build-only, `<platform>-devel:latest`), and `sde` (runtime, `user-devel:latest`).
- `BUILD-DOCKER-IMAGE.bash` now always builds the `user-devel` image locally on top of the selected platform image.
- `RUN-DOCKER-CONTAINER.bash` always loads `docker-compose-user.yaml` in addition to the platform overlay.
- `source-catkin-workspaces.bash`, `build-catkin-workspaces.bash`, and `reset-catkin-workspaces.bash` now also handle the user workspace (sourced and built after the platform workspace when present).
- `gitlab-ci/PUSH-DOCKER-IMAGE.bash` documents that the `user-devel` image is intentionally never pushed to the registry.

## [2.8.0] - 2026-04-26

### Added

- `CHANGELOG.md` following [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/), back-filled from `v0.0.0` through `v2.7.0` (!14, closes #28).
- `## GitLab Project Organization` section in `CONTRIBUTING.md` documenting branches, merge requests, issues, milestones, changelog, and releases.
- `## GitLab Workflow` section in `AGENTS.md` mirroring `CONTRIBUTING.md` for AI coding agents.

### Changed

- Adopt [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) with platform-only scopes for all commit messages and merge request titles (!14, closes #13).
- Document the merge-commit (no-squash) policy and the canonical merge request description structure (Summary, Changes, Testing, Related, Changelog).

## [2.7.0] - 2026-04-26

### Added

- Initial support for the Toyota HSR platform, including bringup, navigation, MoveIt, and a custom RViz layout.
- Navigation FlexBE example behavior for HSR.

### Changed

- Decouple HSR launch files between bringup and navigation/MoveIt.
- Enhance window maximization logic with focus management in Terminator.

### Removed

- Unused `hsr_mapping_default.launch` file.

## [2.6.0] - 2026-04-24

### Added

- Initial FlexBE example behaviors for all platforms.
- `rqt` suite launch configuration for improved monitoring.
- Window maximization for RViz, Gazebo, and FlexBE via a new `maximize-app-window` script.

### Changed

- Standardize RViz configurations and launch files across all platforms.
- Standardize FlexBE behavior packages and add per-package READMEs.
- Streamline FlexBE behavior manifests and update launch files for SRDF loading.

### Fixed

- Use proper FlexBE indentation in example behavior state machines.
- Extend retry duration and correct default delay in the `maximize-app-window` script.

## [2.5.0] - 2026-04-22

### Added

- Real-world configuration, model, and description for the UR5e platform.

### Changed

- Standardize Terminator layouts for consistency across all platforms.
- Standardize RViz configurations and launch files across all platforms.
- Standardize UR5e launch files with SDE-specific comments and upstream references.
- Rename UR5e packages and config files for better separation of functions.
- Consolidate Git submodule initialization and patch application into a single script.
- Rename the container initialization Bash function and add a script for sourcing Catkin workspaces.
- Enhance build commands and clarify Docker project usage in scripts.
- Enhance contribution guidelines and document new platform support instructions.

### Fixed

- Update Intel RealSense ROS repository links to the correct source after migration to RealSenseAI.

## [2.4.0] - 2026-04-21

### Added

- Initial support for the Denso COBOTTA platform.
- Patches for Collada comment fixes in Denso COBOTTA models.

### Changed

- Update COBOTTA gripper type defaults and documentation for Gazebo and real robot operation.
- Update COBOTTA gripper PID gains and material properties.

## [2.3.0] - 2026-04-21

### Added

- Initial support for the RT Sciurus17 platform.
- End-effector assembly links and RealSense cameras to the UR5e platform xacro.

### Changed

- Update Sciurus17 launch files for Gazebo and real robot support.
- Clarify GitHub repository links in Fetch platform documentation.

### Fixed

- Define default values for UR5e URDF parameters.

## [2.2.0] - 2026-04-15

### Added

- Initial support for the Fetch platform.
- `RESTART-CHRONY-SERVICE.bash` for resyncing host and robot clocks.

### Changed

- Refactor Fetch and TurtleBot3 launch files to replace navigation with mapping in real-world layouts.
- Format launch files with consistent ROS 1 style.

## [2.1.0] - 2026-04-14

### Added

- `SWITCH-ROBOT-PLATFORM.bash` for switching between active robot platforms.
- Platform-specific Docker Compose overlays for per-platform customization.
- `rosbridge_server_default.launch` in all Terminator layouts.
- `spacenavd` daemon startup script for launch file integration.

### Changed

- Rename Catkin workspace scripts and update documentation for consistency.
- Enhance documentation with emoji headers and clarify project guidelines.
- Update submodule commit reference for `flexbe_generic_states`.

### Fixed

- Use hyphens in container name formatting.

## [2.0.0] - 2026-04-14

### Added

- Multi-platform support driven by the `SDE_ROBOT_PLATFORM` variable.
- Shared `sde-base` Docker image plus per-platform `*-devel` images for TurtleBot3 and UR5e.
- Shared `sde_catkin_ws` workspace alongside per-platform Catkin workspaces.
- Per-platform environment templates (`env/*.env`) and a shared `scripts/load-sde-env.bash` loader.
- `SDE_CONTAINER_ROOT_DIR` variable across scripts and config files.
- Git submodule patch system via `scripts/apply-submodule-patches.bash`.
- WSL 2 and Ubuntu 24.04 LTS host support.
- `AGENTS.md` for coding agent guidelines.

### Changed

- Refactor file structure for multi-platform support.
- Refactor Docker setup, environment loading, and Catkin workspace handling.
- Build shared and platform-specific Catkin workspaces sequentially.
- Rename custom variables with the `SDE_` prefix.
- Replace `SDE_PLATFORM` with `SDE_ROBOT_PLATFORM`.
- Refactor Dockerfiles to use `apt-get clean` for better layer management.
- Update GitLab CI configuration to hide the deploy token.
- Update SDE launch packages and platform-specific documentation for clarity and consistency.
- Improve `coarobo_teleop` package documentation and structure.

### Fixed

- ROS 1 end-of-life issues in scripts.
- Conflicting container issues when switching platforms.
- ROS rotating-key issues on older Docker images.
- Config-file paths in TurtleBot3 launch files.

## [1.3.0] - 2024-08-23

### Added

- `iproute2` and `ping` tools to the Docker image.
- Documentation in scripts.

### Changed

- Rename Docker Compose file extensions to `.yaml`.
- Disable terminal flow control to prevent accidental locking with `Ctrl+s`.

### Fixed

- Trailing `/` issue in scripts.
- `sde-fix-permission-issues` Bash function.

### Removed

- Obsolete terminal configuration.

## [1.2.0] - 2024-08-18

### Added

- FlexBE App and `flexbe_behavior_engine` integration via Git submodules.
- FlexBE behavior package template and example FlexBE behavior for waypoint navigation with TurtleBot3.
- `ignore = dirty` flag on Git submodules.

### Changed

- Move `catkin_ws/` to `ros/catkin_ws/` for better consistency.
- Update FlexBE-related package manifests and READMEs.

### Fixed

- `ros/catkin_ws/` paths in scripts.

## [1.1.0] - 2024-08-17

### Changed

- Slim down the SDE to single-TurtleBot3 support.
- Build the TurtleBot3 Catkin workspace from distributed packages.
- Increase ROS launch file granularity for independent navigation/mapping from bringup.
- Pass environment variables to the Terminator config file at runtime.
- Format XML of ROS launch files.

### Removed

- Multi-TurtleBot3 support files and references.
- All Git submodules.

## [1.0.0] - 2024-08-17

### Added

- ROS network information display when entering the container.
- Bash function to kill all ROS nodes.
- Project/container name passed as the first argument to Terminator.

### Changed

- Upgrade host OS to Ubuntu 22.04 with the latest Docker, Docker Compose, and Nvidia Container Toolkit.
- Upgrade and refactor the Docker base image from `cudagl` to `cuda`.
- Split `docker-compose.yml` to support both CPU and GPU machines using Compose merge.
- Rename launch files with more explicit suffixes.
- Clean up Docker scripts to match the latest version of the Fetch SDE.
- Redirect `python` shebangs to `python3` for compatibility with older ROS packages.
- Add documentation to all Bash scripts run on the host machine.

### Fixed

- Launch files and Terminator/RViz layouts after renaming files.
- Launch files for multi-robot SLAM simulation.

### Removed

- Contribution guidelines (temporary, reintroduced in a later release).

## [0.0.0] - 2023-10-18

### Added

- Initial public release of the SDE: Docker-based ROS Noetic development environment with Gazebo, RViz, and Terminator integration.

[Unreleased]: https://gitlab.com/coarobo/SDE/-/compare/v2.9.0...main
[2.9.0]: https://gitlab.com/coarobo/SDE/-/compare/v2.8.0...v2.9.0
[2.8.0]: https://gitlab.com/coarobo/SDE/-/compare/v2.7.0...v2.8.0
[2.7.0]: https://gitlab.com/coarobo/SDE/-/compare/v2.6.0...v2.7.0
[2.6.0]: https://gitlab.com/coarobo/SDE/-/compare/v2.5.0...v2.6.0
[2.5.0]: https://gitlab.com/coarobo/SDE/-/compare/v2.4.0...v2.5.0
[2.4.0]: https://gitlab.com/coarobo/SDE/-/compare/v2.3.0...v2.4.0
[2.3.0]: https://gitlab.com/coarobo/SDE/-/compare/v2.2.0...v2.3.0
[2.2.0]: https://gitlab.com/coarobo/SDE/-/compare/v2.1.0...v2.2.0
[2.1.0]: https://gitlab.com/coarobo/SDE/-/compare/v2.0.0...v2.1.0
[2.0.0]: https://gitlab.com/coarobo/SDE/-/compare/v1.3.0...v2.0.0
[1.3.0]: https://gitlab.com/coarobo/SDE/-/compare/v1.2.0...v1.3.0
[1.2.0]: https://gitlab.com/coarobo/SDE/-/compare/v1.1.0...v1.2.0
[1.1.0]: https://gitlab.com/coarobo/SDE/-/compare/v1.0.0...v1.1.0
[1.0.0]: https://gitlab.com/coarobo/SDE/-/compare/v0.0.0...v1.0.0
[0.0.0]: https://gitlab.com/coarobo/SDE/-/tags/v0.0.0
