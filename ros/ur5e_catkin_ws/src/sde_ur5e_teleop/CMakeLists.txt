cmake_minimum_required(VERSION 2.8.3)
project(sde_ur5e_teleop)

find_package(catkin REQUIRED COMPONENTS
  controller_manager_msgs
  geometry_msgs
  rospy
  sensor_msgs
  std_msgs
)

catkin_package()

include_directories(
  ${catkin_INCLUDE_DIRS}
)

catkin_install_python(
  PROGRAMS
    scripts/ur5e_controller_manager_switch.py
    scripts/ur5e_moveit_servo_spacenav_node.py
    scripts/ur5e_onrobot_rg_control_spacenav_node.py
    scripts/ur5e_moveit_servo_viewport.py
  DESTINATION ${CATKIN_PACKAGE_BIN_DESTINATION}
)

# Copy the 'spacenavd' startup script to devel space for roslaunch node resolution.
file(COPY scripts/ur5e_spacenavd_daemon.bash
  DESTINATION ${CATKIN_DEVEL_PREFIX}/lib/${PROJECT_NAME}
  FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)

# Install the 'spacenavd' startup script to the package bin destination.
install(PROGRAMS scripts/ur5e_spacenavd_daemon.bash
  DESTINATION ${CATKIN_PACKAGE_BIN_DESTINATION})
