library angel_websocket.server;

import 'dart:async';
import 'dart:io';
import 'dart:mirrors';
import 'package:angel_framework/angel_framework.dart';
import 'package:json_god/json_god.dart' as god;
import 'package:merge_map/merge_map.dart';
import 'package:uuid/uuid.dart';
import 'angel_websocket.dart';

part 'websocket_context.dart';

final AngelWebSocket websocket = new AngelWebSocket("/ws");

class Realtime {
  const Realtime();
}

class AngelWebSocket {
  Angel _app;
  List<WebSocket> _clients = [];
  List<String> servicesAlreadyWired = [];
  String endpoint;

  AngelWebSocket(String this.endpoint);

  _batchEvent(String path) {
    return (HookedServiceEvent e) async {
      var event = await transformEvent(e);
      event.eventName = "$path::${event.eventName}";
      await batchEvent(event);
    };
  }

  Future batchEvent(WebSocketEvent event) async {
    // Default implementation will just immediately fire events
    _clients.forEach((client) {
      client.add(god.serialize(event));
    });
  }

  Future<List<WebSocketEvent>> getBatchedEvents() async => [];

  Future handleAction(WebSocketAction action, WebSocketContext socket) async {
    var split = action.eventName.split("::");

    if (split.length < 2)
      return socket.sendError(new AngelHttpException.BadRequest());

    var service = _app.service(split[0]);

    if (service == null)
      return socket.sendError(new AngelHttpException.NotFound(
          message: "No service \"${split[0]}\" exists."));

    var eventName = split[1];

    var params = mergeMap([
      god.deserializeDatum(action.params),
      {"provider": Providers.WEBSOCKET}
    ]);
    try {
      if (eventName == "index") {
        return socket.send("${split[0]}::" + HookedServiceEvent.INDEXED,
            await service.index(params));
      } else if (eventName == "read") {
        return socket.send("${split[0]}::" + HookedServiceEvent.READ,
            await service.read(action.id, params));
      } else if (eventName == "create") {
        return new WebSocketEvent(
            eventName: "${split[0]}::" + HookedServiceEvent.CREATED,
            data: await service.create(action.data, params));
      } else if (eventName == "modify") {
        return new WebSocketEvent(
            eventName: "${split[0]}::" + HookedServiceEvent.MODIFIED,
            data: await service.modify(action.id, action.data, params));
      } else if (eventName == "update") {
        return new WebSocketEvent(
            eventName: "${split[0]}::" + HookedServiceEvent.UPDATED,
            data: await service.update(action.id, action.data, params));
      } else if (eventName == "remove") {
        return new WebSocketEvent(
            eventName: "${split[0]}::" + HookedServiceEvent.REMOVED,
            data: await service.remove(action.id, params));
      } else {
        return socket.sendError(new AngelHttpException.MethodNotAllowed(
            message: "Method Not Allowed: \"$eventName\""));
      }
    } catch (e) {
      if (e is AngelHttpException) return socket.sendError(e);

      return socket.sendError(new AngelHttpException(e));
    }
  }

  hookupService(Pattern _path, HookedService service) {
    String path = _path.toString();
    var batch = _batchEvent(path);

    service
      ..afterCreated.listen(batch)
      ..afterModified.listen(batch)
      ..afterUpdated.listen(batch)
      ..afterRemoved.listen(batch);

    servicesAlreadyWired.add(path);
  }

  onData(WebSocketContext socket, data) {
    try {
      WebSocketAction action =
          god.deserialize(data, outputType: WebSocketAction);

      if (action.eventName == null ||
          action.eventName is! String ||
          action.eventName.isEmpty) throw new AngelHttpException.BadRequest();

      var event = handleAction(action, socket);
      if (event is WebSocketEvent) {
        batchEvent(event);
      }
    } catch (e) {
      // Send an error
      socket.sendError(new AngelHttpException(e));
    }
  }

  Future<WebSocketEvent> transformEvent(HookedServiceEvent event) async {
    return new WebSocketEvent(eventName: event.eventName, data: event.result);
  }

  wireAllServices(Angel app) {
    for (Pattern key in app.services.keys.where((x) {
      return !servicesAlreadyWired.contains(x) &&
          app.services[x] is HookedService;
    })) {
      hookupService(key, app.services[key]);
    }
  }

  Future call(Angel app) async {
    this._app = app;

    // Set up services
    wireAllServices(app);

    app.onService.listen((_) {
      wireAllServices(app);
    });

    app.get(endpoint, (RequestContext req, ResponseContext res) async {
      if (!WebSocketTransformer.isUpgradeRequest(req.underlyingRequest))
        throw new AngelHttpException.BadRequest();

      var ws = await WebSocketTransformer.upgrade(req.underlyingRequest);
      var socket = new WebSocketContext(ws, req, res);

      ws.listen((data) {
        onData(socket, data);
      }, onDone: () {
        _clients.remove(ws);
      }, onError: (e) {
        _clients.remove(ws);
      }, cancelOnError: true);
    });
  }
}
