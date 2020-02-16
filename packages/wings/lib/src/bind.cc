#include "angel_wings.h"
#include "wings_socket.h"
#include <fcntl.h>
#include <vector>
using namespace wings;

void getWingsSocketInfo(Dart_NativeArguments arguments, WingsSocketInfo *info);

WingsSocket *wingsFindSocket(Dart_NativeArguments arguments,
                             const WingsSocketInfo &info, int af);

WingsSocket *wingsBindNewSocket(Dart_NativeArguments arguments,
                                const WingsSocketInfo &info, int af);

void wingsReturnBound(Dart_NativeArguments arguments, WingsSocket *socket);

void Dart_WingsSocket_bind(sa_family_t af, Dart_NativeArguments arguments) {
  WingsSocketInfo info;
  getWingsSocketInfo(arguments, &info);
  WingsSocket *socket = wingsFindSocket(arguments, info, af);
  wingsReturnBound(arguments, socket);
}

void Dart_WingsSocket_bindIPv4(Dart_NativeArguments arguments) {
  Dart_WingsSocket_bind(AF_INET, arguments);
}

void Dart_WingsSocket_bindIPv6(Dart_NativeArguments arguments) {
  Dart_WingsSocket_bind(AF_INET6, arguments);
}

void wingsReturnBound(Dart_NativeArguments arguments, WingsSocket *socket) {
  Dart_Port sendPort;
  HandleError(
      Dart_SendPortGetId(Dart_GetNativeArgument(arguments, 5), &sendPort));
  socket->incrRef(sendPort);
  auto ptr = (uint64_t)socket;
  Dart_Handle ptrHandle = Dart_NewIntegerFromUint64(ptr);
  Dart_SetReturnValue(arguments, ptrHandle);
}

WingsSocket *wingsFindSocket(Dart_NativeArguments arguments,
                             const WingsSocketInfo &info, int af) {
  // Find an existing server, if any.
  if (info.shared) {
    // std::cout << info.address << std::endl;
    // std::cout << globalSocketList.size() << std::endl;
    for (auto *socket : globalSocketList) {
      if (info.equals(socket->getInfo())) {
        return socket;
      }
    }
  }

  return wingsBindNewSocket(arguments, info, af);
}

WingsSocket *wingsBindNewSocket(Dart_NativeArguments arguments,
                                const WingsSocketInfo &info, int af) {
  sockaddr *addr;
  sockaddr_in v4;
  sockaddr_in6 v6;
  int ret;

  int sock = socket(af, SOCK_STREAM, IPPROTO_TCP);

  if (sock < 0) {
    wingsThrowError("Failed to create socket.");
    return nullptr;
  }

  int i = 1;
  ret = setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, &i, sizeof(i));

  if (ret < 0) {
    wingsThrowError("Cannot reuse address for socket.");
    return nullptr;
  }

  // TODO: Only on Mac???
  // ret = setsockopt(sock, SOL_SOCKET, SO_REUSEPORT, &i, sizeof(i));

  // if (ret < 0)
  // {
  //     wingsThrowStateError("Cannot reuse port for socket.");
  //     return;
  // }

  if (af == AF_INET6) {
    v6.sin6_family = AF_INET6;
    v6.sin6_port = htons((uint16_t)info.port);
    ret = inet_pton(AF_INET6, info.address, &v6.sin6_addr.s6_addr);
    if (ret >= 0)
      ret = bind(sock, (const sockaddr *)&v6, sizeof(v6));
  } else {
    v4.sin_family = AF_INET;
    v4.sin_port = htons((uint16_t)info.port);
    v4.sin_addr.s_addr = inet_addr(info.address);
    bind(sock, (const sockaddr *)&v4, sizeof(v4));
  }

  if (ret < 0) {
    wingsThrowError("Failed to bind socket.");
    return nullptr;
  }

  if (listen(sock, SOMAXCONN) < 0) {
    wingsThrowError("Failed to set SOMAXCONN on bound socket.");
    return nullptr;
  }

  if (listen(sock, (int)info.backlog) < 0) {
    wingsThrowError("Failed to set backlog on bound socket.");
    return nullptr;
  }

  if (fcntl(sock, F_SETFL, O_NONBLOCK) == -1) {
    wingsThrowError("Failed to make socket non-blocking.");
    return nullptr;
  }

  auto *out = new WingsSocket(af, sock, info);
  globalSocketList.push_back(out);
  return out;
}

void getWingsSocketInfo(Dart_NativeArguments arguments, WingsSocketInfo *info) {
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

void wingsThrowError(const char *msg, const char *lib, const char *name,
                     int n) {
  Dart_Handle msgHandle = Dart_NewStringFromCString(msg);
  Dart_Handle emptyHandle = Dart_NewStringFromCString("");
  Dart_Handle stateErrorHandle = Dart_NewStringFromCString(name);
  Dart_Handle dartCoreHandle = Dart_NewStringFromCString(lib);
  Dart_Handle dartCore = Dart_LookupLibrary(dartCoreHandle);
  Dart_Handle stateError = Dart_GetType(dartCore, stateErrorHandle, 0, nullptr);

  std::vector<Dart_Handle> args;
  args.push_back(msgHandle);

  if (n > -1) {
    args.push_back(Dart_NewInteger(n));
  }

  Dart_Handle errHandle =
      Dart_New(stateError, emptyHandle, args.size(), args.data());
  Dart_ThrowException(errHandle);
}