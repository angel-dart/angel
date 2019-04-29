#include <dart_native_api.h>
#include "angel_wings.h"
#include "wings_socket.h"
using namespace wings;

void Dart_WingsSocket_listen(Dart_NativeArguments arguments)
{
    uint64_t ptr;
    Dart_Handle pointerHandle = Dart_GetNativeArgument(arguments, 0);
    HandleError(Dart_IntegerToUint64(pointerHandle, &ptr));

    auto *socket = (WingsSocket *)ptr;
    socket->start(arguments);
}

void Dart_WingsSocket_getPort(Dart_NativeArguments arguments)
{
    uint64_t ptr;
    Dart_Handle pointerHandle = Dart_GetNativeArgument(arguments, 0);
    HandleError(Dart_IntegerToUint64(pointerHandle, &ptr));

    auto *socket = (WingsSocket *)ptr;
    auto outHandle = Dart_NewIntegerFromUint64(socket->getInfo().port);
    Dart_SetReturnValue(arguments, outHandle);
}

void Dart_WingsSocket_write(Dart_NativeArguments arguments)
{
    int64_t fd;
    void *data;
    Dart_TypedData_Type type;
    intptr_t len;
    Dart_Handle fdHandle = Dart_GetNativeArgument(arguments, 0);
    Dart_Handle dataHandle = Dart_GetNativeArgument(arguments, 1);
    HandleError(Dart_IntegerToInt64(fdHandle, &fd));
    HandleError(Dart_TypedDataAcquireData(dataHandle, &type, &data, &len));
    write(fd, data, len);
    HandleError(Dart_TypedDataReleaseData(dataHandle));
}

void Dart_WingsSocket_closeDescriptor(Dart_NativeArguments arguments)
{
    int64_t fd;
    Dart_Handle fdHandle = Dart_GetNativeArgument(arguments, 0);
    HandleError(Dart_IntegerToInt64(fdHandle, &fd));
    close(fd);
}

void Dart_WingsSocket_close(Dart_NativeArguments arguments)
{
    // TODO: Actually do something.
}