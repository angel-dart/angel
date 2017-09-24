/// Command-line WebSocket client library for the Angel framework.
library angel_websocket.io;

import 'dart:async';
import 'dart:io';
import 'package:angel_client/angel_client.dart';
import 'package:http/http.dart' as http;
import 'package:json_god/json_god.dart' as god;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'angel_websocket.dart';
import 'base_websocket_client.dart';
export 'package:angel_client/angel_client.dart';
export 'angel_websocket.dart';

final RegExp _straySlashes = new RegExp(r"(^/)|(/+$)");

/// Queries an Angel server via WebSockets.
class WebSockets extends BaseWebSocketClient {
  final List<IoWebSocketsService> _services = [];

  WebSockets(String path) : super(new http.Client(), path);

  @override
  Stream<String> authenticateViaPopup(String url, {String eventName: 'token'}) {
    throw new UnimplementedError(
        'Opening popup windows is not supported in the `dart:io` client.');
  }

  @override
  Future close() {
    for (var service in _services) {
      service.close();
    }

    return super.close();
  }

  @override
  Future<WebSocketChannel> getConnectedWebSocket() async {
    var socket = await WebSocket.connect(basePath,
        headers: authToken?.isNotEmpty == true
            ? {'Authorization': 'Bearer $authToken'}
            : {});
    return new IOWebSocketChannel(socket);
  }

  @override
  IoWebSocketsService service(String path,
      {Type type, AngelDeserializer deserializer}) {
    String uri = path.replaceAll(_straySlashes, '');
    return new IoWebSocketsService(socket, this, uri, type);
  }

  @override
  serialize(x) => god.serialize(x);
}

class IoWebSocketsService extends WebSocketsService {
  final Type type;

  IoWebSocketsService(WebSocketChannel socket, Angel app, String uri, this.type)
      : super(socket, app, uri);

  @override
  serialize(WebSocketAction action) => god.serialize(action);

  @override
  deserialize(x) {
    if (type != null && type != dynamic) {
      return god.deserializeDatum(x, outputType: type);
    } else
      return super.deserialize(x);
  }
}
