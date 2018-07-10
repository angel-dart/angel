#include <cstring>
#include <mutex>
#include <vector>
#include "wings.h"

std::vector<WingsServerInfo *> serverInfoVector;
std::mutex serverInfoVectorMutex;

void wings_BindSocket(Dart_NativeArguments arguments)
{
    // Uint8List address, String addressString, int port, int backlog, bool shared
    Dart_Handle addressHandle = Dart_GetNativeArgument(arguments, 0);
    Dart_Handle addressStringHandle = Dart_GetNativeArgument(arguments, 1);
    Dart_Handle portHandle = Dart_GetNativeArgument(arguments, 2);
    Dart_Handle backlogHandle = Dart_GetNativeArgument(arguments, 3);
    Dart_Handle sharedHandle = Dart_GetNativeArgument(arguments, 4);
    Dart_TypedData_Type addressType;
    void *addressData;
    intptr_t addressLength;
    const char *addressString;
    uint64_t port, backlog;
    bool shared;

    // Read the arguments...
    HandleError(Dart_TypedDataAcquireData(addressHandle, &addressType, &addressData, &addressLength));
    HandleError(Dart_TypedDataReleaseData(addressHandle));
    HandleError(Dart_StringToCString(addressStringHandle, &addressString));
    HandleError(Dart_IntegerToUint64(portHandle, &port));
    HandleError(Dart_IntegerToUint64(backlogHandle, &backlog));
    HandleError(Dart_BooleanValue(sharedHandle, &shared));

    // See if there is already a server bound to the port.
    long existingIndex = -1;
    std::string addressStringInstance(addressString);
    std::lock_guard<std::mutex> lock(serverInfoVectorMutex);


    if (shared)
    {
        #if __APPLE__
        #else
        for (unsigned long i = 0; i < serverInfoVector.size(); i++)
        {
            WingsServerInfo *server_info = serverInfoVector.at(i);

            if (server_info->addressString == addressStringInstance && server_info->port == port)
            {
                existingIndex = (long)i;
                break;
            }
        }
        #endif
    }

    if (existingIndex > -1)
    {
        // We found an existing socket, just return a reference to it.
        Dart_SetReturnValue(arguments, Dart_NewIntegerFromUint64(existingIndex));
        return;
    }
    else
    {
        // There's no existing server, so bind a new one, and add it to the serverInfoVector.
#ifndef WIN32
        int sockfd;
#else
        WSADATA wsaData;
        SOCKET ConnectSocket = INVALID_SOCKET;

        // Initialize Winsock
        iResult = WSAStartup(MAKEWORD(2, 2), &wsaData);
        if (iResult != 0)
        {
            Dart_Handle errorHandle = Dart_NewList(2);
            Dart_ListSetAt(errorHandle, 0, Dart_NewStringFromCString("WSAStartup failed."));
            Dart_ListSetAt(errorHandle, 1, Dart_NewInteger(iResult));
            Dart_ThrowException(errorHandle);
            return 1;
        }

        // TODO: Rest of Windows config:
        // https://docs.microsoft.com/en-us/windows/desktop/winsock/complete-client-code
#endif

        if (addressLength == 4)
        {
            // IPv4
            sockfd = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
        }
        else
        {
            // IPv6
            sockfd = socket(AF_INET6, SOCK_STREAM, IPPROTO_TCP);
        }

        if (sockfd < 0)
        {
            Dart_Handle errorHandle = Dart_NewList(3);
            Dart_ListSetAt(errorHandle, 0, Dart_NewStringFromCString("Failed to create socket."));
            Dart_ListSetAt(errorHandle, 1, Dart_NewStringFromCString(strerror(errno)));
            Dart_ListSetAt(errorHandle, 2, Dart_NewInteger(errno));
            Dart_ThrowException(errorHandle);
            return;
        }

        int i = 1;
        int ret = setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, &i, sizeof(i));

        if (ret < 0)
        {

            Dart_Handle errorHandle = Dart_NewList(3);
            Dart_ListSetAt(errorHandle, 0, Dart_NewStringFromCString("Cannot reuse address for socket."));
            Dart_ListSetAt(errorHandle, 1, Dart_NewStringFromCString(strerror(errno)));
            Dart_ListSetAt(errorHandle, 2, Dart_NewInteger(errno));
            Dart_ThrowException(errorHandle);
            return;
        }

#if __APPLE__
        ret = setsockopt(sockfd, SOL_SOCKET, SO_REUSEPORT, &i, sizeof(i));

        if (ret < 0)
        {
            Dart_ThrowException(Dart_NewStringFromCString("Cannot reuse port for socket."));
            return;
        }
#endif

        if (addressLength > 4)
        {
            struct sockaddr_in6 v6
            {
            };
            memset(&v6, 0, sizeof(v6));
            v6.sin6_family = AF_INET6;
            v6.sin6_port = htons((uint16_t)port);
            ret = inet_pton(v6.sin6_family, addressString, &v6.sin6_addr.s6_addr);

            if (ret >= 0)
                ret = bind(sockfd, (const sockaddr *)&v6, sizeof(v6));
        }
        else
        {
            struct sockaddr_in v4
            {
            };
            memset(&v4, 0, sizeof(v4));
            v4.sin_family = AF_INET;
            v4.sin_port = htons((uint16_t)port);
            v4.sin_addr.s_addr = inet_addr(addressString);

            if (ret >= 0)
                ret = bind(sockfd, (const sockaddr *)&v4, sizeof(v4));
            //ret = inet_pton(family, host, &v4.sin_addr);
        }

        /*if (ret < 1) {
            Dart_ThrowException(Dart_NewStringFromCString("Cannot parse IP address."));
            return;
        }*/

        //if (bind(sock, (const sockaddr *) &serveraddr, sizeof(serveraddr)) < 0) {
        if (ret < 0)
        {
            Dart_Handle errorHandle = Dart_NewList(3);
            Dart_ListSetAt(errorHandle, 0, Dart_NewStringFromCString("Failed to bind socket."));
            Dart_ListSetAt(errorHandle, 1, Dart_NewStringFromCString(strerror(errno)));
            Dart_ListSetAt(errorHandle, 2, Dart_NewInteger(errno));
            Dart_ThrowException(errorHandle);
            return;
        }

        if (listen(sockfd, SOMAXCONN) < 0)
        {
            Dart_Handle errorHandle = Dart_NewList(3);
            Dart_ListSetAt(errorHandle, 0, Dart_NewStringFromCString("Failed to listen to bound socket."));
            Dart_ListSetAt(errorHandle, 1, Dart_NewStringFromCString(strerror(errno)));
            Dart_ListSetAt(errorHandle, 2, Dart_NewInteger(errno));
            Dart_ThrowException(errorHandle);
            return;
        }

        if (listen(sockfd, (int)backlog) < 0)
        {
            Dart_Handle errorHandle = Dart_NewList(3);
            Dart_ListSetAt(errorHandle, 0, Dart_NewStringFromCString("Failed to listen to bound socket."));
            Dart_ListSetAt(errorHandle, 1, Dart_NewStringFromCString(strerror(errno)));
            Dart_ListSetAt(errorHandle, 2, Dart_NewInteger(errno));
            Dart_ThrowException(errorHandle);
            return;
        }

        // Now that we've bound the socket, let's add it to the list.
        auto *server_info = new WingsServerInfo;
        server_info->sockfd = sockfd;
        server_info->port = port;
        server_info->ipv6 = addressLength > 4;
        server_info->addressString += addressStringInstance;
        Dart_SetReturnValue(arguments, Dart_NewIntegerFromUint64(serverInfoVector.size()));
        serverInfoVector.push_back(server_info);
    }
}