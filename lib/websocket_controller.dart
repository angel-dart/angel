part of angel_websocket.server;

/// Marks a method as available to WebSockets.
class ExposeWs {
  final String eventName;

  const ExposeWs(this.eventName);
}

/// A special controller that also supports WebSockets.
class WebSocketController extends Controller {
  /// The plug-in instance powering this controller.
  final AngelWebSocket ws;

  Map<String, MethodMirror> _handlers = {};
  Map<String, Symbol> _handlerSymbols = {};

  WebSocketController(this.ws) : super();

  /// Sends an event to all clients.
  void broadcast(String eventName, data, {filter(WebSocketContext socket)}) {
    ws.batchEvent(new WebSocketEvent(eventName: eventName, data: data),
        filter: filter);
  }

  /// Fired on new connections.
  onConnect(WebSocketContext socket) {}

  /// Fired on disconnections.
  onDisconnect(WebSocketContext socket) {}

  /// Fired on all incoming actions.
  onAction(WebSocketAction action, WebSocketContext socket) async {}

  /// Fired on arbitrary incoming data.
  onData(data, WebSocketContext socket) {}

  @override
  Future configureServer(Angel app) async {
    if (findExpose(app.container.reflector) != null)
      await super.configureServer(app);

    InstanceMirror instanceMirror = reflect(this);
    ClassMirror classMirror = reflectClass(this.runtimeType);
    classMirror.instanceMembers.forEach((sym, mirror) {
      if (mirror.isRegularMethod) {
        InstanceMirror exposeMirror = mirror.metadata.firstWhere(
            (mirror) => mirror.reflectee is ExposeWs,
            orElse: () => null);

        if (exposeMirror != null) {
          ExposeWs exposeWs = exposeMirror.reflectee as ExposeWs;
          _handlers[exposeWs.eventName] = mirror;
          _handlerSymbols[exposeWs.eventName] = sym;
        }
      }
    });

    ws.onConnection.listen((socket) async {
      if (!socket.request.container.has<WebSocketContext>()) {
        socket.request.container.registerSingleton<WebSocketContext>(socket);
      }

      await onConnect(socket);

      socket.onData.listen((data) => onData(data, socket));

      socket.onAction.listen((WebSocketAction action) async {
        var container = socket.request.container.createChild();
        container.registerSingleton<WebSocketAction>(action);

        try {
          await onAction(action, socket);

          if (_handlers.containsKey(action.eventName)) {
            var methodMirror = _handlers[action.eventName];
            var fn = instanceMirror.getField(methodMirror.simpleName).reflectee;
            return app.runContained(
                fn as Function, socket.request, socket.response, container);
          }
        } catch (e, st) {
          ws.catchError(e, st, socket);
        }
      });
    });

    ws.onDisconnection.listen(onDisconnect);
  }
}
