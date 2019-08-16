cmake_minimum_required(VERSION 3.0)
project(angel_security)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/cmake_dart_utils/cmake")
find_package(Dart REQUIRED)
include_directories(libinjection/src)
add_subdirectory(libinjection/src)
add_dart_native_extension(angel_security_native lib/src/native/angel_security.c)
target_link_libraries(angel_security_native injection)
install(TARGETS angel_security_native injection
        ARCHIVE DESTINATION "${CMAKE_CURRENT_LIST_DIR}/lib/src"
        LIBRARY DESTINATION "${CMAKE_CURRENT_LIST_DIR}/lib/src")