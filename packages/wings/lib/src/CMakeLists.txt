include_directories("${CMAKE_CURRENT_LIST_DIR}")
add_dart_native_extension(angel_wings
	http-parser/http_parser.c
	angel_wings.h angel_wings.cc
	bind.cc http.cc wings_socket.cc
	util.cc)
install(TARGETS angel_wings LIBRARY DESTINATION "${CMAKE_CURRENT_LIST_DIR}")
install(TARGETS angel_wings LIBRARY DESTINATION "${CMAKE_CURRENT_LIST_DIR}/../..")
