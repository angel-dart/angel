/// Browser WebSocket client library for the Angel framework.
library angel_websocket.browser;

import 'dart:async';
import 'dart:html';
import 'package:angel_client/angel_client.dart';
import 'package:http/browser_client.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/html.dart';
import 'base_websocket_client.dart';
export 'package:angel_client/angel_client.dart';
export 'angel_websocket.dart';

final RegExp _straySlashes = new RegExp(r"(^/)|(/+$)");

/// Queries an Angel server via WebSockets.
class WebSockets extends BaseWebSocketClient {
  WebSockets(String path) : super(new http.BrowserClient(), path);

  @override
  Future<WebSocketChannel> getConnectedWebSocket() {
    var socket = new WebSocket(basePath);
    var completer = new Completer<WebSocketChannel>();

    socket
      ..onOpen.listen((_) {
        if (!completer.isCompleted)
          return completer.complete(new HtmlWebSocketChannel(socket));
      })
      ..onError.listen((ErrorEvent e) {
        if (!completer.isCompleted) return completer.completeError(e.error);
      });

    return completer.future;
  }

  @override
  WebSocketsService service<T>(String path,
      {Type type, AngelDeserializer deserializer}) {
    String uri = path.replaceAll(_straySlashes, '');
    return new WebSocketsService(socket, this, uri, null);
  }
}

class WebSocketsService extends BaseWebSocketService {
  final Type type;

  WebSocketsService(WebSocketChannel socket, Angel app, String uri, this.type)
      : super(socket, app, uri);
}
