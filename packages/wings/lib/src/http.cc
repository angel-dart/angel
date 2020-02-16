#include <cstring>

#include "angel_wings.h"
#include "wings_socket.h"
#include <http-parser/http_parser.h>
#include <iostream>
using namespace wings;

void Dart_WingsSocket_parseHttp(Dart_NativeArguments arguments) {
  Dart_Port service_port =
      Dart_NewNativePort("WingsHttpCallback", &wingsHttpCallback, true);
  Dart_Handle send_port = Dart_NewSendPort(service_port);
  Dart_SetReturnValue(arguments, send_port);
}

struct wingsHttp {
  Dart_Port port;
  std::string lastHeader;
};

void wingsHttpCallback(Dart_Port dest_port_id, Dart_CObject *message) {
  int64_t fd = -1;
  Dart_Port outPort = message->value.as_array.values[0]->value.as_send_port.id;
  Dart_CObject *fdArg = message->value.as_array.values[1];

  wingsHttp httpData = {outPort};

#define theStruct (*((wingsHttp *)parser->data))
#define thePort theStruct.port
#define sendInt(n)                                                             \
  {                                                                            \
    Dart_CObject obj;                                                          \
    obj.type = Dart_CObject_kInt64;                                            \
    obj.value.as_int64 = (n);                                                  \
    Dart_PostCObject(thePort, &obj);                                           \
  }
#define sendString(n)                                                          \
  if (length > 0) {                                                            \
    Dart_CObject typeObj;                                                      \
    typeObj.type = Dart_CObject_kInt32;                                        \
    typeObj.value.as_int32 = (n);                                              \
    std::string str(at, length);                                               \
    Dart_CObject strObj;                                                       \
    strObj.type = Dart_CObject_kString;                                        \
    strObj.value.as_string = (char *)str.c_str();                              \
    Dart_CObject *values[2] = {&typeObj, &strObj};                             \
    Dart_CObject out;                                                          \
    out.type = Dart_CObject_kArray;                                            \
    out.value.as_array.length = 2;                                             \
    out.value.as_array.values = values;                                        \
    Dart_PostCObject(thePort, &out);                                           \
  }

  if (fdArg->type == Dart_CObject_kInt32) {
    fd = (int64_t)fdArg->value.as_int32;
  } else {
    fd = fdArg->value.as_int64;
  }

  if (fd != -1) {
    http_parser_settings settings;

    settings.on_message_begin = [](http_parser *parser) { return 0; };

    settings.on_headers_complete = [](http_parser *parser) {
      Dart_CObject type;
      type.type = Dart_CObject_kInt32;
      type.value.as_int32 = 2;
      Dart_CObject value;
      value.type = Dart_CObject_kInt32;
      value.value.as_int32 = parser->method;
      Dart_CObject *values[2] = {&type, &value};
      Dart_CObject out;
      out.type = Dart_CObject_kArray;
      out.value.as_array.length = 2;
      out.value.as_array.values = values;
      Dart_PostCObject(thePort, &out);
      sendInt(100);
      return 0;
    };

    settings.on_message_complete = [](http_parser *parser) {
      sendInt(200);
      return 0;
    };

    settings.on_chunk_complete = [](http_parser *parser) { return 0; };

    settings.on_chunk_header = [](http_parser *parser) { return 0; };

    settings.on_url = [](http_parser *parser, const char *at, size_t length) {
      sendString(0);
      return 0;
    };

    settings.on_header_field = [](http_parser *parser, const char *at,
                                  size_t length) {
      theStruct.lastHeader = std::string(at, length);
      return 0;
    };

    settings.on_header_value = [](http_parser *parser, const char *at,
                                  size_t length) {
      if (!theStruct.lastHeader.empty()) {
        std::string vStr(at, length);
        Dart_CObject type;
        type.type = Dart_CObject_kInt32;
        type.value.as_int32 = 1;
        Dart_CObject name;
        name.type = Dart_CObject_kString;
        name.value.as_string = (char *)theStruct.lastHeader.c_str();
        Dart_CObject value;
        value.type = Dart_CObject_kString;
        value.value.as_string = (char *)vStr.c_str();
        Dart_CObject *values[3] = {&type, &name, &value};
        Dart_CObject out;
        out.type = Dart_CObject_kArray;
        out.value.as_array.length = 3;
        out.value.as_array.values = values;
        Dart_PostCObject(thePort, &out);
        theStruct.lastHeader.clear();
      }
      return 0;
    };

    settings.on_body = [](http_parser *parser, const char *at, size_t length) {
      Dart_CObject obj;
      obj.type = Dart_CObject_kTypedData;
      obj.value.as_typed_data.type = Dart_TypedData_kUint8;
      obj.value.as_typed_data.length = length;
      obj.value.as_typed_data.values = (uint8_t *)at;
      Dart_PostCObject(thePort, &obj);
      return 0;
    };

    size_t len = 80 * 1024, nparsed = 0;
    char buf[len];
    ssize_t recved = 0;
    memset(buf, 0, sizeof(buf));
    // http_parser parser;
    auto *parser = (http_parser *)malloc(sizeof(http_parser));
    http_parser_init(parser, HTTP_BOTH);
    parser->data = &httpData;

    while ((recved = recv(fd, buf, len, 0)) >= 0) {
      if (false) // (isUpgrade)
      {
        // send_string(&parser, buf, (size_t)recved, 7, true);
      } else {
        /* Start up / continue the parser.
         * Note we pass recved==0 to signal that EOF has been received.
         */
        nparsed = http_parser_execute(parser, &settings, buf, recved);

        if (nparsed != recved) {
          // TODO: End it...!
        } else if (recved == 0) {
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