part of angel_websocket.server;

/// Represents a WebSocket session, with the original
/// [RequestContext] and [ResponseContext] attached.
class WebSocketContext {
  /// Use this to listen for events.
  _WebSocketEventTable on = new _WebSocketEventTable();

  /// The underlying [WebSocketChannel].
  final WebSocketChannel channel;

  /// The original [RequestContext].
  final RequestContext request;

  /// The original [ResponseContext].
  final ResponseContext response;

  StreamController<WebSocketAction> _onAction =
      new StreamController<WebSocketAction>();

  StreamController<Null> _onClose = new StreamController<Null>();

  StreamController _onData = new StreamController();

  /// Fired on any [WebSocketAction];
  Stream<WebSocketAction> get onAction => _onAction.stream;

  /// Fired once the underlying [WebSocket] closes.
  Stream<Null> get onClose => _onClose.stream;

  /// Fired when any data is sent through [channel].
  Stream get onData => _onData.stream;

  WebSocketContext(this.channel, this.request, this.response);

  /// Closes the underlying [WebSocket].
  Future close([int code, String reason]) async {
    await channel.sink.close(code, reason);
    _onAction.close();
    _onData.close();
    _onClose.add(null);
    _onClose.close();
  }

  /// Sends an arbitrary [WebSocketEvent];
  void send(String eventName, data) {
    channel.sink.add(
        god.serialize(new WebSocketEvent(eventName: eventName, data: data)));
  }

  /// Sends an error event.
  void sendError(AngelHttpException error) => send(EVENT_ERROR, error.toJson());
}

class _WebSocketEventTable {
  Map<String, StreamController<Map>> _handlers = {};

  StreamController<Map> _getStreamForEvent(eventName) {
    if (!_handlers.containsKey(eventName))
      _handlers[eventName] = new StreamController<Map>();
    return _handlers[eventName];
  }

  Stream<Map> operator [](String key) => _getStreamForEvent(key).stream;
}
