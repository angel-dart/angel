part of angel_websocket.server;

class WebSocketContext {
  StreamController<Map> _onAll = new StreamController<Map>.broadcast();
  StreamController _onData = new StreamController.broadcast();
  _WebSocketEventTable on = new _WebSocketEventTable();
  Stream<Map> get onAll => _onAll.stream;
  Stream get onData => _onData.stream;
  WebSocket underlyingSocket;
  RequestContext requestContext;
  ResponseContext responseContext;

  WebSocketContext(WebSocket this.underlyingSocket,
      RequestContext this.requestContext, ResponseContext this.responseContext);

  send(String eventName, data) {
    underlyingSocket.add(
        god.serialize(new WebSocketEvent(eventName: eventName, data: data)));
  }

  sendError(AngelHttpException error) => send("error", error);
}

class _WebSocketEventTable {
  Map<String, StreamController<Map>> _handlers = {};

  StreamController<Map> _getStreamForEvent(eventName) {
    if (!_handlers.containsKey(eventName))
      _handlers[eventName] = new StreamController<Map>.broadcast();
    return _handlers[eventName];
  }

  Stream<Map> operator [](String key) => _getStreamForEvent(key).stream;
}
