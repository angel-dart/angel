part of angel_websocket.server;

class ExposeWs {
  final String eventName;

  const ExposeWs(this.eventName);
}

class WebSocketController extends Controller {
  Map<String, MethodMirror> _handlers = {};
  Map<String, Symbol> _handlerSymbols = {};
  AngelWebSocket ws;

  WebSocketController() : super();

  void broadcast(String eventName, data) {
    ws.batchEvent(new WebSocketEvent(eventName: eventName, data: data));
  }

  onConnect(WebSocketContext socket) {}

  onDisconnect(WebSocketContext socket) {}

  onAction(WebSocketAction action, WebSocketContext socket) async {}

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
