# openrosde_launch

The `openrosde_launch` package provides shared launch files common to all platforms.

- Maintainer: Lotfi El Hafi ([lotfi@coarobo.com](mailto:lotfi@coarobo.com)).
- Author: Lotfi El Hafi ([lotfi@coarobo.com](mailto:lotfi@coarobo.com)).

## Launch Files

| Launch File | Description |
| --- | --- |
| `flexbe_app_default.launch` | FlexBE behavior engine and app |
| `rosbridge_server_default.launch` | ROSBridge WebSocket server (port 9090) with the file service of the robot model, the one transport of OpenRoSDE for clients such as web and Unity applications |
| `rqt_suite_default.launch` | RQT monitoring suite (`rqt_topic`, `rqt_image_view`, `rqt_tf_tree`, `rqt_service_caller`) |

## Scripts

| Script | Description |
| --- | --- |
| `maximize-app-window.bash` | Maximizes an X11 window by title substring and then restores focus to the terminal titled `OpenRoSDE (`, the `tmux` session or the Terminator layout (used by RViz, Gazebo, FlexBE, and rqt launch files) |
