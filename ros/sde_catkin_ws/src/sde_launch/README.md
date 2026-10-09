# sde_launch

The `sde_launch` package provides shared launch files common to all platforms.

- Maintainer: Lotfi El Hafi ([lotfi@coarobo.com](mailto:lotfi@coarobo.com)).
- Author: Lotfi El Hafi ([lotfi@coarobo.com](mailto:lotfi@coarobo.com)).

## Launch Files

| Launch File | Description |
| --- | --- |
| `flexbe_app_default.launch` | FlexBE behavior engine and app |
| `rosbridge_server_default.launch` | ROSBridge WebSocket server (port 9090) |
| `ros_tcp_endpoint_default.launch` | Unity ROS TCP Endpoint (port 10000) for Coarobo Sightline, run by `ros_tcp_endpoint_server.py` |
| `rqt_suite_default.launch` | RQT monitoring suite (`rqt_topic`, `rqt_image_view`, `rqt_tf_tree`, `rqt_service_caller`) |

## Scripts

| Script | Description |
| --- | --- |
| `maximize-app-window.bash` | Maximizes an X11 window by title substring and then restores focus to the Terminator window (used by RViz, Gazebo, FlexBE, and rqt launch files) |
| `ros_tcp_endpoint_server.py` | Runs the upstream Unity ROS TCP Endpoint `0.7.0` with the `__remove_subscriber`, `__remove_publisher`, `__remove_ros_service`, and `__remove_unity_service` system commands it lacks, so a Unity client that drops its last subscription on a topic keeps its connection |
