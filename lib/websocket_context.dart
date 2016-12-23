part of angel_websocket.server;

/// Represents a WebSocket session, with the original
/// [RequestContext] and [ResponseContext] attached.
class WebSocketContext {
  /// Use this to listen for events.
  _WebSocketEventTable on = new _WebSocketEventTable();

  /// The underlying [WebSocket] instance.
  final WebSocket io;

  /// The original [RequestContext].
  final RequestContext request;

  /// The original [ResponseContext].
  final ResponseContext response;

  StreamController<WebSocketAction> _onAction =
      new StreamController<WebSocketAction>();
  StreamController _onData = new StreamController();

  /// Fired on any [WebSocketAction];
  Stream<WebSocketAction> get onAction => _onAction.stream;

  /// Fired when any data is sent through [io].
  Stream get onData => _onData.stream;

  WebSocketContext(WebSocket this.io, RequestContext this.request,
      ResponseContext this.response);

  /// Sends an arbitrary [WebSocketEvent];
  void send(String eventName, data) {
    io.add(god.serialize(new WebSocketEvent(eventName: eventName, data: data)));
  }

  /// Sends an error event.
  void sendError(AngelHttpException error) => send(EVENT_ERROR, error.toJson());
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
