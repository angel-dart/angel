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
  bool operator==(const WingsSocketInfo &other) const;
};

class WingsSocket
{
public:
  explicit WingsSocket(int sockfd, const WingsSocketInfo &info);
  void incrRef(Dart_Port port);
  const WingsSocketInfo &getInfo() const;
  void start(Dart_NativeArguments arguments);

private:
  static void threadCallback(Dart_Port dest_port_id, Dart_CObject *message);
  WingsSocketInfo info;
  int sockfd;
  int refCount;
  std::unique_ptr<std::thread> workerThread;
  std::vector<Dart_Port> sendPorts;
};

extern std::vector<WingsSocket *> globalSocketList;
} // namespace wings

#endif