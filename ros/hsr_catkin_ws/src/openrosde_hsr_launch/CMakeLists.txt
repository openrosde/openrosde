cmake_minimum_required(VERSION 2.8.3)
project(openrosde_hsr_launch)

find_package(catkin REQUIRED COMPONENTS)

catkin_package()

include_directories(
  ${catkin_INCLUDE_DIRS}
)

# Install config files (RViz layouts).
install(DIRECTORY config/
  DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION}/config
)
