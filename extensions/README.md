# Extensions

This folder holds the extensions of OpenRoSDE, each a Git repository cloned into `extensions/<extension>/`.
Git ignores everything here but this file, so every extension keeps its own history, remote, and license.

An extension shares the layout of the core (`env/`, `docker/`, `ros/`, `scripts/`, `terminator/`, `patches/`, `docs/`), and OpenRoSDE finds its files by name:

- A platform extension holds `env/<platform>.env`, which declares `OPENROSDE_ROBOT_PLATFORM=<platform>`, beside `docker/<platform>-devel/`, `ros/<platform>_catkin_ws/`, and the other files of a platform, so `bash ./SWITCH-ROBOT-PLATFORM.bash <platform>` offers it like a platform of the core.
- A setup extension holds `env/<setup>.env`, which declares `OPENROSDE_ROBOT_SETUP=<setup>` with its platform and extensions, and `env/<setup>.repos`, from which `bash ./SWITCH-ROBOT-SETUP.bash <setup>` clones the rest.
- Any other extension, such as a device or a product binding, takes effect once its folder name is listed in `OPENROSDE_ROBOT_EXTENSIONS`, which adds its Catkin workspaces after the platform workspace and its Docker Compose overlays to the container.

A private extension, cloned from a private repository, works exactly as a public one.
See [docs/extensions.md](../docs/extensions.md) for the full guide.
