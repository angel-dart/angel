#ifndef WINGS_SOCKET_H
#define WINGS_SOCKET_H
#include <arpa/inet.h>
#include <unistd.h>
#include <stdio.h>
#include <sys/socket.h>
#include <stdlib.h>
#include <netinet/in.h>
#include <dart_api.h>
#include <dart_native_api.h>
#include <memory>
#include <thread>
#include <vector>

namespace wings
{
struct WingsSocketInfo
{
  const char *address;
  uint64_t port;
  bool shared;
  uint64_t backlog;
  bool v6Only;
  Dart_Handle sendPortHandle;
  bool equals(const WingsSocketInfo &right) const;
};

class WingsSocket
{
public:
  WingsSocket(sa_family_t family, int sockfd, const WingsSocketInfo &info);
  void incrRef(Dart_Port port);
  void decrRef(Dart_Port port);
  const WingsSocketInfo &getInfo() const;
  void start(Dart_NativeArguments arguments);
  int getFD() const;
  sa_family_t getFamily() const;
  Dart_Port nextPort();

private:
  static void threadCallback(Dart_Port dest_port_id, Dart_CObject *message);
  WingsSocketInfo info;
  unsigned long index;
  int sockfd;
  int refCount;
  bool open;
  sa_family_t family;
  std::unique_ptr<std::thread> workerThread;
  std::vector<Dart_Port> sendPorts;
};

extern std::vector<WingsSocket *> globalSocketList;
} // namespace wings

#endif