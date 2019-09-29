#ifndef ANGEL_WINGS_WINGS_H
#define ANGEL_WINGS_WINGS_H

#include "angel_wings.h"
#include <dart_api.h>
#include <dart_native_api.h>

Dart_NativeFunction ResolveName(Dart_Handle name, int argc,
                                bool *auto_setup_scope);
Dart_Handle HandleError(Dart_Handle handle);

void wingsThrowError(const char *msg, const char *lib = "dart:core",
                     const char *name = "StateError", int n = -1);
void Dart_WingsSocket_bindIPv4(Dart_NativeArguments arguments);
void Dart_WingsSocket_bindIPv6(Dart_NativeArguments arguments);
void Dart_WingsSocket_getAddress(Dart_NativeArguments arguments);
void Dart_WingsSocket_getPort(Dart_NativeArguments arguments);
void Dart_WingsSocket_write(Dart_NativeArguments arguments);
void Dart_WingsSocket_closeDescriptor(Dart_NativeArguments arguments);
void Dart_WingsSocket_close(Dart_NativeArguments arguments);
void Dart_WingsSocket_listen(Dart_NativeArguments arguments);
void Dart_WingsSocket_parseHttp(Dart_NativeArguments arguments);
void wingsHttpCallback(Dart_Port dest_port_id, Dart_CObject *message);

#endif