/// Browser WebSocket client library for the Angel framework.
library angel_websocket.browser;

import 'dart:async';
import 'dart:html';
import 'package:angel_client/angel_client.dart';
import 'package:angel_http_exception/angel_http_exception.dart';
import 'package:http/browser_client.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/html.dart';
import 'base_websocket_client.dart';
export 'angel_websocket.dart';

final RegExp _straySlashes = new RegExp(r"(^/)|(/+$)");

/// Queries an Angel server via WebSockets.
class WebSockets extends BaseWebSocketClient {
  final List<BrowserWebSocketsService> _services = [];

  WebSockets(baseUrl,
      {bool reconnectOnClose = true, Duration reconnectInterval})
      : super(new http.BrowserClient(), baseUrl,
            reconnectOnClose: reconnectOnClose,
            reconnectInterval: reconnectInterval);

  @override
  Future close() {
    for (var service in _services) {
      service.close();
    }

    return super.close();
  }

  @override
  Stream<String> authenticateViaPopup(String url,
      {String eventName = 'token', String errorMessage}) {
    var ctrl = new StreamController<String>();
    var wnd = window.open(url, 'angel_client_auth_popup');

    Timer t;
    StreamSubscription<Event> sub;
    t = new Timer.periodic(new Duration(milliseconds: 500), (timer) {
      if (!ctrl.isClosed) {
        if (wnd.closed) {
          ctrl.addError(new AngelHttpException.notAuthenticated(
              message:
                  errorMessage ?? 'Authentication via popup window failed.'));
          ctrl.close();
          timer.cancel();
          sub?.cancel();
        }
      } else
        timer.cancel();
    });

    sub = window.on[eventName ?? 'token'].listen((e) {
      if (!ctrl.isClosed) {
        ctrl.add((e as CustomEvent).detail.toString());
        t.cancel();
        ctrl.close();
        sub.cancel();
      }
    });

    return ctrl.stream;
  }

  @override
  Future<WebSocketChannel> getConnectedWebSocket() {
    var url = websocketUri;

    if (authToken?.isNotEmpty == true) {
      url = url.replace(
          queryParameters: new Map<String, String>.from(url.queryParameters)
            ..['token'] = authToken);
    }

    var socket = new WebSocket(url.toString());
    var completer = new Completer<WebSocketChannel>();

    socket
      ..onOpen.listen((_) {
        if (!completer.isCompleted)
          return completer.complete(new HtmlWebSocketChannel(socket));
      })
      ..onError.listen((e) {
        if (!completer.isCompleted)
          return completer.completeError(e is ErrorEvent ? e.error : e);
      });

    return completer.future;
  }

  @override
  BrowserWebSocketsService<Id, Data> service<Id, Data>(String path,
      {Type type, AngelDeserializer<Data> deserializer}) {
    String uri = path.replaceAll(_straySlashes, '');
    return new BrowserWebSocketsService<Id, Data>(socket, this, uri,
        deserializer: deserializer);
  }
}

class BrowserWebSocketsService<Id, Data> extends WebSocketsService<Id, Data> {
  final Type type;

  BrowserWebSocketsService(WebSocketChannel socket, WebSockets app, String uri,
      {this.type, AngelDeserializer<Data> deserializer})
      : super(socket, app, uri, deserializer: deserializer);
}
