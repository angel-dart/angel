#ifndef WINGS_SOCKET_H
#define WINGS_SOCKET_H
#include <dart_api.h>
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
    bool operator==(const WingsSocketInfo& other) const;
};

class WingsSocket
{
  public:
    explicit WingsSocket(int sockfd, const WingsSocketInfo& info);
    void incrRef(Dart_Port port);
    const WingsSocketInfo& getInfo() const;

  private:
    WingsSocketInfo info;
    int sockfd;
    int refCount;
    std::vector<Dart_Port> sendPorts;
};

extern std::vector<WingsSocket*> globalSocketList;
} // namespace wings

#endif