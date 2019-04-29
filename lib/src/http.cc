#include <iostream>
#include <http-parser/http_parser.h>
#include "angel_wings.h"
#include "wings_socket.h"
using namespace wings;

void Dart_WingsSocket_parseHttp(Dart_NativeArguments arguments)
{
    Dart_Port service_port =
        Dart_NewNativePort("WingsHttpCallback", &wingsHttpCallback, true);
    Dart_Handle send_port = Dart_NewSendPort(service_port);
    Dart_SetReturnValue(arguments, send_port);
}

void wingsHttpCallback(Dart_Port dest_port_id, Dart_CObject *message)
{
    int64_t fd = -1;
    Dart_Port outPort = message->value.as_array.values[0]->value.as_send_port.id;
    Dart_CObject *fdArg = message->value.as_array.values[1];

#define thePort (*((Dart_Port *)parser->data))
#define sendInt(n)                  \
    Dart_CObject obj;               \
    obj.type = Dart_CObject_kInt64; \
    obj.value.as_int64 = (n);       \
    Dart_PostCObject(thePort, &obj);
#define sendString()                               \
    if (length > 0)                                \
    {                                              \
        std::string str(at, length);               \
        Dart_CObject obj;                          \
        obj.type = Dart_CObject_kString;           \
        obj.value.as_string = (char *)str.c_str(); \
        Dart_PostCObject(thePort, &obj);           \
    }

    if (fdArg->type == Dart_CObject_kInt32)
    {
        fd = (int64_t)fdArg->value.as_int32;
    }
    else
    {
        fd = fdArg->value.as_int64;
    }

    if (fd != -1)
    {
        http_parser_settings settings;

        settings.on_message_begin = [](http_parser *parser) {
            return 0;
        };

        settings.on_headers_complete = [](http_parser *parser) {
            {
                sendInt(0);
            }
            {
            sendInt(parser->method);
            }
            return 0;
        };

        settings.on_message_complete = [](http_parser *parser) {
            sendInt(1);
            return 0;
        };

        settings.on_chunk_complete = [](http_parser *parser) {
            return 0;
        };

        settings.on_chunk_header = [](http_parser *parser) {
            return 0;
        };

        settings.on_url = [](http_parser *parser, const char *at, size_t length) {
            sendString();
            return 0;
        };

        settings.on_header_field = [](http_parser *parser, const char *at, size_t length) {
            sendString();
            return 0;
        };

        settings.on_header_value = [](http_parser *parser, const char *at, size_t length) {
            sendString();
            return 0;
        };

        settings.on_body = [](http_parser *parser, const char *at, size_t length) {
            sendString();
            return 0;
        };

        size_t len = 80 * 1024, nparsed = 0;
        char buf[len];
        ssize_t recved = 0;
        memset(buf, 0, sizeof(buf));
        // http_parser parser;
        auto *parser = (http_parser *)malloc(sizeof(http_parser));
        http_parser_init(parser, HTTP_BOTH);
        parser->data = &outPort;

        while ((recved = recv(fd, buf, len, 0)) >= 0)
        {
            if (false) // (isUpgrade)
            {
                // send_string(&parser, buf, (size_t)recved, 7, true);
            }
            else
            {
                /* Start up / continue the parser.
             * Note we pass recved==0 to signal that EOF has been received.
             */
                nparsed = http_parser_execute(parser, &settings, buf, recved);

                if (nparsed != recved)
                {
                    // TODO: End it...!
                }
                else if (recved == 0)
                {
                    break;
                }

                // if ((isUpgrade = parser.upgrade) == 1)
                // {
                //     send_notification(&parser, 6);
                // }
                // else if (nparsed != recved)
                // {
                //     close(rq->sock);
                //     return;
                // }
            }

            // memset(buf, 0, len);
        }
    }
}