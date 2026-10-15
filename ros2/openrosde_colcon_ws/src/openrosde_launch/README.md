# openrosde_launch

The `openrosde_launch` package provides shared launch files common to all platforms on ROS 2, beside the package of the same name in `ros/openrosde_catkin_ws/` for the platforms on ROS 1.

- Maintainer: Lotfi El Hafi ([lotfi@coarobo.com](mailto:lotfi@coarobo.com)).
- Author: Lotfi El Hafi ([lotfi@coarobo.com](mailto:lotfi@coarobo.com)).

## Launch Files

| Launch File | Description |
| --- | --- |
| `rosbridge_server_default.launch.xml` | ROSBridge WebSocket server (port 9090) with the file service of the robot model, the one transport of OpenRoSDE for clients such as web and Unity applications, with the argument `max_message_size` (100,000,000 bytes by default) |
| `rqt_suite_default.launch.xml` | RQT monitoring suite (`rqt_topic`, `rqt_image_view`, `rqt_tf_tree`, `rqt_service_caller`) |

The FlexBE App has no launch file here, since no release of it exists for ROS 2 Lyrical, while the image holds the FlexBE behavior engine.

## Scripts

The package installs `maximize-app-window.bash` of the package of ROS 1 into `lib/openrosde_launch/`, so one script serves both ROS.
A launch file of ROS 2 runs it as an `executable`, which passes no ROS argument to it:

```xml
<executable cmd="$(find-pkg-prefix openrosde_launch)/lib/openrosde_launch/maximize-app-window.bash RViz" />
```
