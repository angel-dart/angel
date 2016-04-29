///Exposes WebSocket functionality to Angel.
library angel_websocket.server;

import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'shared.dart';

_respond(AngelMessage message, Service service, Angel app) async {
  if (message.method == 'index') {
    return await service.index(message.body['query']);
  }

  else if (message.method == 'read') {
    return await service.read(message.body['id'], message.body['query']);
  }

  else if (message.method == 'modify') {
    return await service.modify(
        message.body['id'], message.body['data'] ?? {}, message.body['query']);
  }

  else if (message.method == 'update') {
    return await service.update(
        message.body['id'], message.body['data'] ?? {}, message.body['query']);
  }

  else if (message.method == 'remove') {
    return await service.remove(message.body['id'], message.body['query']);
  }

  else throw new AngelHttpException.NotImplemented(
        message: "This service does not support a \"${message
            .method}\" method.");
}

_handleMsg(WebSocket socket, Angel app) {
  return (msg) async {
    String text = msg.toString();
    try {
      AngelMessage incoming = new AngelMessage.fromMap(
          app.god.serializeToMap(text));
      try {
        Service service = app.service(incoming.service);
        if (service == null) {
          throw new AngelHttpException.NotFound(
              message: 'The requested service does not exist.');
        }

        // Now, let's respond. :)
        var result = await _respond(incoming, service, app);
        AngelMessage response = new AngelMessage(
            incoming.service, incoming.method, body: {'result': result});
        socket.add(app.god.serialize(response));
      } catch (e) {
        AngelHttpException err = (e is AngelHttpException)
            ? e
            : new AngelHttpException(e);
        AngelMessage response = new AngelMessage(
            incoming.service, incoming.method, body: err.toMap());
        socket.add(app.god.serialize(response));
      }
    } catch (e) {
      // If we are sent invalid data, we're not even going to
      // bother responding. :)
    }
  };
}

websocket({String endPoint: '/ws'}) {
  return (Angel app) async {
    app.get(endPoint, (RequestContext req, ResponseContext res) async {
      if (WebSocketTransformer.isUpgradeRequest(req.underlyingRequest)) {
        res
          ..end()
          ..willCloseItself = true;
        WebSocket socket = await WebSocketTransformer.upgrade(
            req.underlyingRequest);

        socket.listen(_handleMsg(socket, app));
      } else {
        throw new AngelHttpException.BadRequest(
            message: 'This endpoint is only available via WebSockets.');
      }
    });
  };
}