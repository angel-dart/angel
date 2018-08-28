/// Server-side support for WebSockets.
library angel_websocket.server;

import 'dart:async';
import 'dart:io';
import 'dart:mirrors';
import 'package:angel_auth/angel_auth.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:dart2_constant/convert.dart';
import 'package:json_god/json_god.dart' as god;
import 'package:merge_map/merge_map.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'angel_websocket.dart';
export 'angel_websocket.dart';

part 'websocket_context.dart';

part 'websocket_controller.dart';

typedef String WebSocketResponseSerializer(data);

/// Broadcasts events from [HookedService]s, and handles incoming [WebSocketAction]s.
class AngelWebSocket {
  List<WebSocketContext> _clients = <WebSocketContext>[];
  final List<String> _servicesAlreadyWired = [];

  final StreamController<WebSocketAction> _onAction =
      new StreamController<WebSocketAction>();
  final StreamController _onData = new StreamController();
  final StreamController<WebSocketContext> _onConnection =
      new StreamController<WebSocketContext>.broadcast();
  final StreamController<WebSocketContext> _onDisconnect =
      new StreamController<WebSocketContext>.broadcast();

  final Angel app;

  /// If this is not `true`, then all client-side service parameters will be
  /// discarded, other than `params['query']`.
  final bool allowClientParams;

  /// If `true`, then clients can authenticate their WebSockets by sending a valid JWT.
  final bool allowAuth;

  /// Send error information across WebSockets, without including debug information..
  final bool sendErrors;

  /// A list of clients currently connected to this server via WebSockets.
  List<WebSocketContext> get clients => new List.unmodifiable(_clients);

  /// Services that have already been hooked to fire socket events.
  List<String> get servicesAlreadyWired =>
      new List.unmodifiable(_servicesAlreadyWired);

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
  WebSocketResponseSerializer serializer;

  /// Deserializes data from WebSockets.
  Function deserializer;

  AngelWebSocket(this.app,
      {this.sendErrors: false,
      this.allowClientParams: false,
      this.allowAuth: true,
      this.synchronizer,
      this.serializer,
      this.deserializer}) {
    if (serializer == null) serializer = god.serialize;
    if (deserializer == null) deserializer = (params) => params;
  }

  HookedServiceEventListener serviceHook(String path) {
    return (HookedServiceEvent e) async {
      if (e.params != null && e.params['broadcast'] == false) return;

      var event = await transformEvent(e);
      event.eventName = "$path::${event.eventName}";

      _filter(WebSocketContext socket) {
        if (e.service.configuration.containsKey('ws:filter'))
          return e.service.configuration['ws:filter'](e, socket);
        else if (e.params != null && e.params.containsKey('ws:filter'))
          return e.params['ws:filter'](e, socket);
        else
          return true;
      }

      await batchEvent(event, filter: _filter);
    };
  }

  /// Slates an event to be dispatched.
  Future batchEvent(WebSocketEvent event,
      {filter(WebSocketContext socket), bool notify: true}) async {
    // Default implementation will just immediately fire events
    _clients.forEach((client) async {
      dynamic result = true;
      if (filter != null) result = await filter(client);
      if (result == true) {
        client.channel.sink.add((serializer ?? god.serialize)(event.toJson()));
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

    if (split.length < 2) {
      socket.sendError(new AngelHttpException.badRequest());
      return null;
    }

    var service = app.service(split[0]);

    if (service == null) {
      socket.sendError(new AngelHttpException.notFound(
          message: "No service \"${split[0]}\" exists."));
      return null;
    }

    var actionName = split[1];

    if (action.params is! Map) action.params = {};

    if (allowClientParams != true) {
      if (action.params['query'] is Map)
        action.params = {'query': action.params['query']};
      else
        action.params = {};
    }

    var params = mergeMap([
      ((deserializer ?? (params) => params)(action.params)) as Map,
      {
        "provider": Providers.websocket,
        '__requestctx': socket.request,
        '__responsectx': socket.response
      }
    ]);

    try {
      if (actionName == ACTION_INDEX) {
        socket.send(
            "${split[0]}::" + EVENT_INDEXED, await service.index(params));
        return null;
      } else if (actionName == ACTION_READ) {
        socket.send("${split[0]}::" + EVENT_READ,
            await service.read(action.id, params));
        return null;
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
        socket.sendError(new AngelHttpException.methodNotAllowed(
            message: "Method Not Allowed: \"$actionName\""));
        return null;
      }
    } catch (e, st) {
      catchError(e, st, socket);
    }
  }

  /// Authenticates a [WebSocketContext].
  Future handleAuth(WebSocketAction action, WebSocketContext socket) async {
    if (allowAuth != false &&
        action.eventName == ACTION_AUTHENTICATE &&
        action.params['query'] is Map &&
        action.params['query']['jwt'] is String) {
      try {
        var auth = socket.request.container.make<AngelAuth>();
        var jwt = action.params['query']['jwt'] as String;
        AuthToken token;

        token = new AuthToken.validate(jwt, auth.hmac);
        var user = await auth.deserializer(token.userId);
        socket.request
          ..container.registerSingleton<AuthToken>(token)
          ..container.registerSingleton(user, as: user.runtimeType as Type);
        socket.send(EVENT_AUTHENTICATED,
            {'token': token.serialize(auth.hmac), 'data': user});
      } catch (e, st) {
        catchError(e, st, socket);
      }
    } else {
      socket.sendError(new AngelHttpException.badRequest(
          message: 'No JWT provided for authentication.'));
    }
  }

  /// Hooks a service up to have its events broadcasted.
  hookupService(Pattern _path, HookedService service) {
    String path = _path.toString();
    service.after(
      [
        HookedServiceEvent.created,
        HookedServiceEvent.modified,
        HookedServiceEvent.updated,
        HookedServiceEvent.removed
      ],
      serviceHook(path),
    );
    _servicesAlreadyWired.add(path);
  }

  /// Runs before firing [onConnection].
  Future handleConnect(WebSocketContext socket) async {}

  /// Handles incoming data from a WebSocket.
  handleData(WebSocketContext socket, data) async {
    try {
      socket._onData.add(data);
      var fromJson = json.decode(data.toString());
      var action = new WebSocketAction.fromJson(fromJson as Map);
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
            .add(fromJson["data"] as Map);
      }

      if (action.eventName == ACTION_AUTHENTICATE)
        await handleAuth(action, socket);

      if (action.eventName.contains("::")) {
        var split = action.eventName.split("::");

        if (split.length >= 2) {
          if (ACTIONS.contains(split[1])) {
            var event = await handleAction(action, socket);
            if (event is Future) event = await event;
          }
        }
      }
    } catch (e, st) {
      catchError(e, st, socket);
    }
  }

  void catchError(e, StackTrace st, WebSocketContext socket) {
    // Send an error
    if (e is AngelHttpException) {
      socket.sendError(e);
      app.logger?.severe(e.message, e.error ?? e, e.stackTrace);
    } else if (sendErrors) {
      var err = new AngelHttpException(e,
          message: e.toString(), stackTrace: st, errors: [st.toString()]);
      socket.sendError(err);
      app.logger?.severe(err.message, e, st);
    } else {
      var err = new AngelHttpException(e);
      socket.sendError(err);
      app.logger?.severe(e.toString(), e, st);
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
      hookupService(key, app.services[key] as HookedService);
    }
  }

  /// Configures an [Angel] instance to listen for WebSocket connections.
  Future configureServer(Angel app) async {
    app..container.registerSingleton(this);

    if (runtimeType != AngelWebSocket)
      app..container.registerSingleton<AngelWebSocket>(this);

    // Set up services
    wireAllServices(app);

    app.onService.listen((_) {
      wireAllServices(app);
    });

    if (synchronizer != null) {
      synchronizer.stream.listen((e) => batchEvent(e, notify: false));
    }

    app.shutdownHooks.add((_) => synchronizer?.close());
  }

  /// Handles an incoming [WebSocketContext].
  Future handleClient(WebSocketContext socket) async {
    _clients.add(socket);
    await handleConnect(socket);

    _onConnection.add(socket);

    socket.request.container.registerSingleton<WebSocketContext>(socket);

    socket.channel.stream.listen(
      (data) {
        _onData.add(data);
        handleData(socket, data);
      },
      onDone: () {
        _onDisconnect.add(socket);
        _clients.remove(socket);
      },
      onError: (e) {
        _onDisconnect.add(socket);
        _clients.remove(socket);
      },
      cancelOnError: true,
    );
  }

  /// Handles an incoming HTTP request.
  Future<bool> handleRequest(RequestContext req, ResponseContext res) async {
    if (req is HttpRequestContext && res is HttpResponseContext) {
      if (!WebSocketTransformer.isUpgradeRequest(req.rawRequest))
        throw new AngelHttpException.badRequest();

      await res.detach();
      var ws = await WebSocketTransformer.upgrade(req.rawRequest);
      var channel = new IOWebSocketChannel(ws);
      var socket = new WebSocketContext(channel, req, res);
      handleClient(socket);
      return false;
    } else {
      throw new ArgumentError('Not an HTTP/1.1 RequestContext: $req');
    }
  }
}

/// Notifies other nodes of outgoing WWebSocket events, and listens for
/// notifications from other nodes.
abstract class WebSocketSynchronizer {
  Stream<WebSocketEvent> get stream;

  Future close() => new Future.value();

  void notifyOthers(WebSocketEvent e);
}
