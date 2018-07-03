#include "wings.h"

void wings_CloseSocket(Dart_NativeArguments arguments)
{
    Dart_Handle sockfdHandle = Dart_GetNativeArgument(arguments, 0);
    uint64_t sockfd;
    HandleError(Dart_IntegerToUint64(sockfdHandle, &sockfd));
    close((int)sockfd);
}

void wings_Send(Dart_NativeArguments arguments)
{
    Dart_Handle sockfdHandle = Dart_GetNativeArgument(arguments, 0);
    Dart_Handle dataHandle = Dart_GetNativeArgument(arguments, 1);
    uint64_t sockfd;
    Dart_TypedData_Type dataType;
    void *dataBytes;
    intptr_t dataLength;
    HandleError(Dart_IntegerToUint64(sockfdHandle, &sockfd));
    HandleError(Dart_TypedDataAcquireData(dataHandle, &dataType, &dataBytes, &dataLength));
    write((int)sockfd, dataBytes, (size_t)dataLength);
}