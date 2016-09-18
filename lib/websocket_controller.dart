part of angel_websocket.server;

class ExposeWs {
  final String eventName;

  const ExposeWs(this.eventName);
}

class WebSocketController extends Controller {
  Map<String, MethodMirror> _handlers = {};
  Map<String, Symbol> _handlerSymbols = {};
  InstanceMirror _instanceMirror;
  AngelWebSocket ws;

  WebSocketController():super() {
    _instanceMirror = reflect(this);
  }

  @override
  Future call(Angel app) async {
    await super.call(app);

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
      await onConnect(socket);

      socket.onData.listen(onData);

      socket.onAll.listen((Map data) async {
        await onAllEvents(data);

        if (_handlers.containsKey(data["eventName"])) {
          var methodMirror = _handlers[data["eventName"]];
          try {
            // Load parameters, and execute
            List args = [];

            for (int i = 0; i < methodMirror.parameters.length; i++) {
              ParameterMirror parameter = methodMirror.parameters[i];
              String name = MirrorSystem.getName(parameter.simpleName);

              if (parameter.type.reflectedType == RequestContext ||
                  name == "req")
                args.add(socket.requestContext);
              else if (parameter.type.reflectedType == ResponseContext ||
                  name == "res")
                args.add(socket.responseContext);
              else if (parameter.type == AngelWebSocket)
                args.add(socket);
              else {
                if (socket.requestContext.params.containsKey(name)) {
                  args.add(socket.requestContext.params[name]);
                } else {
                  try {
                    args.add(app.container.make(parameter.type.reflectedType));
                    continue;
                  } catch (e) {
                    throw new AngelHttpException.BadRequest(
                        message: "Missing parameter '$name'");
                  }
                }
              }
            }

            await _instanceMirror.invoke(_handlerSymbols[data["eventName"]], args);
          } catch (e) {
            // Send an error
            if (e is AngelHttpException)
              socket.sendError(e);
            else
              socket.sendError(new AngelHttpException(e));
          }
        }
      });
    });

    ws.onDisconnection.listen(onDisconnect);
  }

  void broadcast(String eventName, data) {
    ws.batchEvent(new WebSocketEvent(eventName: eventName, data: data));
  }

  Future onConnect(WebSocketContext socket) async {}

  Future onDisconnect(WebSocketContext socket) async {}

  Future onAllEvents(Map data) async {}

  void onData(data) {}
}
