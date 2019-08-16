#include <dart_api.h>
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
    char* text;
    HandleError();
  Dart_Handle result = HandleError(Dart_NewInteger(rand()));
  Dart_SetReturnValue(arguments, result);
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
