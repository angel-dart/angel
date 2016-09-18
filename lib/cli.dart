import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:angel_client/angel_client.dart';
import 'package:angel_framework/angel_framework.dart' as srv;
import 'package:angel_websocket/angel_websocket.dart';
import 'package:json_god/json_god.dart' as god;
export 'package:angel_client/angel_client.dart';
export 'package:angel_websocket/angel_websocket.dart';

class WebSocketClient extends Angel {
  WebSocket _socket;
  Map<Pattern, List<WebSocketService>> _services = {};
  WebSocket get underlyingSocket => _socket;
  _WebSocketEventTable on = new _WebSocketEventTable();

  WebSocketClient(String wsEndpoint) : super(wsEndpoint);

  onData(data) async {
    var fromJson = JSON.decode(data);
    print("a: $fromJson");
    var e = new WebSocketEvent(
        eventName: fromJson['eventName'], data: fromJson['data']);
    print("b: $e");
    var split = e.eventName.split("::");
    var serviceName = split[0];
    var services = _services[serviceName];

    if (serviceName == "error") {
      var exc = new srv.AngelHttpException(new Exception("Server-side error."));
      exc.statusCode = e.data['statusCode'];
      exc.message = e.data['message'];
      exc.errors = exc.errors ?? [];
      exc.errors.addAll(e.data['errors'] ?? []);
      throw exc;
    } else {
      on._getStreamForEvent(serviceName).add(e.data);

      if (services != null) {
        e.eventName = split[1];

        for (WebSocketService service in services) {
          service._onAllEvents.add(e);
          switch (e.eventName) {
            case srv.HookedServiceEvent.INDEXED:
              service._onIndexed.add(e);
              break;
            case srv.HookedServiceEvent.READ:
              service._onRead.add(e);
              break;
            case srv.HookedServiceEvent.CREATED:
              service._onCreated.add(e);
              break;
            case srv.HookedServiceEvent.MODIFIED:
              service._onModified.add(e);
              break;
            case srv.HookedServiceEvent.UPDATED:
              service._onUpdated.add(e);
              break;
            case srv.HookedServiceEvent.REMOVED:
              service._onRemoved.add(e);
              break;
            case "error":
              service._onError.add(e);
              break;
            default:
              if (service._on._events.containsKey(e.eventName))
                service._on._events[e.eventName].add(e);
              break;
          }
        }
      }
    }
  }

  Future connect() async {
    _socket = await WebSocket.connect(basePath);
    _socket.listen(onData);
  }

  void send(String eventName, data) {
    _socket.add(JSON.encode({"eventName": eventName, "data": data}));
  }

  @override
  Service service(Pattern path, {Type type}) {
    var service =
        new WebSocketService._base(path.toString(), this, _socket, type);
    if (_services[path.toString()] == null) _services[path.toString()] = [];

    _services[path.toString()].add(service);
    return service;
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

class _WebSocketServiceTransformer
    implements StreamTransformer<WebSocketEvent, WebSocketEvent> {
  Type _outputType;

  _WebSocketServiceTransformer.base(this._outputType);

  @override
  Stream<WebSocketEvent> bind(Stream<WebSocketEvent> stream) {
    var _stream = new StreamController<WebSocketEvent>();

    stream.listen((WebSocketEvent e) {
      if (_outputType != null && e.eventName != "error")
        e.data =
            god.deserialize(god.serialize(e.data), outputType: _outputType);
      _stream.add(e);
    });

    return _stream.stream;
  }
}

class WebSocketService extends Service {
  Type _outputType;
  String _path;
  _WebSocketServiceTransformer _transformer;
  WebSocket connection;

  WebSocketExtraneousEventHandler _on = new WebSocketExtraneousEventHandler();
  var _onAllEvents = new StreamController<WebSocketEvent>();
  var _onError = new StreamController<WebSocketEvent>();
  var _onIndexed = new StreamController<WebSocketEvent>();
  var _onRead = new StreamController<WebSocketEvent>();
  var _onCreated = new StreamController<WebSocketEvent>();
  var _onModified = new StreamController<WebSocketEvent>();
  var _onUpdated = new StreamController<WebSocketEvent>();
  var _onRemoved = new StreamController<WebSocketEvent>();

  WebSocketExtraneousEventHandler get on => _on;

  Stream<WebSocketEvent> get onAllEvents =>
      _onAllEvents.stream.transform(_transformer);

  Stream<WebSocketEvent> get onError => _onError.stream;

  Stream<WebSocketEvent> get onIndexed =>
      _onIndexed.stream.transform(_transformer);

  Stream<WebSocketEvent> get onRead => _onRead.stream.transform(_transformer);

  Stream<WebSocketEvent> get onCreated =>
      _onCreated.stream.transform(_transformer);

  Stream<WebSocketEvent> get onModified =>
      _onModified.stream.transform(_transformer);

  Stream<WebSocketEvent> get onUpdated =>
      _onUpdated.stream.transform(_transformer);

  Stream<WebSocketEvent> get onRemoved =>
      _onRemoved.stream.transform(_transformer);

  WebSocketService._base(
      String path, Angel app, WebSocket this.connection, Type _outputType) {
    this._path = path;
    this.app = app;
    this._outputType = _outputType;
    _transformer = new _WebSocketServiceTransformer.base(this._outputType);
  }

  @override
  Future<List> index([Map params]) async {
    connection.add(god.serialize(
        new WebSocketAction(eventName: "$_path::index", params: params)));
    return null;
  }

  @override
  Future read(id, [Map params]) async {
    connection.add(god.serialize(new WebSocketAction(
        eventName: "$_path::read", id: id, params: params)));
  }

  @override
  Future create(data, [Map params]) async {
    connection.add(god.serialize(new WebSocketAction(
        eventName: "$_path::create", data: data, params: params)));
  }

  @override
  Future modify(id, data, [Map params]) async {
    connection.add(god.serialize(new WebSocketAction(
        eventName: "$_path::modify", id: id, data: data, params: params)));
  }

  @override
  Future update(id, data, [Map params]) async {
    connection.add(god.serialize(new WebSocketAction(
        eventName: "$_path::update", id: id, data: data, params: params)));
  }

  @override
  Future remove(id, [Map params]) async {
    connection.add(god.serialize(new WebSocketAction(
        eventName: "$_path::remove", id: id, params: params)));
  }
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
