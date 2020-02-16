#include "angel_wings.h"
#include <cstdlib>
#include <dart_api.h>
#include <iostream>
#include <string.h>

// The name of the initialization function is the extension name followed
// by _Init.
DART_EXPORT Dart_Handle angel_wings_Init(Dart_Handle parent_library) {
  if (Dart_IsError(parent_library))
    return parent_library;

  Dart_Handle result_code =
      Dart_SetNativeResolver(parent_library, ResolveName, NULL);
  if (Dart_IsError(result_code))
    return result_code;

  return Dart_Null();
}

Dart_Handle HandleError(Dart_Handle handle) {
  if (Dart_IsError(handle))
    Dart_PropagateError(handle);
  return handle;
}

Dart_NativeFunction ResolveName(Dart_Handle name, int argc,
                                bool *auto_setup_scope) {
  // If we fail, we return NULL, and Dart throws an exception.
  if (!Dart_IsString(name))
    return NULL;
  Dart_NativeFunction result = NULL;
  const char *cname;
  HandleError(Dart_StringToCString(name, &cname));

  if (strcmp("Dart_WingsSocket_bindIPv4", cname) == 0)
    result = Dart_WingsSocket_bindIPv4;
  if (strcmp("Dart_WingsSocket_bindIPv6", cname) == 0)
    result = Dart_WingsSocket_bindIPv6;
  if (strcmp("Dart_WingsSocket_getAddress", cname) == 0)
    result = Dart_WingsSocket_getAddress;
  if (strcmp("Dart_WingsSocket_getPort", cname) == 0)
    result = Dart_WingsSocket_getPort;
  if (strcmp("Dart_WingsSocket_write", cname) == 0)
    result = Dart_WingsSocket_write;
  if (strcmp("Dart_WingsSocket_closeDescriptor", cname) == 0)
    result = Dart_WingsSocket_closeDescriptor;
  if (strcmp("Dart_WingsSocket_close", cname) == 0)
    result = Dart_WingsSocket_close;
  if (strcmp("Dart_WingsSocket_listen", cname) == 0)
    result = Dart_WingsSocket_listen;
  if (strcmp("Dart_WingsSocket_parseHttp", cname) == 0)
    result = Dart_WingsSocket_parseHttp;
  return result;
}