cmake_minimum_required(VERSION 3.10)
project(openrosde_user_launch)

find_package(ament_cmake REQUIRED)

# Install the launch files and the configuration files, such as RViz layouts and maps.
install(DIRECTORY launch config
  DESTINATION share/${PROJECT_NAME}
)

ament_package()
