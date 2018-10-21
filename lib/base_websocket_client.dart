import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:angel_client/angel_client.dart';
import 'package:angel_client/base_angel_client.dart';
import 'package:angel_http_exception/angel_http_exception.dart';
import 'package:http/src/base_client.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'angel_websocket.dart';

final RegExp _straySlashes = new RegExp(r"(^/)|(/+$)");

/// An [Angel] client that operates across WebSockets.
abstract class BaseWebSocketClient extends BaseAngelClient {
  Duration _reconnectInterval;
  WebSocketChannel _socket;
  final Queue<WebSocketAction> _queue = new Queue<WebSocketAction>();

  final StreamController _onData = new StreamController();
  final StreamController<WebSocketEvent> _onAllEvents =
      new StreamController<WebSocketEvent>();
  final StreamController<AngelAuthResult> _onAuthenticated =
      new StreamController<AngelAuthResult>();
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

  /// Fired whenever a WebSocket is successfully authenticated.
  Stream<AngelAuthResult> get onAuthenticated => _onAuthenticated.stream;

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

  /// If `true` (default), then the client will automatically try to reconnect to the server
  /// if the socket closes.
  final bool reconnectOnClose;

  /// The amount of time to wait between reconnect attempts. Default: 10 seconds.
  Duration get reconnectInterval => _reconnectInterval;

  BaseWebSocketClient(http.BaseClient client, String basePath,
      {this.reconnectOnClose: true, Duration reconnectInterval})
      : super(client, basePath) {
    _reconnectInterval = reconnectInterval ?? new Duration(seconds: 10);
  }

  @override
  Future close() async {
    await _socket.sink.close(status.goingAway);
    _onData.close();
    _onAllEvents.close();
    _onAuthenticated.close();
    _onError.close();
    _onServiceEvent.close();
    _onWebSocketChannelException.close();
  }

  /// Connects the WebSocket. [timeout] is optional.
  Future<WebSocketChannel> connect({Duration timeout}) async {
    if (timeout != null) {
      var c = new Completer<WebSocketChannel>();
      Timer timer;

      timer = new Timer(timeout, () {
        if (!c.isCompleted) {
          if (timer.isActive) timer.cancel();
          c.completeError(new TimeoutException(
              'WebSocket connection exceeded timeout of ${timeout.inMilliseconds} ms',
              timeout));
        }
      });

      getConnectedWebSocket().then((socket) {
        if (!c.isCompleted) {
          if (timer.isActive) timer.cancel();

          while (_queue.isNotEmpty) {
            var action = _queue.removeFirst();
            socket.sink.add(serialize(action));
          }

          c.complete(socket);
        }
      }).catchError((e, StackTrace st) {
        if (!c.isCompleted) {
          if (timer.isActive) timer.cancel();
          c.completeError(e, st);
        }
      });

      return await c.future.then((socket) {
        _socket = socket;
        listen();
      });
    } else {
      _socket = await getConnectedWebSocket();
      listen();
      return _socket;
    }
  }

  /// Returns a new [WebSocketChannel], ready to be listened on.
  ///
  /// This should be overriden by child classes, **NOT** [connect].
  Future<WebSocketChannel> getConnectedWebSocket();

  @override
  WebSocketsService<Id, Data> service<Id, Data>(String path,
      {Type type, AngelDeserializer<Data> deserializer}) {
    String uri = path.toString().replaceAll(_straySlashes, '');
    return new WebSocketsService<Id, Data>(socket, this, uri,
        deserializer: deserializer);
  }

  /// Starts listening for data.
  void listen() {
    _socket?.stream?.listen(
        (data) {
          _onData.add(data);

          if (data is WebSocketChannelException) {
            _onWebSocketChannelException.add(data);
          } else if (data is String) {
            var jsons = json.decode(data);

            if (jsons is Map) {
              var event = new WebSocketEvent.fromJson(jsons);

              if (event.eventName?.isNotEmpty == true) {
                _onAllEvents.add(event);
                on._getStream(event.eventName).add(event);
              }

              if (event.eventName == EVENT_ERROR) {
                var error =
                    new AngelHttpException.fromMap((event.data ?? {}) as Map);
                _onError.add(error);
              } else if (event.eventName == EVENT_AUTHENTICATED) {
                var authResult = new AngelAuthResult.fromMap(event.data as Map);
                _onAuthenticated.add(authResult);
              } else if (event.eventName?.isNotEmpty == true) {
                var split = event.eventName
                    .split("::")
                    .where((str) => str.isNotEmpty)
                    .toList();

                if (split.length >= 2) {
                  var serviceName = split[0], eventName = split[1];
                  _onServiceEvent
                      .add({serviceName: event..eventName = eventName});
                }
              }
            }
          }
        },
        cancelOnError: true,
        onDone: () {
          _socket = null;
          if (reconnectOnClose == true) {
            new Timer.periodic(reconnectInterval, (Timer timer) async {
              var result;

              try {
                result = await connect(timeout: reconnectInterval);
              } catch (e) {
                //
              }

              if (result != null) timer.cancel();
            });
          }
        });
  }

  /// Serializes data to JSON.
  serialize(x) => json.encode(x);

  /// Alternative form of [send]ing an action.
  void send(String eventName, WebSocketAction action) =>
      sendAction(action..eventName = eventName);

  /// Sends the given [action] on the [socket].
  void sendAction(WebSocketAction action) {
    if (_socket == null)
      _queue.addLast(action);
    else
      socket.sink.add(serialize(action));
  }

  /// Attempts to authenticate a WebSocket, using a valid JWT.
  void authenticateViaJwt(String jwt) {
    send(
        ACTION_AUTHENTICATE,
        new WebSocketAction(params: {
          'query': {'jwt': jwt}
        }));
  }
}

/// A [Service] that asynchronously interacts with the server.
class WebSocketsService<Id, Data> extends Service<Id, Data> {
  /// The [BaseWebSocketClient] that spawned this service.
  @override
  final BaseWebSocketClient app;

  /// Used to deserialize JSON into typed data.
  final AngelDeserializer<Data> deserializer;

  /// The [WebSocketChannel] to listen to, and send data across.
  final WebSocketChannel socket;

  /// The service path to listen to.
  final String path;

  final StreamController<WebSocketEvent> _onAllEvents =
      new StreamController<WebSocketEvent>();
  final StreamController _onIndexed = new StreamController();
  final StreamController<Data> _onRead = new StreamController<Data>();
  final StreamController<Data> _onCreated = new StreamController<Data>();
  final StreamController<Data> _onModified = new StreamController<Data>();
  final StreamController<Data> _onUpdated = new StreamController<Data>();
  final StreamController<Data> _onRemoved = new StreamController<Data>();

  /// Fired on all events.
  Stream<WebSocketEvent> get onAllEvents => _onAllEvents.stream;

  /// Fired on `index` events.
  Stream get onIndexed => _onIndexed.stream;

  /// Fired on `read` events.
  Stream<Data> get onRead => _onRead.stream;

  /// Fired on `created` events.
  Stream<Data> get onCreated => _onCreated.stream;

  /// Fired on `modified` events.
  Stream<Data> get onModified => _onModified.stream;

  /// Fired on `updated` events.
  Stream<Data> get onUpdated => _onUpdated.stream;

  /// Fired on `removed` events.
  Stream<Data> get onRemoved => _onRemoved.stream;

  WebSocketsService(this.socket, this.app, this.path, {this.deserializer}) {
    listen();
  }

  Future close() async {
    _onAllEvents.close();
    _onCreated.close();
    _onIndexed.close();
    _onModified.close();
    _onRead.close();
    _onRemoved.close();
    _onUpdated.close();
  }

  /// Serializes an [action] to be sent over a WebSocket.
  serialize(WebSocketAction action) => json.encode(action);

  /// Deserializes data from a [WebSocketEvent].
  Data deserialize(x) {
    return deserializer != null ? deserializer(x) : x as Data;
  }

  /// Deserializes the contents of an [event].
  WebSocketEvent<Data> transformEvent(WebSocketEvent<Data> event) {
    return event..data = deserialize(event.data);
  }

  /// Starts listening for events.
  void listen() {
    app.onServiceEvent.listen((map) {
      if (map.containsKey(path)) {
        var event = map[path].cast<Data>();
        var transformed = transformEvent(event).data;

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
    app.sendAction(action);
  }

  @override
  Future index([Map<String, dynamic> params]) async {
    app.sendAction(new WebSocketAction(
        eventName: '$path::${ACTION_INDEX}', params: params ?? {}));
    return null;
  }

  @override
  Future read(id, [Map<String, dynamic> params]) async {
    app.sendAction(new WebSocketAction(
        eventName: '$path::${ACTION_READ}',
        id: id.toString(),
        params: params ?? {}));
    return null;
  }

  @override
  Future create(data, [Map<String, dynamic> params]) async {
    app.sendAction(new WebSocketAction(
        eventName: '$path::${ACTION_CREATE}',
        data: data,
        params: params ?? {}));
    return null;
  }

  @override
  Future modify(id, data, [Map<String, dynamic> params]) async {
    app.sendAction(new WebSocketAction(
        eventName: '$path::${ACTION_MODIFY}',
        id: id.toString(),
        data: data,
        params: params ?? {}));
    return null;
  }

  @override
  Future update(id, data, [Map<String, dynamic> params]) async {
    app.sendAction(new WebSocketAction(
        eventName: '$path::${ACTION_UPDATE}',
        id: id.toString(),
        data: data,
        params: params ?? {}));
    return null;
  }

  @override
  Future remove(id, [Map<String, dynamic> params]) async {
    app.sendAction(new WebSocketAction(
        eventName: '$path::${ACTION_REMOVE}',
        id: id.toString(),
        params: params ?? {}));
    return null;
  }

  /// No longer necessary.
  @deprecated
  Service unwrap() => this;
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
