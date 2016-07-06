library angel_websocket.server;

import 'dart:async';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:json_god/json_god.dart' as god;
import 'package:uuid/uuid.dart';
import 'angel_websocket.dart';

typedef Future<bool> WebSocketFilter(WebsocketContext context);

List<WebsocketContext> _clients = [];
Uuid _uuid = new Uuid();

class WebsocketContext {
  WebSocket socket;
  RequestContext request;
  ResponseContext response;

  WebsocketContext(WebSocket this.socket, RequestContext this.request,
      ResponseContext this.response);
}

_broadcast(WebSocketEvent event) {
  String json = god.serialize(event);
  _clients.forEach((WebsocketContext client) {
    client.socket.add(json);
  });
}

_onData(Angel app) {
  return (data) {
    try {
      WebSocketAction action = god.deserialize(
          data, outputType: WebSocketAction);

      List<String> split = action.eventName.split("::");

      if (split.length >= 2) {
        Service service = app.service(split[0]);

        if (service != null) {
          String event = split[1];

          if (event == "index") {

          }
        }
      }
    } catch (e) {

    }
  };
}

_onError(e) {

}

class websocket {
  static Map<String, WebSocketFilter> filters = {};

  call({List<Pattern> endPoints: const['/ws']}) {
    return (Angel app) async {
      for (Pattern endPoint in endPoints) {
        app.all(endPoint, (RequestContext req, ResponseContext res) async {
          if (!WebSocketTransformer.isUpgradeRequest(req.underlyingRequest)) {
            res.write("This endpoint is only accessible via WebSockets.");
            res.end();
          } else {
            res
              ..willCloseItself = true
              ..end();
            WebSocket socket = await WebSocketTransformer.upgrade(
                req.underlyingRequest);
            WebsocketContext context = new WebsocketContext(socket, req, res);
            _clients.add(context);

            socket.listen(_onData(app), onError: _onError, onDone: () {
              _clients.remove(context);
            });
          }
        });

        app.services.forEach((Pattern path, Service service) {
          if (service is HookedService) {
            String pathName = (path is RegExp) ? path.pattern : path;
            List<HookedServiceEventDispatcher> dispatchers = [
              service.afterIndexed,
              service.afterCreated,
              service.afterRead,
              service.afterModified,
              service.afterUpdated,
              service.afterRemoved
            ];

            for (HookedServiceEventDispatcher dispatcher in dispatchers) {
              dispatcher.listen((HookedServiceEvent event) async {
                bool canContinue = true;
                String filterName = "$pathName::${event.eventName}";
                WebSocketFilter filter = filters[filterName];

                for (WebsocketContext client in _clients) {
                  if (filter != null)
                    canContinue = await filter(client);
                }

                if (canContinue) {
                  WebSocketEvent socketEvent = new WebSocketEvent(eventName: filterName,
                      data: event.result);
                  _broadcast(socketEvent);
                }
              });
            }
          }
        });
      }
    };
  }
}