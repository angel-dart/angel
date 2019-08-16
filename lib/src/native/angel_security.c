#include <dart_api.h>
#include <libinjection.h>
#include <libinjection_sqli.h>
#include <stdbool.h>
#include <string.h>

Dart_NativeFunction ResolveName(Dart_Handle name, int argc,
                                bool *auto_setup_scope);

DART_EXPORT Dart_Handle angel_security_native_Init(Dart_Handle parent_library) {
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

void Angel_Security_IsSqli(Dart_NativeArguments arguments) {
  const char *text;
  Dart_Handle textHandle = Dart_GetNativeArgument(arguments, 0);
  HandleError(Dart_StringToCString(textHandle, &text));

  struct libinjection_sqli_state state;
  libinjection_sqli_init(&state, text, strlen(text), FLAG_NONE);
  int is_sqli = libinjection_is_sqli(&state);

  // Return list
  Dart_Handle outHandle = Dart_NewList(2);
  if (is_sqli != 0) {
    HandleError(Dart_ListSetAt(outHandle, 0, Dart_NewBoolean(true)));
    HandleError(Dart_ListSetAt(outHandle, 1,
                               Dart_NewStringFromCString(state.fingerprint)));
  } else {
    HandleError(Dart_ListSetAt(outHandle, 0, Dart_NewBoolean(false)));
    HandleError(Dart_ListSetAt(outHandle, 1, Dart_Null()));
  }
}

Dart_NativeFunction ResolveName(Dart_Handle name, int argc,
                                bool *auto_setup_scope) {
  if (!Dart_IsString(name))
    return NULL;
  Dart_NativeFunction result = NULL;
  const char *cname;
  HandleError(Dart_StringToCString(name, &cname));

  if (strcmp("Angel_Security_IsSqli", cname) == 0)
    result = Angel_Security_IsSqli;
  return result;
}
