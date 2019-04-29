CXXFLAGS := $(CXXFLAGS) --std=c++11 -fPIC -DDART_SHARED_LIB=1 -I $(DART_SDK)/include
objects := lib/src/angel_wings.o lib/src/wings_socket.o\
lib/src/bind.o lib/src/util.o

.PHONY: distclean clean

distclean: clean
	rm -rf .dart_tool/http-parser

clean:
	find . -type f -name '*.o' -delete
	find . -type f -name '*.obj' -delete
	find . -type f -name '*.so' -delete
	find . -type f -name '*.dylib' -delete

mac: libangel_wings.dylib

linux: lib/src/libangel_wings.so

libangel_wings.dylib: lib/src/libangel_wings.dylib
	cp $< $@

lib/src/libangel_wings.dylib: $(objects)

%.dylib: $(objects)
	$(CXX) -shared -undefined dynamic_lookup -o $@ $^

%.so: $(objects)
	$(CXX) -shared -o $@ $^

%.o: %.cc lib/src/angel_wings.h
	$(CXX) $(CXXFLAGS) -c -o $@ $<

%.o: %.cc lib/src/angel_wings.h %.h
	$(CXX) $(CXXFLAGS) -c -o $@ $<