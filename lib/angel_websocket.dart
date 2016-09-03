library angel_websocket;

class WebSocketEvent {
  String eventName;
  var data;

  WebSocketEvent({String this.eventName, this.data});
}

class WebSocketAction {
  String id;
  String eventName;
  var data;
  var params;

  WebSocketAction({String this.id, String this.eventName, this.data, this.params});
}
