#ifdef __cplusplus
#include <cstdio>
#else
#include <stdio.h>
#endif
#include <dart_api.h>

Dart_Handle ToCString(Dart_Handle obj, const char** out) {
  Dart_Handle toStringMethod = Dart_NewStringFromCString("toString");
  Dart_Handle string = Dart_Invoke(obj, toStringMethod, 0, nullptr);
  return Dart_StringToCString(string, out);
}

Dart_Handle Dart_PrintToFile(Dart_Handle obj, FILE* stream) {
  const char *toString;
  Dart_Handle result = ToCString(obj, &toString);

  if (Dart_IsError(result))
    return result;
 
  fprintf(stream, "%s\n", toString);
  return Dart_Null();
}

Dart_Handle Dart_Print(Dart_Handle obj) {
  return Dart_PrintToFile(obj, stdout);
}