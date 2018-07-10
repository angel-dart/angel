CXX=clang
HTTP_PARSER=.dart_tool/build_native/third_party/angel_wings.http_parser
CXX_INCLUDES=-I$(HTTP_PARSER) -I$(DART_SDK)/include

.PHONY: clean debug macos all

all:
	//printf 'Available targets:\n'\
	'  * `debug` - Builds a debug library on MacOS\n'\
	'  * `example` - Runs example/main.dart in LLDB on MacOS\n'\
	'  * `macos` - Builds a release-mode library on MacOS\n'

clean:
	find lib -name "*.a" -delete
	find lib -name "*.o" -delete
	find lib -name "*.dylib" -delete

debug:
	$(MAKE) lib/src/libwings.dylib CXXFLAGS="-g -DDEBUG=1"

macos:
	$(MAKE) lib/src/libwings.dylib

example: debug
	lldb -o "target create dart" \
	-o "process launch --stop-at-entry example/main.dart" \
	-o "process handle SIGINT -p true" \
	-o "continue" \

lib/src/bind_socket.o:
	$(CXX) $(CXXFLAGS) $(CXX_INCLUDES) -std=c++11 -c -o lib/src/bind_socket.o lib/src/bind_socket.cc

lib/src/http_listener.o:
	$(CXX) $(CXXFLAGS) $(CXX_INCLUDES) -std=c++11 -c -o lib/src/http_listener.o lib/src/http_listener.cc

lib/src/http_parser.o:
	$(CXX) $(CXXFLAGS) $(CXX_INCLUDES) -c -o lib/src/http_parser.o $(HTTP_PARSER)/http_parser.c

lib/src/send.o:
	$(CXX) $(CXXFLAGS) $(CXX_INCLUDES) -std=c++11 -c -o lib/src/send.o lib/src/send.cc

lib/src/util.o:
	$(CXX) $(CXXFLAGS) $(CXX_INCLUDES) -std=c++11 -c -o lib/src/util.o lib/src/util.cc

lib/src/wings.o:
	$(CXX) $(CXXFLAGS) $(CXX_INCLUDES) -std=c++11 -c -o lib/src/wings.o lib/src/wings.cc

lib/src/worker_thread.o:
	$(CXX) $(CXXFLAGS) $(CXX_INCLUDES) -std=c++11 -c -o lib/src/worker_thread.o lib/src/worker_thread.cc

lib/src/libwings.dylib: lib/src/bind_socket.o lib/src/http_listener.o lib/src/http_parser.o lib/src/send.o lib/src/util.o lib/src/wings.o lib/src/worker_thread.o
	$(CXX) $(CXXFLAGS) -shared -o lib/src/libwings.dylib -undefined dynamic_lookup -DDART_SHARED_LIB -Wl -fPIC -m64 \
	lib/src/bind_socket.o lib/src/http_listener.o \
	lib/src/http_parser.o lib/src/send.o lib/src/util.o \
	lib/src/wings.o lib/src/worker_thread.o