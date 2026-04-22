cmake_minimum_required(VERSION 2.8.3)
project(sde_ur5e_launch)

find_package(catkin REQUIRED COMPONENTS)

catkin_package()

include_directories(
  ${catkin_INCLUDE_DIRS}
)

catkin_install_python(PROGRAMS
  scripts/publish-gripper-joint-states.py
  DESTINATION ${CATKIN_PACKAGE_BIN_DESTINATION}
)
