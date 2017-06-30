/// Server-side support for WebSockets.
library angel_websocket.server;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:mirrors';
import 'package:angel_auth/angel_auth.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:json_god/json_god.dart' as god;
import 'package:merge_map/merge_map.dart';
import 'angel_websocket.dart';
export 'angel_websocket.dart';

part 'websocket_context.dart';

part 'websocket_controller.dart';

/// Used to assign routes to a given handler.
typedef AngelWebSocketRegisterer(Angel app, RequestHandler handler);

/// Broadcasts events from [HookedService]s, and handles incoming [WebSocketAction]s.
class AngelWebSocket extends AngelPlugin {
  Angel _app;
  List<WebSocketContext> _clients = [];
  final List<String> _servicesAlreadyWired = [];

  final StreamController<WebSocketAction> _onAction =
  new StreamController<WebSocketAction>();
  final StreamController _onData = new StreamController();
  final StreamController<WebSocketContext> _onConnection =
  new StreamController<WebSocketContext>.broadcast();
  final StreamController<WebSocketContext> _onDisconnect =
  new StreamController<WebSocketContext>.broadcast();

  /// If this is not `true`, then all client-side service parameters will be
  /// discarded, other than `params['query']`.
  final bool allowClientParams;

  /// If `true`, then clients can authenticate their WebSockets by sending a valid JWT.
  final bool allowAuth;

  /// Include debug information, and send error information across WebSockets.
  final bool debug;

  bool _sendErrors;

  /// Send error information across WebSockets, without including [debug] information..
  bool get sendErrors => _sendErrors == true;

  /// Registers this instance as a route on the server.
  final AngelWebSocketRegisterer register;

  /// A list of clients currently connected to this server via WebSockets.
  List<WebSocketContext> get clients => new List.unmodifiable(_clients);

  /// Services that have already been hooked to fire socket events.
  List<String> get servicesAlreadyWired =>
      new List.unmodifiable(_servicesAlreadyWired);

  /// The endpoint that users should connect a WebSocket to.
  final String endpoint;

  /// Used to notify other nodes of an event's firing. Good for scaled applications.
  final WebSocketSynchronizer synchronizer;

  /// Fired on any [WebSocketAction].
  Stream<WebSocketAction> get onAction => _onAction.stream;

  /// Fired whenever a WebSocket sends data.
  Stream get onData => _onData.stream;

  /// Fired on incoming connections.
  Stream<WebSocketContext> get onConnection => _onConnection.stream;

  /// Fired when a user disconnects.
  Stream<WebSocketContext> get onDisconnection => _onDisconnect.stream;

  /// Serializes data to WebSockets.
  ResponseSerializer serializer;

  /// Deserializes data from WebSockets.
  Function deserializer;

  AngelWebSocket({this.endpoint: '/ws',
    this.debug: false,
    bool sendErrors,
    this.allowClientParams: false,
    this.allowAuth: true,
    this.register,
    this.synchronizer,
    this.serializer,
    this.deserializer}) {
    _sendErrors = sendErrors;

    if (serializer == null) serializer = god.serialize;
    if (deserializer == null) deserializer = (params) => params;
  }

  serviceHook(String path) {
    return (HookedServiceEvent e) async {
      if (e.params != null && e.params['broadcast'] == false) return;

      var event = await transformEvent(e);
      event.eventName = "$path::${event.eventName}";

      _filter(WebSocketContext socket) {
        if (e.service.properties.containsKey('ws:filter'))
          return e.service.properties['ws:filter'](e, socket);
        else if (e.params != null && e.params.containsKey('ws:filter'))
          return e.params['ws:filter'](e, socket);
        else
          return true;
      }

      await batchEvent(event, filter: _filter);
    };
  }

  void _printDebug(String msg) {
    if (debug == true) print(msg);
  }

  /// Slates an event to be dispatched.
  Future batchEvent(WebSocketEvent event,
      {filter(WebSocketContext socket), bool notify: true}) async {
    // Default implementation will just immediately fire events
    _clients.forEach((client) async {
      var result = true;
      if (filter != null) result = await filter(client);
      if (result == true) {
        var serialized = event.toJson();
        _printDebug('Batching this event: $serialized');
        // print('Serialized: ' + JSON.encode(serialized));
        client.io.add((serializer ?? god.serialize)(event.toJson()));
      }
    });

    if (synchronizer != null && notify != false)
      synchronizer.notifyOthers(event);
  }

  /// Returns a list of events yet to be sent.
  Future<List<WebSocketEvent>> getBatchedEvents() async => [];

  /// Responds to an incoming action on a WebSocket.
  Future handleAction(WebSocketAction action, WebSocketContext socket) async {
    var split = action.eventName.split("::");

    if (split.length < 2)
      return socket.sendError(new AngelHttpException.badRequest());

    var service = _app.service(split[0]);

    if (service == null)
      return socket.sendError(new AngelHttpException.notFound(
          message: "No service \"${split[0]}\" exists."));

    var actionName = split[1];

    if (action.params is! Map) action.params = {};

    if (allowClientParams != true) {
      if (action.params['query'] is Map)
        action.params = {'query': action.params['query']};
      else
        action.params = {};
    }

    var params = mergeMap([
      (deserializer ?? (params) => params)(action.params),
      {
        "provider": Providers.WEBSOCKET,
        '__requestctx': socket.request,
        '__responsectx': socket.response
      }
    ]);

    try {
      if (actionName == ACTION_INDEX) {
        return socket.send(
            "${split[0]}::" + EVENT_INDEXED, await service.index(params));
      } else if (actionName == ACTION_READ) {
        return socket.send("${split[0]}::" + EVENT_READ,
            await service.read(action.id, params));
      } else if (actionName == ACTION_CREATE) {
        return new WebSocketEvent(
            eventName: "${split[0]}::" + EVENT_CREATED,
            data: await service.create(action.data, params));
      } else if (actionName == ACTION_MODIFY) {
        return new WebSocketEvent(
            eventName: "${split[0]}::" + EVENT_MODIFIED,
            data: await service.modify(action.id, action.data, params));
      } else if (actionName == ACTION_UPDATE) {
        return new WebSocketEvent(
            eventName: "${split[0]}::" + EVENT_UPDATED,
            data: await service.update(action.id, action.data, params));
      } else if (actionName == ACTION_REMOVE) {
        return new WebSocketEvent(
            eventName: "${split[0]}::" + EVENT_REMOVED,
            data: await service.remove(action.id, params));
      } else {
        return socket.sendError(new AngelHttpException.methodNotAllowed(
            message: "Method Not Allowed: \"$actionName\""));
      }
    } catch (e, st) {
      if (e is AngelHttpException)
        return socket.sendError(e);
      else if (debug == true || _sendErrors == true)
        socket.sendError(new AngelHttpException(e,
            message: e.toString(), stackTrace: st, errors: [st.toString()]));
      else
        socket.sendError(new AngelHttpException(e));
    }
  }

  /// Authenticates a [WebSocketContext].
  Future handleAuth(WebSocketAction action, WebSocketContext socket) async {
    if (allowAuth != false &&
        action.eventName == ACTION_AUTHENTICATE &&
        action.params['query'] is Map &&
        action.params['query']['jwt'] is String) {
      try {
        var auth = socket.request.grab<AngelAuth>(AngelAuth);
        var jwt = action.params['query']['jwt'] as String;
        AuthToken token;

        token = new AuthToken.validate(jwt, auth.hmac);
        var user = await auth.deserializer(token.userId);
        var req = socket.request;
        req..inject(AuthToken, req.properties['token'] = token)..inject(
            user.runtimeType, req.properties["user"] = user);
        socket.send(EVENT_AUTHENTICATED,
            {'token': token.serialize(auth.hmac), 'data': user});
      } catch (e, st) {
        // Send an error
        if (e is AngelHttpException)
          socket.sendError(e);
        else if (debug == true || _sendErrors == true)
          socket.sendError(new AngelHttpException(e,
              message: e.toString(), stackTrace: st, errors: [st.toString()]));
        else
          socket.sendError(new AngelHttpException(e));
      }
    } else {
      socket.sendError(new AngelHttpException.badRequest(
          message: 'No JWT provided for authentication.'));
    }
  }

  /// Hooks a service up to have its events broadcasted.
  hookupService(Pattern _path, HookedService service) {
    String path = _path.toString();
    service.after([
      HookedServiceEvent.CREATED,
      HookedServiceEvent.MODIFIED,
      HookedServiceEvent.UPDATED,
      HookedServiceEvent.REMOVED
    ], serviceHook(path));
    _servicesAlreadyWired.add(path);
  }

  /// Runs before firing [onConnection].
  Future handleConnect(WebSocketContext socket) async {}

  /// Handles incoming data from a WebSocket.
  handleData(WebSocketContext socket, data) async {
    try {
      socket._onData.add(data);
      var fromJson = JSON.decode(data);
      var action = new WebSocketAction.fromJson(fromJson);
      _onAction.add(action);

      if (action.eventName == null ||
          action.eventName is! String ||
          action.eventName.isEmpty) {
        throw new AngelHttpException.badRequest();
      }

      if (fromJson is Map && fromJson.containsKey("eventName")) {
        socket._onAction.add(new WebSocketAction.fromJson(fromJson));
        socket.on
            ._getStreamForEvent(fromJson["eventName"].toString())
            .add(fromJson["data"]);
      }

      if (action.eventName == ACTION_AUTHENTICATE)
        await handleAuth(action, socket);

      if (action.eventName.contains("::")) {
        var split = action.eventName.split("::");

        if (split.length >= 2) {
          if (ACTIONS.contains(split[1])) {
            var event = handleAction(action, socket);
            if (event is Future) event = await event;
          }
        }
      }
    } catch (e, st) {
      // Send an error
      if (e is AngelHttpException)
        socket.sendError(e);
      else if (debug == true || _sendErrors == true)
        socket.sendError(new AngelHttpException(e,
            message: e.toString(), stackTrace: st, errors: [st.toString()]));
      else
        socket.sendError(new AngelHttpException(e));
    }
  }

  /// Transforms a [HookedServiceEvent], so that it can be broadcasted.
  Future<WebSocketEvent> transformEvent(HookedServiceEvent event) async {
    return new WebSocketEvent(eventName: event.eventName, data: event.result);
  }

  /// Hooks any [HookedService]s that are not being broadcasted yet.
  wireAllServices(Angel app) {
    for (Pattern key in app.services.keys.where((x) {
      return !_servicesAlreadyWired.contains(x) &&
          app.services[x] is HookedService;
    })) {
      hookupService(key, app.services[key]);
    }
  }

  @override
  Future call(Angel app) async {
    if (_sendErrors == null) _sendErrors = app.isProduction;

    _app = app..container.singleton(this);

    if (runtimeType != AngelWebSocket)
      app.container.singleton(this, as: AngelWebSocket);

    // Set up services
    wireAllServices(app);

    app.onService.listen((_) {
      wireAllServices(app);
    });

    handler(RequestContext req, ResponseContext res) async {
      if (!WebSocketTransformer.isUpgradeRequest(req.io))
        throw new AngelHttpException.badRequest();

      res
        ..willCloseItself = true
        ..end();

      var ws = await WebSocketTransformer.upgrade(req.io);
      var socket = new WebSocketContext(ws, req, res);
      _clients.add(socket);
      await handleConnect(socket);

      _onConnection.add(socket);

      req
        ..properties['socket'] = socket
        ..inject(WebSocketContext, socket);

      ws.listen((data) {
        _onData.add(data);
        handleData(socket, data);
      }, onDone: () {
        _onDisconnect.add(socket);
        _clients.remove(ws);
      }, onError: (e) {
        _onDisconnect.add(socket);
        _clients.remove(ws);
      }, cancelOnError: true);
    }

    _register() {
      if (register != null)
        return register(app, handler);
      else
        app.get(endpoint, handler);
    }

    await _register();

    if (synchronizer != null) {
      synchronizer.stream.listen((e) => batchEvent(e, notify: false));
    }
  }
}

/// Notifies other nodes of outgoing WWebSocket events, and listens for
/// notifications from other nodes.
abstract class WebSocketSynchronizer {
  Stream<WebSocketEvent> get stream;

  void notifyOthers(WebSocketEvent e);
}
