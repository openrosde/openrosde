cmake_minimum_required(VERSION 2.8.3)
project(openrosde_user_launch)

find_package(catkin REQUIRED COMPONENTS)

catkin_package()

include_directories(
  ${catkin_INCLUDE_DIRS}
)

catkin_install_python(
  PROGRAMS
    scripts/seg_fastsam_node.py
    scripts/depth_colorizer_node.py
  DESTINATION ${CATKIN_PACKAGE_BIN_DESTINATION}
)
