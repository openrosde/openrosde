cmake_minimum_required(VERSION 3.0.2)
project(openrosde_fetch_teleop)

find_package(catkin REQUIRED COMPONENTS
  geometry_msgs
  message_generation
  rospy
  std_msgs
)

add_service_files(
  FILES
    FetchSwitchController.srv
)

generate_messages(
  DEPENDENCIES
    std_msgs
)

catkin_package(
  CATKIN_DEPENDS geometry_msgs message_runtime rospy std_msgs
)

include_directories(
  ${catkin_INCLUDE_DIRS}
)

catkin_install_python(
  PROGRAMS
    scripts/fetch_cartesian_twist_control.py
  DESTINATION ${CATKIN_PACKAGE_BIN_DESTINATION}
)
