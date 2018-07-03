#ifndef ANGEL_WINGS_THREAD_H
#define ANGEL_WINGS_THREAD_H
#include <dart_api.h>
#include <http_parser.h>
#include "wings.h"

typedef struct
{
    Dart_Port port;
    WingsServerInfo *serverInfo;
} wings_thread_info;

typedef struct
{
    bool ipv6;
    int sock;
    sockaddr addr;
    socklen_t addr_len;
    Dart_Port port;
} requestInfo;

void wingsThreadMain(wings_thread_info *info);
void handleRequest(requestInfo *rq);

#endif