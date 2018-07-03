#ifndef ANGEL_WINGS_H
#define ANGEL_WINGS_H
#ifndef WIN32
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#else
#include <windows.h>
#include <winsock2.h>
#include <ws2tcpip.h>
#include <sstream>
// Need to link with Ws2_32.lib, Mswsock.lib, and Advapi32.lib
#pragma comment(lib, "Ws2_32.lib")
#pragma comment(lib, "Mswsock.lib")
#pragma comment(lib, "AdvApi32.lib")
#endif
#include <cstdint>
#include <mutex>
#include <string>
#include <vector>
#include <dart_api.h>

class WingsServerInfo
{
public:
  std::mutex mutex;
  std::string addressString;
  uint64_t port;
  int sockfd;
  bool ipv6;
};

extern std::mutex serverInfoVectorMutex;
extern std::vector<WingsServerInfo *> serverInfoVector;

Dart_Handle HandleError(Dart_Handle handle);

void wings_AddressToString(Dart_NativeArguments arguments);
void wings_BindSocket(Dart_NativeArguments arguments);
void wings_CloseSocket(Dart_NativeArguments arguments);
void wings_Send(Dart_NativeArguments arguments);
void wings_StartHttpListener(Dart_NativeArguments arguments);

#endif