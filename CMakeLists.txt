list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/cmake_dart_utils")
find_package(Dart REQUIRED)
add_subdirectory(lib/src)
