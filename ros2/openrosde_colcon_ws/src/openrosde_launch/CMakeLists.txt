cmake_minimum_required(VERSION 3.10)
project(openrosde_launch)

find_package(ament_cmake REQUIRED)

# Install the launch files.
install(DIRECTORY launch
  DESTINATION share/${PROJECT_NAME}
)

# Install the 'maximize-app-window.bash' helper script of the 'openrosde_launch' package of ROS 1, which launch files of ROS 2 run as
# '$(find-pkg-prefix openrosde_launch)/lib/openrosde_launch/maximize-app-window.bash <window-title>', so that one script serves both ROS.
install(PROGRAMS
  ${CMAKE_CURRENT_SOURCE_DIR}/../../../../ros/openrosde_catkin_ws/src/openrosde_launch/scripts/maximize-app-window.bash
  DESTINATION lib/${PROJECT_NAME}
)

ament_package()
