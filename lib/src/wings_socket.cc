#include <cstring>
#include "wings_socket.h"
using namespace wings;

std::vector<WingsSocket *> wings::globalSocketList;

bool WingsSocketInfo::operator==(const WingsSocketInfo &other) const
{
    return (strcmp(address, other.address) == 0) &&
           port == other.port;
}

WingsSocket::WingsSocket(int sockfd, const WingsSocketInfo &info) : sockfd(sockfd), info(info)
{
    refCount = 0;
}

void WingsSocket::incrRef(Dart_Port port)
{
    refCount++;
    sendPorts.push_back(port);
}

const WingsSocketInfo &WingsSocket::getInfo() const
{
    return info;
}