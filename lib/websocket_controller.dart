part of angel_websocket.server;

/// Marks a method as available to WebSockets.
class ExposeWs {
  final String eventName;

  const ExposeWs(this.eventName);
}

/// A special controller that also supports WebSockets.
class WebSocketController extends Controller {
  Map<String, MethodMirror> _handlers = {};
  Map<String, Symbol> _handlerSymbols = {};

  /// The plug-in instance powering this controller.
  AngelWebSocket plugin;

  WebSocketController() : super();

  /// Sends an event to all clients.
  void broadcast(String eventName, data, {filter(WebSocketContext socket)}) {
    plugin.batchEvent(new WebSocketEvent(eventName: eventName, data: data),
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
  Future call(Angel app) async {
    await super.call(app);

    InstanceMirror instanceMirror = reflect(this);
    ClassMirror classMirror = reflectClass(this.runtimeType);
    classMirror.instanceMembers.forEach((sym, mirror) {
      if (mirror.isRegularMethod) {
        InstanceMirror exposeMirror = mirror.metadata.firstWhere(
            (mirror) => mirror.reflectee is ExposeWs,
            orElse: () => null);

        if (exposeMirror != null) {
          ExposeWs exposeWs = exposeMirror.reflectee;
          _handlers[exposeWs.eventName] = mirror;
          _handlerSymbols[exposeWs.eventName] = sym;
        }
      }
    });

    AngelWebSocket ws = app.container.make(AngelWebSocket);

    ws.onConnection.listen((socket) async {
      socket.request
        ..inject('socket', socket)
        ..inject(WebSocketContext, socket);

      await onConnect(socket);

      socket.onData.listen((data) => onData(data, socket));

      socket.onAction.listen((WebSocketAction action) async {
        socket.request.inject(WebSocketAction, action);
        await onAction(action, socket);

        if (_handlers.containsKey(action.eventName)) {
          try {
            var methodMirror = _handlers[action.eventName];
            var fn = instanceMirror.getField(methodMirror.simpleName).reflectee;
            return app.runContained(fn, socket.request, socket.response);
          } catch (e, st) {
            // Send an error
            if (e is AngelHttpException)
              socket.sendError(e);
            else if (ws.debug == true)
              socket.sendError(new AngelHttpException(e,
                  message: e.toString(),
                  stackTrace: st,
                  errors: [st.toString()]));
            else
              socket.sendError(new AngelHttpException(e));
          }
        }
      });
    });

    ws.onDisconnection.listen(onDisconnect);
  }
}
