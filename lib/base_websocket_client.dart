import 'dart:async';
import 'dart:convert';
import 'package:angel_client/angel_client.dart';
import 'package:http/src/base_client.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'angel_websocket.dart';
export 'package:angel_client/angel_client.dart';
import 'package:angel_client/base_angel_client.dart';

final RegExp _straySlashes = new RegExp(r"(^/)|(/+$)");

/// An [Angel] client that operates across WebSockets.
abstract class BaseWebSocketClient extends BaseAngelClient {
  WebSocketChannel _socket;

  final StreamController _onData = new StreamController();
  final StreamController<WebSocketEvent> _onAllEvents =
      new StreamController<WebSocketEvent>();
  final StreamController<AngelHttpException> _onError =
      new StreamController<AngelHttpException>();
  final StreamController<Map<String, WebSocketEvent>> _onServiceEvent =
      new StreamController<Map<String, WebSocketEvent>>.broadcast();
  final StreamController<WebSocketChannelException>
      _onWebSocketChannelException =
      new StreamController<WebSocketChannelException>();

  /// Use this to handle events that are not standard.
  final WebSocketExtraneousEventHandler on =
      new WebSocketExtraneousEventHandler();

  /// Fired on all events.
  Stream<WebSocketEvent> get onAllEvents => _onAllEvents.stream;

  /// A broadcast stream of data coming from the [socket].
  ///
  /// Mostly just for internal use.
  Stream get onData => _onData.stream;

  /// Fired on errors.
  Stream<AngelHttpException> get onError => _onError.stream;

  /// Fired whenever an event is fired by a service.
  Stream<Map<String, WebSocketEvent>> get onServiceEvent =>
      _onServiceEvent.stream;

  /// Fired on [WebSocketChannelException]s.
  Stream<WebSocketChannelException> get onWebSocketChannelException =>
      _onWebSocketChannelException.stream;

  /// The [WebSocketChannel] underneath this instance.
  WebSocketChannel get socket => _socket;

  BaseWebSocketClient(http.BaseClient client, String basePath)
      : super(client, basePath) {}

  @override
  Future close() async => _socket.sink.close(status.goingAway);

  /// Connects the WebSocket.
  Future<WebSocketChannel> connect() async {
    _socket = await getConnectedWebSocket();
    listen();
    return _socket;
  }

  /// Returns a new [WebSocketChannel], ready to be listened on.
  ///
  /// This should be overriden by child classes, **NOT** [connect].
  Future<WebSocketChannel> getConnectedWebSocket();

  @override
  BaseWebSocketService service<T>(String path,
      {Type type, AngelDeserializer deserializer}) {
    String uri = path.toString().replaceAll(_straySlashes, '');
    return new BaseWebSocketService(socket, this, uri,
        deserializer: deserializer);
  }

  /// Starts listening for data.
  void listen() {
    _socket.stream.listen((data) {
      _onData.add(data);

      if (data is WebSocketChannelException) {
        _onWebSocketChannelException.add(data);
      } else if (data is String) {
        var json = JSON.decode(data);

        if (json is Map) {
          var event = new WebSocketEvent.fromJson(json);

          if (event.eventName?.isNotEmpty == true) {
            _onAllEvents.add(event);
            on._getStream(event.eventName).add(event);
          }

          if (event.eventName == EVENT_ERROR) {
            var error = new AngelHttpException.fromMap(event.data ?? {});
            _onError.add(error);
          } else if (event.eventName?.isNotEmpty == true) {
            var split = event.eventName
                .split("::")
                .where((str) => str.isNotEmpty)
                .toList();

            if (split.length >= 2) {
              var serviceName = split[0], eventName = split[1];
              _onServiceEvent.add({serviceName: event..eventName = eventName});
            }
          }
        }
      }
    });
  }

  /// Serializes data to JSON.
  serialize(x) => JSON.encode(x);

  /// Alternative form of [send]ing an action.
  void send(String eventName, WebSocketAction action) =>
      sendAction(action..eventName = eventName);

  /// Sends the given [action] on the [socket].
  void sendAction(WebSocketAction action) {
    socket.sink.add(serialize(action));
  }
}

/// A [Service] that asynchronously interacts with the server.
class BaseWebSocketService extends Service {
  /// The [BaseWebSocketClient] that spawned this service.
  @override
  final BaseWebSocketClient app;

  /// Used to deserialize JSON into typed data.
  final AngelDeserializer deserializer;

  /// The [WebSocketChannel] to listen to, and send data across.
  final WebSocketChannel socket;

  /// The service path to listen to.
  final String path;

  final StreamController<WebSocketEvent> _onAllEvents =
      new StreamController<WebSocketEvent>();
  final StreamController<WebSocketEvent> _onIndexed =
      new StreamController<WebSocketEvent>();
  final StreamController<WebSocketEvent> _onRead =
      new StreamController<WebSocketEvent>();
  final StreamController<WebSocketEvent> _onCreated =
      new StreamController<WebSocketEvent>();
  final StreamController<WebSocketEvent> _onModified =
      new StreamController<WebSocketEvent>();
  final StreamController<WebSocketEvent> _onUpdated =
      new StreamController<WebSocketEvent>();
  final StreamController<WebSocketEvent> _onRemoved =
      new StreamController<WebSocketEvent>();

  /// Fired on all events.
  Stream<WebSocketEvent> get onAllEvents => _onAllEvents.stream;

  /// Fired on `index` events.
  Stream<WebSocketEvent> get onIndexed => _onIndexed.stream;

  /// Fired on `read` events.
  Stream<WebSocketEvent> get onRead => _onRead.stream;

  /// Fired on `created` events.
  Stream<WebSocketEvent> get onCreated => _onCreated.stream;

  /// Fired on `modified` events.
  Stream<WebSocketEvent> get onModified => _onModified.stream;

  /// Fired on `updated` events.
  Stream<WebSocketEvent> get onUpdated => _onUpdated.stream;

  /// Fired on `removed` events.
  Stream<WebSocketEvent> get onRemoved => _onRemoved.stream;

  BaseWebSocketService(this.socket, this.app, this.path, {this.deserializer}) {
    listen();
  }

  /// Serializes an [action] to be sent over a WebSocket.
  serialize(WebSocketAction action) => JSON.encode(action);

  /// Deserializes data from a [WebSocketEvent].
  deserialize(x) {
    return deserializer != null ? deserializer(x) : x;
  }

  /// Deserializes the contents of an [event].
  WebSocketEvent transformEvent(WebSocketEvent event) {
    return event..data = deserialize(event.data);
  }

  /// Starts listening for events.
  void listen() {
    app.onServiceEvent.listen((map) {
      if (map.containsKey(path)) {
        var event = map[path];
        var transformed = transformEvent(event);

        _onAllEvents.add(event);

        switch (event.eventName) {
          case EVENT_INDEXED:
            _onIndexed.add(transformed);
            break;
          case EVENT_READ:
            _onRead.add(transformed);
            break;
          case EVENT_CREATED:
            _onCreated.add(transformed);
            break;
          case EVENT_MODIFIED:
            _onModified.add(transformed);
            break;
          case EVENT_UPDATED:
            _onUpdated.add(transformed);
            break;
          case EVENT_REMOVED:
            _onRemoved.add(transformed);
            break;
        }
      }
    });
  }

  /// Sends the given [action] on the [socket].
  void send(WebSocketAction action) {
    socket.sink.add(serialize(action));
  }

  @override
  Future<List> index([Map params]) async {
    socket.sink.add(serialize(new WebSocketAction(
        eventName: '$path::${ACTION_INDEX}', params: params ?? {})));
    return null;
  }

  @override
  Future read(id, [Map params]) async {
    socket.sink.add(serialize(new WebSocketAction(
        eventName: '$path::${ACTION_READ}', id: id, params: params ?? {})));
    return null;
  }

  @override
  Future create(data, [Map params]) async {
    socket.sink.add(serialize(new WebSocketAction(
        eventName: '$path::${ACTION_CREATE}',
        data: data,
        params: params ?? {})));
    return null;
  }

  @override
  Future modify(id, data, [Map params]) async {
    socket.sink.add(serialize(new WebSocketAction(
        eventName: '$path::${ACTION_MODIFY}',
        id: id,
        data: data,
        params: params ?? {})));
    return null;
  }

  @override
  Future update(id, data, [Map params]) async {
    socket.sink.add(serialize(new WebSocketAction(
        eventName: '$path::${ACTION_UPDATE}',
        id: id,
        data: data,
        params: params ?? {})));
    return null;
  }

  @override
  Future remove(id, [Map params]) async {
    socket.sink.add(serialize(new WebSocketAction(
        eventName: '$path::${ACTION_REMOVE}', id: id, params: params ?? {})));
    return null;
  }
}

/// Contains a dynamic Map of [WebSocketEvent] streams.
class WebSocketExtraneousEventHandler {
  Map<String, StreamController<WebSocketEvent>> _events = {};

  StreamController<WebSocketEvent> _getStream(String index) {
    if (_events[index] == null)
      _events[index] = new StreamController<WebSocketEvent>();

    return _events[index];
  }

  Stream<WebSocketEvent> operator [](String index) {
    if (_events[index] == null)
      _events[index] = new StreamController<WebSocketEvent>();

    return _events[index].stream;
  }
}
