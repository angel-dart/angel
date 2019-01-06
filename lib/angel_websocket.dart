/// WebSocket plugin for Angel.
library angel_websocket;

/// A notification from the server that something has occurred.
class WebSocketEvent<Data> {
  String eventName;
  Data data;

  WebSocketEvent({String this.eventName, this.data});

  factory WebSocketEvent.fromJson(Map data) => new WebSocketEvent(
      eventName: data['eventName'].toString(), data: data['data'] as Data);

  WebSocketEvent<T> cast<T>() {
    if (T == Data) {
      return this as WebSocketEvent<T>;
    } else {
      return new WebSocketEvent<T>(eventName: eventName, data: data as T);
    }
  }

  Map<String, dynamic> toJson() {
    return {'eventName': eventName, 'data': data};
  }
}

/// A command sent to the server, usually corresponding to a service method.
class WebSocketAction {
  String id;
  String eventName;
  var data;
  Map<String, dynamic> params;

  WebSocketAction(
      {String this.id, String this.eventName, this.data, this.params});

  factory WebSocketAction.fromJson(Map data) => new WebSocketAction(
      id: data['id'].toString(),
      eventName: data['eventName'].toString(),
      data: data['data'],
      params: data['params'] as Map<String, dynamic>);

  Map<String, dynamic> toJson() {
    return {'id': id, 'eventName': eventName, 'data': data, 'params': params};
  }
}
