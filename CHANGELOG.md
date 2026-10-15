# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- The entry scripts stop with the commands that clone a platform into `extensions/` when `.env` or `.env.custom` selects a platform that neither the core nor a clone declares, as in a fresh clone of the core, with the repository of a public platform from `OPENROSDE_PLATFORM_REPOSITORY_URL` (#40).
- The CI reaches the Fetch through `rosbridge` alone in Gazebo, with no network, in the test job of the setup `fetch`: `ci/check-rosbridge.bash` of `openrosde-platform-fetch` checks `/clock`, `/joint_states`, `/tf`, `/tf_static`, and the relay from `fetch_ee_cmd_vel` to `/arm_controller/cartesian_twist/command` with a WebSocket client on port `9090` (#40).
- `rosbridge_server_default.launch` starts the ROS# file service `/file_server/get_file`, built from source in the base image and patched to serve only meshes, textures, and their GLB files up to 12,000,000 bytes, so that a client of `rosbridge` loads the model of any robot from `robot_description`, as `docs/robot-models.md` describes (#41).
- The converter image `openrosde-mesh2glb` turns every COLLADA, STL, and OBJ mesh into a GLB beside it, named by appending `.glb`, for the meshes of the images when the user overlay builds and for those of the workspaces with `scripts/generate-mesh-glbs.bash`, which `BUILD-DOCKER-IMAGE.bash` runs, and GLBs are never committed or published (#41).
- The CI checks that the converter gives the same bytes twice and valid GLBs, and every test job of a setup checks the file service through `rosbridge` with the GLBs of its container (#41).
- The CI tests every setup it finds, in the core and in the public extensions that `gitlab-ci/extensions.repos` pins and `gitlab-ci/clone-extensions.bash` clones anonymously, with one test job per setup that builds its Docker layers and its Catkin workspaces in the image of its platform, and a test job of the core alone in the base image (#38).
- `gitlab-ci/clone-extensions.bash` refuses a file of extensions in another layout than its own, rather than reading no name from it and testing nothing (#38).
- A public extension tests one of its branches against the core by triggering a pipeline with `OPENROSDE_CI_EXTENSION_OVERRIDE=<name>=<branch>@<commit>`, which tests only the setups that activate it and never publishes, and `OPENROSDE_CI_EXTRA_EXTENSIONS` adds extensions to every setup that the CI tests (#38).
- `gitlab-ci/check-launch-files.bash` fails when two panes of one layout start a node of the same name, which `roslaunch --nodes` lists without starting it, unless `gitlab-ci/allowed-duplicate-nodes.txt` or `ci/allowed-duplicate-nodes.txt` of an active extension allows it, for some panes or for any, as the core does for the mapping and navigation panes of the TurtleBot3, which a session runs one at a time (#38).
- `check-scripts-job` runs `gitlab-ci/check-no-motion.bash`, which fails on any `roslaunch` beyond `--files`, `--nodes`, or `--dump-params`, and on any `rosrun`, `rostopic pub`, or `rosservice call`, in the scripts that the CI runs, apart from the simulations that an allowlist names, even after a path, and with no option read from a trailing comment, and every test job needs it (#38).
- The CI runs `ci/check-in-container.bash` of every active extension in the container of the setup, after disconnecting it from every network (#38).
- Tag pipelines publish the images of a release as `vX.Y.Z`, which a setup can pull with `OPENROSDE_DOCKER_IMAGE_TAG` (#38).
- `scripts/load-openrosde-settings.bash` loads `.env`, `.env.custom`, and the paths of the extensions with every variable exported, for the shell of the container and for the CI scripts that run in it (#38).
- `OPENROSDE_DOCKER_BUILD_FALLBACK` sets which images `BUILD-DOCKER-IMAGE.bash` builds locally when their pull fails: `true` for the base and platform images as before, `platform` for the platform image alone, such as a private platform, or `false` for neither, so that a CI job fails rather than building the base image for hours (#38).
- `scripts/build-extension-layers.bash` builds the Docker layers of the active extensions on the parent image it is given, for `BUILD-DOCKER-IMAGE.bash` and for a CI job alike (#38).
- A setup template may pin the version of the core it was tested with, `OPENROSDE_CORE_VERSION`, as a release tag or a branch, and `SWITCH-ROBOT-SETUP.bash` warns, with the `git checkout` command, when the core is checked out at another version (#38).
- `OPENROSDE_QUIET=true` leaves out the list of every `OPENROSDE_*` variable that the entry scripts print, as a CI job needs (#38).
- `tests/suites/test-terminator-parity.bash` checks that every layout of a Terminator config of the core runs the same launch files and arguments as the `tmux` panes of that layout, and that every config holds a layout named after its platform (#38).
- Parts: an extension of a company holds the units of several robots in `parts/<part>/`, each with the layout of the core, whose templates are listed like those of an extension, whose patches `scripts/update-git-submodules.bash` applies, and which `OPENROSDE_ROBOT_EXTENSIONS` activates by name, with an error when no folder or several folders hold that name (#38).
- `tests/run.bash` runs the test suites of the loader and the entry scripts in a Debian container with no network, on scratch copies of the repository with every outside command stubbed (#38).
- Extensions: a platform, a device, or other packages cloned from a repository of their own into `extensions/`, public or private, whose files `scripts/load-extension-paths.bash` finds by name on the host and inside the container, with `OPENROSDE_ROBOT_EXTENSIONS` naming the active ones and `docs/extensions.md` as the guide (#38).
- Setups: a template `env/<setup>.env` that declares `OPENROSDE_ROBOT_SETUP=<setup>` with its platform and extensions, in the core or in an extension, which `SWITCH-ROBOT-SETUP.bash` selects after cloning the repositories of its `env/<setup>.repos` with `vcstool`, and whose own files and scripts take precedence over those of the platform (#38).
- `SETUP-DEVEL-MACHINE.bash` installs `vcstool` (#38).
- `RUN-TMUX-SESSION.bash` runs the terminals in a `tmux` session, with the mouse on and one window per group of panes, which the platform, the active extensions, the setup, and the core declare in `tmux/<name>.panes`, and `SETUP-DEVEL-MACHINE.bash` installs `tmux` (#38).
- The CI checks that every launch entry point of the `tmux` sessions of each platform resolves with `roslaunch --files`, which starts no node, after its Catkin workspaces build (#30).
- A new CI pipeline: a parent pipeline generates a child pipeline of one image job and one test job per platform found by name, each image built only when the hash of its folders changed and otherwise retagged on the registry, the Catkin workspaces of every platform built inside its image, and the images published as `dev` and `main` from those branches (#37).
- The CI hands every image through the registry with Docker-in-Docker over TLS and lets every artifact expire, so the same pipeline runs on a self-managed runner and on the instance runners of GitLab.com, which `OPENROSDE_CI_RUNNER_TAG` selects (#37).
- `OPENROSDE_DOCKER_IMAGE_TAG` selects the `main` or `dev` images, and derives the tag from the branch by default (#37).
- Docker layers of extensions: every `docker/<name>-devel/Dockerfile` of an active extension that is not a platform builds locally between the platform image and the user overlay, in the order of the active folders (#38).
- `OPENROSDE_DOCKER_REGISTRY` sets the registry of the base and platform images in `.env`, in place of `registry.gitlab.com/coarobo/sde` written in the Docker Compose file and the push script (#38).
- `color_width`, `color_height`, `color_fps`, `depth_width`, `depth_height`, `depth_fps`, and `align_depth` arguments on `realsense_camera_default_realworld.launch`, applied to both UR5e cameras and kept at the upstream `-1` by default, with `align_depth` kept at the upstream `false`.
- Light streams of both UR5e cameras for Coarobo Viewport in the user overlay (`viewport_streams_ur5e.launch`): a colorized JPEG of each depth image from `depth_colorizer_node.py`, and each point cloud throttled to 5 Hz on a 2 cm voxel grid, plus the FastSAM overlay projected in 3D on the aligned depth, started with FastSAM by `viewport_demo_ur5e.launch`.
- FastSAM segmentation in the user overlay (`openrosde_user_launch`), from the `add_segmentation` branch by Hajime Teruoka, with a JPEG copy of the overlay for Coarobo Viewport and `seg_fastsam_ur5e_cameras.launch` for both UR5e cameras, for the ATR Open House 2026 demo.
- `input_source:=spacemouse_viewport` on the UR5e teleop launch files starts the 3Dconnexion SpaceMouse and the Coarobo Viewport bridges together, with the Viewport bridge silent once idle (`stop_publishing_when_idle`), so either input can drive MoveIt Servo during a demo.
- `input_source:=spacemouse_viewport_sightline` on the UR5e teleop launch files adds the Coarobo Sightline nodes to those two bridges, on the `flange` end effector frame, so the 3Dconnexion SpaceMouse, Coarobo Viewport, and Coarobo Sightline can each drive MoveIt Servo while in use.
- UR5e documentation warns that the 3Dconnexion Universal Receiver of the 3Dconnexion SpaceMouse only works from a USB 2 port of the Ubuntu development machine.
- UR5e documentation warns that the two Intel RealSense cameras must sit on two different USB host controllers of the Ubuntu development machine, with a command that shows the controller behind each camera.

### Changed

- `gitlab-ci/extensions.repos` pins `openrosde-platform-turtlebot3`, `openrosde-platform-fetch`, `openrosde-platform-sciurus17`, `openrosde-platform-cobotta`, and `openrosde-platform-hsr` at a commit of their `main`, so the CI clones them, reuses the published images of their byte-identical Dockerfiles by source hash, and tests and publishes them under the same names as before (#40).
- `.env` keeps `turtlebot3` as the default platform, which a fresh clone of the core clones into `extensions/` first, as the Quick Start of `README.md` shows (#40).
- `RUN-TERMINATOR-TERMINAL.bash` creates `terminator/`, which a clone of the core lacks once no platform of the core has a Terminator layout (#40).
- The relay of `openrosde_fetch_teleop` starts from `fetch_teleop.launch` itself, with the same node, arguments, and parameters, in place of `fetch_teleop_sightline.launch`, and `fetch_teleop_default.launch`, `fetch_ee_cmd_vel`, and `/arm_controller/cartesian_twist/command` keep their names (#40).
- The line of `gitlab-ci/allowed-duplicate-nodes.txt` for the TurtleBot3 moves to `ci/allowed-duplicate-nodes.txt` of its platform repository (#40).
- The test suites of `tests/` write the platforms they need in their scratch copy, and check the canonical platforms that a developer cloned into `extensions/`, including their Terminator layouts against their panes (#40).
- `catkin build` takes its parallel jobs from `OPENROSDE_BUILD_JOBS` when it is set, and the CI sets it from the `JOB_CPUS` of a self-managed runner, so a job no longer starts a compiler for every CPU of the machine inside its share (#37).
- `gitlab-ci/build-ci-image.bash` takes the build context of the image, builds a platform from the folder that holds it, and hashes each source folder in the Git repository that holds it, which gives the folders of the core the same hash as before (#38).
- The images publish only from a protected branch or tag, under its own name, in a pipeline that a push or a person on the web started, so a merge request, a schedule, a pipeline of another project, or a pipeline that tests an extension at another version never publishes `dev` (#38).
- `gitlab-ci/test-catkin-workspaces.bash` and `gitlab-ci/check-launch-files.bash` take a setup in place of a platform, and the test job reads its images from `OPENROSDE_CI_IMAGE_REGISTRY` with the tag `OPENROSDE_CI_IMAGE_TAG`, the images of the pipeline by default, which a pipeline of another project sets to published images, such as `registry.gitlab.com/coarobo/sde` and `v3.0.0` (#38).
- `gitlab-ci/test-catkin-workspaces.bash` refuses outside the CI to replace an existing `.env.custom`, which holds the setup that a developer selected (#38).
- The shell of the container loads its settings with `scripts/load-openrosde-settings.bash`, so every script it runs, such as `reset-catkin-workspaces.bash`, reads the same platform, setup, and extensions, and the base image is built again (#38).
- The Docker layers of the extensions and the user overlay are tagged `openrosde-local/<setup>/<name>-devel:latest` and `openrosde-local/<setup>/user-devel:latest`, with the setup in lowercase, in place of the name of the registry, so two setups that share a device no longer overwrite each other's layer, and the next `bash ./BUILD-DOCKER-IMAGE.bash` builds them under their new names, after which `docker image rm` can remove the old `registry.gitlab.com/coarobo/sde/user-devel:latest` (#38).
- `scripts/load-openrosde-env.bash` reads the platforms that the templates declare rather than running `scripts/list-robot-platforms.bash`, whose warnings every entry script printed (#38).
- The panes of a setup, `tmux/<setup>.panes`, replace those of its platform, as its Terminator layout does, and an active extension no longer adds a Docker Compose overlay or a pane file named after a platform or a setup that is not active (#38).
- `SWITCH-ROBOT-SETUP.bash` fails, and leaves the setup unchanged, when its platform or an extension it lists is still missing after `vcs import`, and warns about a clone whose `origin` points to another repository than the `.repos` file, over HTTPS and SSH alike, with a `git remote set-url` command that would point it there (#38).
- `scripts/list-robot-platforms.bash` and `scripts/list-robot-setups.bash` warn when two templates declare the same name, and name with an error a template whose `OPENROSDE_ROBOT_PLATFORM=` or `OPENROSDE_ROBOT_SETUP=` line is quoted or carries a comment, which OpenRoSDE never reads (#38).
- The pipeline of `dev` or `main` after a merge reuses the images that the pipeline of the merged branch built, which it finds from the message of the merge commit, rather than building them again (#37).
- **Breaking:** the SDE becomes OpenRoSDE in every name: `OPENROSDE_*` variables in place of `SDE_*`, `openrosde_*` ROS packages in `ros/openrosde_catkin_ws/` in place of `sde_*`, the `openrosde-base` image, the `openrosde` Docker Compose service and container, `openrosde-*` shell functions, the `OpenRoSDE (<session>)` terminal title, and `/root/OpenRoSDE` inside the container, so every image and container is built again, packages of the user overlay that depend on a renamed package take its new name, and a `.env.custom` with the old names keeps working with a warning that says how to rename them.
- `SWITCH-ROBOT-PLATFORM.bash` switches to the default setup of the platform, its own template, which now declares `OPENROSDE_ROBOT_SETUP=<platform>`, and a `.env.custom` written earlier keeps its platform files (#38).
- OpenRoSDE finds the platforms by name: `scripts/list-robot-platforms.bash` lists every `env/<platform>.env` that declares `OPENROSDE_ROBOT_PLATFORM=<platform>`, and `SWITCH-ROBOT-PLATFORM.bash`, `BUILD-DOCKER-IMAGE.bash`, and `gitlab-ci/PUSH-DOCKER-IMAGE.bash` use it in place of their written lists (#38).
- The platform-specific parts of `BRINGUP-ROS-ROBOT.bash`, `RESTART-CHRONY-SERVICE.bash`, and `docker/openrosde-base/scripts/initialize-bash-shell.bash` move to optional scripts in `scripts/<platform>/`, and the launch package is derived as `openrosde_<platform>_launch` (#38).
- The Catkin workspaces build and source in the order the platform and the active extensions give them, and `openrosde-fix-permission-issues` returns the files of every one of them to the host user, the user workspace included (#38).
- `scripts/apply-submodule-patches.bash` takes the root directory of the repository whose patches it applies, so that every extension patches its own Git submodules (#38).
- `scripts/load-openrosde-env.bash` exports every `OPENROSDE_*` variable in place of a list per platform, so a new variable of a platform or of the user overlay needs no change of the loader (#38).
- The UR5e bringup and MoveIt launch files load the robot description, the SRDF, and the calibration from the ROS package that `OPENROSDE_UR5E_DESCRIPTION_PACKAGE` names, `openrosde_ur5e_launch` by default, so that a setup brings its own, and the calibration moves to `config/ur5e/ur5e_calibration.yaml` (#39).
- The UR5e xacro files read the pose of the external camera from the `OPENROSDE_UR5E_EXTERNAL_CAMERA_*` variables themselves, in place of `external_camera_*` launch arguments, which the real robot bringup never passed on (#39).
- `CONTRIBUTING.md` describes the work on `dev` with `<type>/<slug>` branches, releases merged from `dev` into `main`, and the labels of the `coarobo` group, as `AGENTS.md` does.
- `AGENTS.md` describes the approved split of OpenRoSDE into the OpenRoSDE core and its extensions, the rules that hold during it, the interfaces that Coarobo Sightline and Coarobo Viewport use, the work on `dev`, and the labels of the `coarobo` group, and corrects the Terminator pane numbers, the submodules, and the patches.
- UR5e documentation cites the camera adapter from PickNik Robotics in the BSD-3-Clause `picknik_accessories` repository, whose `picknik_ur5_realsense_camera_adapter_rev2.STL` OpenRoSDE mesh matches byte for byte, with that license next to the mesh, in place of the GrabCAD page, whose terms forbid redistribution.
- The `default-realworld` UR5e Terminator layout preloads the Coarobo Viewport demo: the teleop with `input_source:=spacemouse_viewport_sightline`, the cameras at 640 by 480 and 15 fps with the depth aligned to color, and `openrosde_user_launch:viewport_demo_ur5e.launch` in Number 9, while the `default-gazebo` layout preloads the teleop with `input_source:=spacemouse`.
- The default pose of the UR5e external camera matches the Coarobo setup measured on 2026-10-07 (`x=-0.10`, `y=0.35`, `z=0.10`, level, yaw `-2.35619`) in `env/ur5e.env`, the launch file fallbacks, the xacro defaults, and the documentation.

- `BUILD-DOCKER-IMAGE.bash` pulls the `main` or `dev` images instead of `latest`, which the registry no longer keeps (#37).

### Deprecated

- `RUN-TERMINATOR-TERMINAL.bash` and `terminator/`, which `RUN-TMUX-SESSION.bash` and `tmux/` replace once the `tmux` sessions have run on a real robot (#38).

### Removed

- **Breaking:** the platforms `turtlebot3`, `fetch`, `sciurus17`, `cobotta`, and `hsr` leave the core for repositories of their own under the Apache License 2.0, `https://gitlab.com/coarobo/openrosde/openrosde-platform-<platform>`, with their templates, Dockerfiles, Docker Compose overlays, Catkin workspaces, Git submodules, patches, panes, Terminator layouts, scripts, and documentation (#40).
  Migration: on a machine that runs one of them, clone its repository into `extensions/` before pulling the core, such as `git clone https://gitlab.com/coarobo/openrosde/openrosde-platform-fetch.git extensions/openrosde-platform-fetch`, then run `bash ./scripts/update-git-submodules.bash`, and a `.env.custom` that selects the platform keeps working.
- `gitlab-ci/PUSH-DOCKER-IMAGE.bash`, `gitlab-ci/SETUP-GITLAB-RUNNER.bash`, and the `gitlab-ci` mode of `BUILD-DOCKER-IMAGE.bash`, since the CI publishes the images itself, and the runner is set up with the infrastructure of whoever runs the CI (#37).

### Fixed

- `gitlab-ci/check-launch-files.bash` checks the pane files that `RUN-TMUX-SESSION.bash` opens for the setup, and fails when neither the setup nor its platform has one, rather than checking the panes of the core alone and passing, as it did for a platform held by an extension (#38).
- `gitlab-ci/check-launch-files.bash` takes the launch package of the panes that name none from `OPENROSDE_LAUNCH_PACKAGE`, which the shell configuration of a setup or a platform may change, as the shell of the container does (#38).
- `gitlab-ci/build-ci-image.bash` fails when a source folder is missing or not committed, rather than hashing it as a constant and reusing an outdated image for ever (#38).
- The shell of the container no longer announces a newer image, nor prints a Git error, when the repository of the platform does not hold the commit embedded in the image, as for a platform outside the core (#38).
- The image of a platform held by an extension or a part builds from the folder of that platform, as the Docker layers do, so the `COPY` instructions of its Dockerfile read from there rather than from the core (#38).
- A clone that is not active no longer supplies the Docker Compose overlay, the panes, the scripts, or the Terminator layout of the active platform or setup, since a file named after the setup now comes from the folder of the setup, and a file named after the platform from the folder of the platform, then the core (#38).
- `build-catkin-workspaces.bash` ends with a failure status when a workspace fails to build, which `reset-catkin-workspaces.bash` passes on, so the CI and `openrosde-reset-catkin-workspaces` no longer report success over a broken package (#30).
- `SWITCH-ROBOT-PLATFORM.bash` no longer offers the user overlay template `user` as a platform (#38).
- `openrosde_launch:ros_tcp_endpoint_default.launch` runs the Unity ROS TCP Endpoint through `ros_tcp_endpoint_server.py`, which adds the `__remove_subscriber`, `__remove_publisher`, `__remove_ros_service`, and `__remove_unity_service` system commands missing from the ROS 1 endpoint `0.7.0`, so Coarobo Sightline no longer loses its connection for two seconds when it drops its last subscription on a topic, as when a sensor layer is turned off or an alignment starts.
- UR5e documentation and configuration comments name the wrist camera an Intel RealSense D435, as mounted on the robot, instead of a D435i.
- `gitlab-ci/gitlab-ci.yml` pins the Docker CLI image and the Docker-in-Docker service to `29.8.1` instead of `latest`, as GitLab recommends.
- The `default-gazebo` `tmux` sessions of `fetch`, `sciurus17`, `cobotta`, `hsr`, and `ur5e` open the MoveIt pane that their Terminator layouts run as Number 6, so the CI now also resolves `sciurus17_moveit_default_gazebo.launch`, `cobotta_moveit_default_gazebo.launch`, and `ur5e_moveit_default_gazebo.launch` (#38).
- The example `env/<setup>.repos` of `docs/extensions.md` clones the extensions from `https://gitlab.com/coarobo/openrosde/`, a namespace that the project controls, rather than from a GitHub organization that does not exist and that anyone could register, and says that its versions only show the format (#38).

### Security

- The entry scripts print `<redacted>` in place of the value of every `OPENROSDE_*` variable whose name holds `PASSWORD`, `TOKEN`, or `SECRET`, so a credential of a setup reaches no terminal recording or job log (#38).
- No `docker push` can publish a local Docker layer or the user overlay any more, since their names no longer carry the name of the public registry, where one push of a maintainer logged in to it would have published a private layer (#38).
- `BUILD-DOCKER-IMAGE.bash` no longer logs in to the GitLab registry with a read-only deploy token written in the script, since the registry of the public project serves its images to anyone, and that token is revoked.

## [2.12.0] - 2026-07-09

### Added

- Coarobo Sightline teleop input for the UR5e: `input_source:=sightline` on the teleop wrappers starts MoveIt Servo for the headset with the end effector frame switched to `onrobot_rg2_base_link`, the OnRobot RG-2 gripper action interface on `/gripper_controller/gripper_action`, and the relayed wrist camera streams (`/wrist_camera/depth/color/points_downsampled` at 5 Hz on a 2 cm voxel grid and `/wrist_camera/color/image_raw/compressed_throttled` at 10 Hz).
- `sde_fetch_teleop` package for Fetch end effector teleoperation from Coarobo Sightline, bridging the headset twist commands to the Fetch Cartesian twist controller.
- `ros_tcp_endpoint` submodule with `sde_launch:ros_tcp_endpoint_default.launch` and a dedicated terminal in the Terminator layouts, so the headset connects on port `10000`.
- Launch argument forwarding through `RUN-DOCKER-CONTAINER.bash` and `run-roslaunch-repeatedly.bash`: `arg:=value` tokens after the launch file are passed to `roslaunch` as is, so a Terminator terminal can override a launch argument without modifying the launch file itself.
- TF frames documentation for the UR5e platform.

### Changed

- The UR5e Terminator layouts preload the teleop terminals with `input_source:=sightline`, while the launch file default remains `spacemouse`.
- Reorganized `sde_fetch_teleop` and `sde_ur5e_teleop` for the Coarobo Sightline integration.

### Fixed

- The MoveIt Servo configs tolerate brief teleop command gaps, with a raised incoming command timeout and low latency mode enabled.
- The real world teleop wrapper defaults back to trajectory control, since the earlier trajectory glitches came from headset side time stamping that Coarobo Sightline now performs in the ROS graph time. Velocity mode stays available through the `controller_mode` argument.

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
