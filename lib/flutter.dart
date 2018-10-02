/// Flutter-compatible WebSocket client library for the Angel framework.
library angel_websocket.flutter;

import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'base_websocket_client.dart';
export 'package:angel_client/angel_client.dart';
export 'angel_websocket.dart';

// final RegExp _straySlashes = new RegExp(r"(^/)|(/+$)");

/// Queries an Angel server via WebSockets.
class WebSockets extends BaseWebSocketClient {
  final List<WebSocketsService> _services = [];

  WebSockets(String path) : super(new http.IOClient(), path);

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
}
