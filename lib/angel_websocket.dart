library angel_websocket;

class WebSocketEvent {
  String id;
  String eventName;
  var data;

  WebSocketEvent({String this.id, String this.eventName, this.data});
}

class WebSocketAction {
  String id;
  String eventName;
  var data;
  var params;
}