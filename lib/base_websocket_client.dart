import 'dart:async';
import 'package:angel_client/angel_client.dart';
import 'package:http/src/base_client.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart';
import 'angel_websocket.dart';
export 'package:angel_client/angel_client.dart';
import 'package:angel_client/base_angel_client.dart';

final RegExp _straySlashes = new RegExp(r"(^/)|(/+$)");

abstract class BaseWebSocketClient extends BaseAngelClient {
  WebSocketChannel _socket;

  /// The [WebSocketChannel] underneath this instance.
  WebSocketChannel get socket => _socket;

  BaseWebSocketClient(http.BaseClient client, String basePath)
      : super(client, basePath);

  Future<WebSocketChannel> connect();

  @override
  BaseWebSocketService service<T>(String path,
      {Type type, AngelDeserializer deserializer}) {
    String uri = path.toString().replaceAll(_straySlashes, '');
    return new BaseWebSocketService(socket, this, uri,
        deserializer: deserializer)..listen();
  }
}

class BaseWebSocketService extends Service {
  @override
  final Angel app;
  final AngelDeserializer deserializer;
  final WebSocketChannel socket;
  final String uri;

  final StreamController<WebSocketEvent> _onMessage =
      new StreamController<WebSocketEvent>();
  final StreamController<WebSocketEvent> _onError =
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
  final WebSocketExtraneousEventHandler _on =
      new WebSocketExtraneousEventHandler();

  /// Use this to handle events that are not standard.
  WebSocketExtraneousEventHandler get on => _on;

  /// Fired on all events.
  Stream<WebSocketEvent> get onMessage => _onMessage.stream;

  /// Fired on errors.
  Stream<WebSocketEvent> get onError => _onError.stream;

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

  BaseWebSocketService(this.socket, this.app, this.uri, {this.deserializer});

  void listen() {
    socket.stream.listen((message) {
      print('Message: ${message.runtimeType}');
    });
  }

  @override
  Future<List> index([Map params]) {
    // TODO: implement index
  }

  @override
  Future read(id, [Map params]) {
    // TODO: implement read
  }

  @override
  Future create(data, [Map params]) {
    // TODO: implement create
  }

  @override
  Future modify(id, data, [Map params]) {
    // TODO: implement modify
  }

  @override
  Future update(id, data, [Map params]) {
    // TODO: implement update
  }

  @override
  Future remove(id, [Map params]) {
    // TODO: implement remove
  }
}

class WebSocketExtraneousEventHandler {
  Map<String, StreamController<WebSocketEvent>> _events = {};

  operator [](String index) {
    if (_events[index] == null)
      _events[index] = new StreamController<WebSocketEvent>();

    return _events[index].stream;
  }
}
