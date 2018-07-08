//#include <memory>
#include <utility>
#include <dart_native_api.h>
#include "wings_thread.h"

void wingsThreadMain(wings_thread_info *info)
{
    auto *serverInfo = std::move(info->serverInfo);
    Dart_Port port = std::move(info->port);
    //delete info;

    while (true)
    {
        std::unique_lock<std::mutex> lock(serverInfo->mutex, std::defer_lock);

        sockaddr client_addr{};
        socklen_t client_addr_len;

        if (lock.try_lock())
        {
            int client = accept(serverInfo->sockfd, &client_addr, &client_addr_len);
            lock.unlock();

            if (client < 0)
            {
                // send_error(info->port, "Failed to accept client socket.");
                return;
            }

            //auto rq = std::make_shared<requestInfo>();
            auto *rq = new requestInfo;
            rq->ipv6 = serverInfo->ipv6;
            rq->sock = client;
            rq->addr = client_addr;
            rq->addr_len = client_addr_len;
            rq->port = port;
            handleRequest(rq);
        }
    }
}

int send_notification(http_parser *parser, int code)
{
    //if (parser == nullptr) return 0;
    auto *rq = (requestInfo *)parser->data;
    //if (rq == nullptr) return 0;

    Dart_CObject first{};
    Dart_CObject second{};
    first.type = second.type = Dart_CObject_kInt64;
    first.value.as_int64 = rq->sock;
    second.value.as_int64 = code;

    Dart_CObject *list[2]{&first, &second};
    Dart_CObject obj{};
    obj.type = Dart_CObject_kArray;
    obj.value.as_array.length = 2;
    obj.value.as_array.values = list;
    Dart_PostCObject(rq->port, &obj);
    return 0;
}

int send_string(http_parser *parser, char *str, size_t length, int code, bool as_typed_data = false)
{
    //if (parser == nullptr) return 0;
    auto *rq = (requestInfo *)parser->data;
    //if (rq == nullptr) return 0;
    auto *s = new char[length + 1];
    memset(s, 0, length + 1);

    Dart_CObject first{};
    Dart_CObject second{};
    Dart_CObject third{};
    first.type = second.type = Dart_CObject_kInt32;
    first.value.as_int32 = rq->sock;
    second.value.as_int32 = code;

    if (!as_typed_data)
    {
        third.type = Dart_CObject_kString;
        memcpy(s, str, length);
        third.value.as_string = s;
    }
    else
    {
        third.type = Dart_CObject_kExternalTypedData;
        third.type = Dart_CObject_kExternalTypedData;
        third.value.as_external_typed_data.type = Dart_TypedData_kUint8;
        third.value.as_external_typed_data.length = length;
        third.value.as_external_typed_data.data = (uint8_t *)str;
    }

    // Post the string back to Dart...
    Dart_CObject *list[3]{&first, &second, &third};
    Dart_CObject obj{};
    obj.type = Dart_CObject_kArray;
    obj.value.as_array.length = 3;
    obj.value.as_array.values = list;
    Dart_PostCObject(rq->port, &obj);
    delete[] s;
    return 0;
}

int send_oncomplete(http_parser *parser, int code)
{
    //if (parser == nullptr) return 0;
    auto *rq = (requestInfo *)parser->data;
    //if (rq == nullptr) return 0;

    Dart_CObject sockfd{};
    Dart_CObject command{};
    Dart_CObject method{};
    Dart_CObject major{};
    Dart_CObject minor{};
    Dart_CObject addr{};
    sockfd.type = command.type = method.type = major.type = minor.type = Dart_CObject_kInt32;
    addr.type = Dart_CObject_kExternalTypedData;
    sockfd.value.as_int32 = rq->sock;
    command.value.as_int32 = code;
    method.value.as_int32 = parser->method;
    major.value.as_int32 = parser->http_major;
    minor.value.as_int32 = parser->http_minor;
    addr.value.as_external_typed_data.type = Dart_TypedData_kUint8;
    addr.value.as_external_typed_data.length = rq->addr_len;

    if (rq->ipv6)
    {
        auto *v6 = (sockaddr_in6 *)&rq->addr;
        addr.value.as_external_typed_data.data = (uint8_t *)v6->sin6_addr.s6_addr;
    }
    else
    {
        auto *v4 = (sockaddr_in *)&rq->addr;
        addr.value.as_external_typed_data.data = (uint8_t *)&v4->sin_addr.s_addr;
    }

    Dart_CObject *list[6]{&sockfd, &command, &method, &major, &minor, &addr};
    Dart_CObject obj{};
    obj.type = Dart_CObject_kArray;
    obj.value.as_array.length = 6;
    obj.value.as_array.values = list;
    Dart_PostCObject(rq->port, &obj);
    //delete parser;
    return 0;
}

//void handleRequest(const std::shared_ptr<requestInfo> &rq)
void handleRequest(requestInfo* rq)
{
    size_t len = 80 * 1024, nparsed;
    char buf[len];
    ssize_t recved;
    memset(buf, 0, len);

    http_parser parser{};
    http_parser_init(&parser, HTTP_REQUEST);
    parser.data = rq; //rq.get();

    http_parser_settings settings{};

    settings.on_message_begin = [](http_parser *parser) {
        // std::cout << "mb" << std::endl;
        return send_notification(parser, 0);
    };

    settings.on_message_complete = [](http_parser *parser) {
        //std::cout << "mc" << std::endl;
        send_oncomplete(parser, 1);
        delete (requestInfo *)parser->data;
        //std::cout << "deleted rq!" << std::endl;
        return 0;
    };

    settings.on_url = [](http_parser *parser, const char *at, size_t length) {
        // std::cout << "url" << std::endl;
        return send_string(parser, (char *)at, length, 2);
    };

    settings.on_header_field = [](http_parser *parser, const char *at, size_t length) {
        // std::cout << "hf" << std::endl;
        return send_string(parser, (char *)at, length, 3);
    };

    settings.on_header_value = [](http_parser *parser, const char *at, size_t length) {
        // std::cout << "hv" << std::endl;
        return send_string(parser, (char *)at, length, 4);
    };

    settings.on_body = [](http_parser *parser, const char *at, size_t length) {
        // std::cout << "body" << std::endl;
        return send_string(parser, (char *)at, length, 5, true);
    };

    unsigned int isUpgrade = 0;

    // std::cout << "start" << std::endl;
    while ((recved = recv(rq->sock, buf, len, 0)) > 0)
    {
        if (isUpgrade)
        {
            send_string(&parser, buf, (size_t)recved, 7, true);
        }
        else
        {
            /* Start up / continue the parser.
             * Note we pass recved==0 to signal that EOF has been received.
             */
            nparsed = http_parser_execute(&parser, &settings, buf, (size_t)recved);

            if ((isUpgrade = parser.upgrade) == 1)
            {
                send_notification(&parser, 6);
            }
            else if (nparsed != recved)
            {
                close(rq->sock);
                return;
            }
        }

        memset(buf, 0, len);
    }
}