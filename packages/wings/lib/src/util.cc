#include <cstring>

#include "angel_wings.h"
#include "wings_socket.h"
#include <dart_native_api.h>
#include <iostream>
using namespace wings;

void Dart_WingsSocket_listen(Dart_NativeArguments arguments) {
  uint64_t ptr;
  Dart_Handle pointerHandle = Dart_GetNativeArgument(arguments, 0);
  HandleError(Dart_IntegerToUint64(pointerHandle, &ptr));

  auto *socket = (WingsSocket *)ptr;
  socket->start(arguments);
}

struct wingsSockName {
  sa_family_t family;
  sockaddr_in v4;
  sockaddr_in6 v6;

  struct sockaddr *ptr() const {
    if (family == AF_INET6) {
      return (sockaddr *)&v6;
    } else {
      return (sockaddr *)&v4;
    }
  }

  void *addrPtr() const {
    if (family == AF_INET6) {
      return (void *)&v6.sin6_addr;
    } else {
      return (void *)&v4.sin_addr;
    }
  }

  socklen_t length() const {
    if (family == AF_INET6) {
      return sizeof(v6);
    } else {
      return sizeof(v4);
    }
  }
};

void wingsThrowOSError() {
  wingsThrowError(strerror(errno), "dart:io", "OSError", errno);
}

bool wingsReadSocket(Dart_NativeArguments arguments, wingsSockName *out) {
  uint64_t ptr;
  Dart_Handle pointerHandle = Dart_GetNativeArgument(arguments, 0);
  HandleError(Dart_IntegerToUint64(pointerHandle, &ptr));

  auto *socket = (WingsSocket *)ptr;
  int fd = socket->getFD();

  socklen_t len;
  out->family = socket->getFamily();
  len = out->length();

  int result;

  // result = connect(fd, out->ptr(), len);

  // if (result < 0)
  // {
  //     wingsThrowOSError();
  //     return false;
  // }

  result = getsockname(fd, out->ptr(), &len);

  if (result == -1) {
    wingsThrowOSError();
    return false;
  }

  return true;
}

void Dart_WingsSocket_getAddress(Dart_NativeArguments arguments) {
  wingsSockName sock;
  if (wingsReadSocket(arguments, &sock)) {
    char addrBuf[INET6_ADDRSTRLEN + 1] = {0};

    auto *result =
        inet_ntop(sock.family, sock.addrPtr(), addrBuf, sock.length());

    if (result == NULL) {
      wingsThrowOSError();
    }

    Dart_Handle outHandle = Dart_NewStringFromCString(addrBuf);
    Dart_SetReturnValue(arguments, outHandle);
  }
}

void Dart_WingsSocket_getPort(Dart_NativeArguments arguments) {
  wingsSockName sock;
  if (wingsReadSocket(arguments, &sock)) {
    Dart_Handle outHandle;

    if (sock.family == AF_INET6) {
      outHandle = Dart_NewIntegerFromUint64(ntohs(sock.v6.sin6_port));
    } else {
      outHandle = Dart_NewIntegerFromUint64(ntohs(sock.v4.sin_port));
    }

    Dart_SetReturnValue(arguments, outHandle);
  }
}

void Dart_WingsSocket_write(Dart_NativeArguments arguments) {
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

void Dart_WingsSocket_closeDescriptor(Dart_NativeArguments arguments) {
  int64_t fd;
  Dart_Handle fdHandle = Dart_GetNativeArgument(arguments, 0);
  HandleError(Dart_IntegerToInt64(fdHandle, &fd));
  close(fd);
}

void Dart_WingsSocket_close(Dart_NativeArguments arguments) {
  Dart_Port port;
  uint64_t ptr;
  Dart_Handle pointerHandle = Dart_GetNativeArgument(arguments, 0);
  Dart_Handle sendPortHandle = Dart_GetNativeArgument(arguments, 1);
  HandleError(Dart_IntegerToUint64(pointerHandle, &ptr));
  HandleError(Dart_SendPortGetId(sendPortHandle, &port));

  auto *socket = (WingsSocket *)ptr;
  socket->decrRef(port);
}