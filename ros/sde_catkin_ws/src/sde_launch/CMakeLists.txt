cmake_minimum_required(VERSION 2.8.3)
project(sde_launch)

find_package(catkin REQUIRED COMPONENTS)

catkin_package()

include_directories(
  ${catkin_INCLUDE_DIRS}
)

# Install the 'maximize-app-window.bash' helper script so it is discoverable as a
# roslaunch node type via 'pkg="sde_launch" type="maximize-app-window.bash"'.
install(PROGRAMS
  scripts/maximize-app-window.bash
  DESTINATION ${CATKIN_PACKAGE_BIN_DESTINATION}
)

# Install the 'ros_tcp_endpoint_server.py' node, which runs the Unity ROS TCP Endpoint for 'ros_tcp_endpoint_default.launch'.
catkin_install_python(PROGRAMS
  scripts/ros_tcp_endpoint_server.py
  DESTINATION ${CATKIN_PACKAGE_BIN_DESTINATION}
)
