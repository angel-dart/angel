#include "wings_socket.h"
#include <algorithm>
#include <cstring>
#include <vector>
using namespace wings;

std::vector<WingsSocket *> wings::globalSocketList;

bool WingsSocketInfo::equals(const WingsSocketInfo &right) const {
  // std::cout << address << " vs " << right.address << std::endl;
  // std::cout << port << " vs " << right.port << std::endl;
  return (strcmp(address, right.address) == 0) && port == right.port;
}

WingsSocket::WingsSocket(sa_family_t family, int sockfd,
                         const WingsSocketInfo &info)
    : sockfd(sockfd), info(info), family(family) {
  portIterator = sendPorts.begin();
  open = true;
  refCount = 0;
  workerThread = nullptr;
  this->info.address = strdup(info.address);
}

void WingsSocket::incrRef(Dart_Port port) {
  refCount++;
  sendPorts.push_back(port);
}

void WingsSocket::decrRef(Dart_Port port) {
  auto it = std::find(sendPorts.begin(), sendPorts.end(), port);

  if (it != sendPorts.end()) {
    sendPorts.erase(it);
  }

  refCount--;

  if (refCount <= 0 && open) {
    close(sockfd);
    open = false;
  }
}

Dart_Port WingsSocket::nextPort() {
  portIterator++;
  if (portIterator == sendPorts.end())
    portIterator = sendPorts.begin();
  return *portIterator;
}

const WingsSocketInfo &WingsSocket::getInfo() const { return info; }

int WingsSocket::getFD() const { return sockfd; }

sa_family_t WingsSocket::getFamily() const { return family; }

bool WingsSocket::isClosed() const { return !open; }

void WingsSocket::start(Dart_NativeArguments arguments) {
  // if (workerThread == nullptr)
  // {
  //     workerThread = std::make_unique<std::thread>(threadCallback, this);
  // }
  Dart_Port service_port =
      Dart_NewNativePort("WingsThreadCallback", &threadCallback, true);
  Dart_Handle send_port = Dart_NewSendPort(service_port);
  Dart_SetReturnValue(arguments, send_port);
}

void WingsSocket::threadCallback(Dart_Port dest_port_id,
                                 Dart_CObject *message) {

  WingsSocket *socket = nullptr;
  Dart_Port outPort = message->value.as_array.values[0]->value.as_send_port.id;
  Dart_CObject *ptrArg = message->value.as_array.values[1];

  // If there are no listeners, quit.
  if (ptrArg->type == Dart_CObject_kInt32) {
    auto as64 = (int64_t)ptrArg->value.as_int32;
    socket = (WingsSocket *)as64;
  } else {
    socket = (WingsSocket *)ptrArg->value.as_int64;
  }

  if (socket != nullptr) {
    if (socket->sendPorts.empty() || socket->isClosed()) {
      return;
    }

    int sock;
    unsigned long index = 0;
    sockaddr addr;
    socklen_t len;

    if ((sock = accept(socket->sockfd, &addr, &len)) != -1) {
      char addrBuf[INET6_ADDRSTRLEN] = {0};

      if (addr.sa_family == AF_INET6) {
        auto as6 = (sockaddr_in6 *)&addr;
        inet_ntop(addr.sa_family, &(as6->sin6_addr), addrBuf, len);
      } else {
        auto as4 = (sockaddr_in *)&addr;
        inet_ntop(AF_INET, &(as4->sin_addr), addrBuf, len);
      }

      Dart_CObject fdObj;
      fdObj.type = Dart_CObject_kInt64;
      fdObj.value.as_int64 = sock;

      Dart_CObject addrObj;
      addrObj.type = Dart_CObject_kString;
      addrObj.value.as_string = addrBuf;

      Dart_CObject *values[2] = {&fdObj, &addrObj};

      Dart_CObject obj;
      obj.type = Dart_CObject_kArray;
      obj.value.as_array.length = 2;
      obj.value.as_array.values = values;

      // Dart_PostCObject(outPort, &obj);
      // Dispatch the fd to the next listener.
      auto port = socket->nextPort();
      Dart_PostCObject(port, &obj);
      // Dart_PostCObject(outPort, &obj);
    }
  }
}