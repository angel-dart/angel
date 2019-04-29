#include <cstring>
#include <iostream>
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
    workerThread = nullptr;
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

void WingsSocket::start(Dart_NativeArguments arguments)
{
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
                                 Dart_CObject *message)
{

    WingsSocket *socket = nullptr;
    Dart_Port outPort = message->value.as_array.values[0]->value.as_send_port.id;
    Dart_CObject* ptrArg = message->value.as_array.values[1];

    if (ptrArg->type == Dart_CObject_kInt32)
    {
        auto as64 = (int64_t)ptrArg->value.as_int32;
        socket = (WingsSocket *)as64;
    }
    else
    {
        socket = (WingsSocket *)ptrArg->value.as_int64;
    }

    if (socket != nullptr)
    {
        int sock;
        unsigned long index = 0;
        sockaddr addr;
        socklen_t len;

        if ((sock = accept(socket->sockfd, &addr, &len)) != -1)
        {
            Dart_CObject obj;
            obj.type = Dart_CObject_kInt64;
            obj.value.as_int64 = sock;
            Dart_PostCObject(outPort, &obj);
            // Dispatch the fd to the next listener.
            // auto &ports = socket->sendPorts;
            // Dart_Port port = ports.at(index++);
            // if (index >= ports.size())
            //     index = 0;
            // Dart_Handle intHandle = Dart_NewInteger(sock);
            // Dart_Post(port, intHandle);
        }
    }
}