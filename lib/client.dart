library angel_websocket.client;

import 'dart:convert' show JSON;
import 'dart:html';
import 'shared.dart';

class Angel {
  String wsEndPoint;
  WebSocket _socket;

  Angel(String this.wsEndPoint) {
    _socket = new WebSocket(wsEndPoint);
  }

  AngelService service(String path) {
    return new AngelService._base(_socket, path.trim().replaceAll(new RegExp(r'(^\/+)|(\/+$)'), ''));
  }
}

class AngelService {
  WebSocket _socket;
  String path;

  AngelService._base(WebSocket this._socket, path) {}

  index([Map params]) {
    AngelMessage request = new AngelMessage(path, 'index', body: params);
    _socket.send(JSON.encode(request.toMap()));
  }
}