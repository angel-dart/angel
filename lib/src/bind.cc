#include "angel_wings.h"
#include "wings_socket.h"
using namespace wings;

void getWingsSocketInfo(Dart_NativeArguments arguments, WingsSocketInfo *info);

WingsSocket *wingsFindSocket(Dart_NativeArguments arguments, const WingsSocketInfo &info, int af);

WingsSocket *wingsBindNewSocket(Dart_NativeArguments arguments, const WingsSocketInfo &info, int af);

void wingsReturnBound(Dart_NativeArguments arguments, WingsSocket *socket);

void Dart_WingsSocket_bindIPv4(Dart_NativeArguments arguments)
{
    WingsSocketInfo info;
    getWingsSocketInfo(arguments, &info);
    WingsSocket *socket = wingsFindSocket(arguments, info, AF_INET);
    wingsReturnBound(arguments, socket);
}

void Dart_WingsSocket_bindIPv6(Dart_NativeArguments arguments)
{
    WingsSocketInfo info;
    getWingsSocketInfo(arguments, &info);
    WingsSocket *socket = wingsFindSocket(arguments, info, AF_INET6);
    wingsReturnBound(arguments, socket);
}

void wingsReturnBound(Dart_NativeArguments arguments, WingsSocket *socket)
{
    Dart_Port sendPort;
    HandleError(Dart_SendPortGetId(socket->getInfo().sendPortHandle, &sendPort));
    socket->incrRef(sendPort);
    auto ptr = (uint64_t)socket;
    Dart_Handle ptrHandle = Dart_NewIntegerFromUint64(ptr);
    Dart_SetReturnValue(arguments, ptrHandle);
}

void wingsThrowStateError(const char *msg)
{
    Dart_Handle msgHandle = Dart_NewStringFromCString(msg);
    Dart_Handle emptyHandle = Dart_NewStringFromCString("");
    Dart_Handle stateErrorHandle = Dart_NewStringFromCString("StateError");
    Dart_Handle dartCoreHandle = Dart_NewStringFromCString("dart:core");
    Dart_Handle dartCore = Dart_LookupLibrary(dartCoreHandle);
    Dart_Handle stateError = Dart_GetType(dartCore, stateErrorHandle, 0, nullptr);
    Dart_Handle errHandle = Dart_New(stateError, emptyHandle, 1, &msgHandle);
    Dart_ThrowException(errHandle);
}

WingsSocket *wingsFindSocket(Dart_NativeArguments arguments, const WingsSocketInfo &info, int af)
{
    // Find an existing server, if any.
    if (info.shared)
    {
        for (auto *socket : globalSocketList)
        {
            if (socket->getInfo() == info)
            {
                return socket;
            }
        }
    }

    return wingsBindNewSocket(arguments, info, af);
}

WingsSocket *wingsBindNewSocket(Dart_NativeArguments arguments, const WingsSocketInfo &info, int af)
{
    sockaddr *addr;
    sockaddr_in v4;
    sockaddr_in6 v6;
    int ret;

    int sock = socket(af, SOCK_STREAM, IPPROTO_TCP);

    if (sock < 0)
    {
        wingsThrowStateError("Failed to create socket.");
        return nullptr;
    }

    int i = 1;
    ret = setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, &i, sizeof(i));

    if (ret < 0)
    {
        wingsThrowStateError("Cannot reuse address for socket.");
        return nullptr;
    }

    // TODO: Only on Mac???
    // ret = setsockopt(sock, SOL_SOCKET, SO_REUSEPORT, &i, sizeof(i));

    // if (ret < 0)
    // {
    //     wingsThrowStateError("Cannot reuse port for socket.");
    //     return;
    // }

    if (af == AF_INET6)
    {
        v6.sin6_family = AF_INET6;
        v6.sin6_port = htons((uint16_t)info.port);
        ret = inet_pton(AF_INET6, info.address, &v6.sin6_addr.s6_addr);
        if (ret >= 0)
            ret = bind(sock, (const sockaddr *)&v6, sizeof(v6));
    }
    else
    {
        v4.sin_family = AF_INET;
        v4.sin_port = htons((uint16_t)info.port);
        v4.sin_addr.s_addr = inet_addr(info.address);
        bind(sock, (const sockaddr *)&v4, sizeof(v4));
    }

    if (ret < 0)
    {
        wingsThrowStateError("Failed to bind socket.");
        return nullptr;
    }

    if (listen(sock, SOMAXCONN) < 0)
    {
        wingsThrowStateError("Failed to set SOMAXCONN on bound socket.");
        return nullptr;
    }

    if (listen(sock, (int)info.backlog) < 0)
    {
        wingsThrowStateError("Failed to set backlog on bound socket.");
        return nullptr;
    }

    auto *out = new WingsSocket(sock, info);
    globalSocketList.push_back(out);
    return out;
}

void getWingsSocketInfo(Dart_NativeArguments arguments, WingsSocketInfo *info)
{
    Dart_Handle addressHandle = Dart_GetNativeArgument(arguments, 0);
    Dart_Handle portHandle = Dart_GetNativeArgument(arguments, 1);
    Dart_Handle sharedHandle = Dart_GetNativeArgument(arguments, 2);
    Dart_Handle backlogHandle = Dart_GetNativeArgument(arguments, 3);
    Dart_Handle v6OnlyHandle = Dart_GetNativeArgument(arguments, 4);
    info->sendPortHandle = Dart_GetNativeArgument(arguments, 5);

    HandleError(Dart_StringToCString(addressHandle, &info->address));
    HandleError(Dart_IntegerToUint64(portHandle, &info->port));
    HandleError(Dart_BooleanValue(sharedHandle, &info->shared));
    HandleError(Dart_IntegerToUint64(backlogHandle, &info->backlog));
    HandleError(Dart_BooleanValue(v6OnlyHandle, &info->v6Only));
}
