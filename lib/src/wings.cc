#include <cstdlib>
#include <iostream>
#include <string.h>
#include <dart_api.h>
#include "wings.h"

// Forward declaration of ResolveName function.
Dart_NativeFunction ResolveName(Dart_Handle name, int argc, bool *auto_setup_scope);

// The name of the initialization function is the extension name followed
// by _Init.
DART_EXPORT Dart_Handle wings_Init(Dart_Handle parent_library)
{
  if (Dart_IsError(parent_library))
    return parent_library;

  Dart_Handle result_code =
      Dart_SetNativeResolver(parent_library, ResolveName, NULL);
  if (Dart_IsError(result_code))
    return result_code;

  return Dart_Null();
}

Dart_Handle HandleError(Dart_Handle handle)
{
  if (Dart_IsError(handle))
    Dart_PropagateError(handle);
  return handle;
}

Dart_NativeFunction ResolveName(Dart_Handle name, int argc, bool *auto_setup_scope)
{
  // If we fail, we return NULL, and Dart throws an exception.
  if (!Dart_IsString(name))
    return NULL;
  Dart_NativeFunction result = NULL;
  const char *cname;
  HandleError(Dart_StringToCString(name, &cname));

  if (strcmp(cname, "AddressToString") == 0)
  {
    result = wings_AddressToString;
  }
  else if (strcmp(cname, "BindSocket") == 0)
  {
    result = wings_BindSocket;
  }
  else if (strcmp(cname, "CloseSocket") == 0)
  {
    result = wings_CloseSocket;
  }
  else if (strcmp(cname, "Send") == 0)
  {
    result = wings_Send;
  }
  else if (strcmp(cname, "StartHttpListener") == 0)
  {
    result = wings_StartHttpListener;
  }

  return result;
}