/// WebSocket plugin for Angel.
library angel_websocket;

const String ACTION_AUTHENTICATE = 'authenticate';
const String ACTION_INDEX = 'index';
const String ACTION_READ = 'read';
const String ACTION_CREATE = 'create';
const String ACTION_MODIFY = 'modify';
const String ACTION_UPDATE = 'update';
const String ACTION_REMOVE = 'remove';

const String EVENT_AUTHENTICATED = 'authenticated';
const String EVENT_ERROR = 'error';
const String EVENT_INDEXED = 'indexed';
const String EVENT_READ = 'read';
const String EVENT_CREATED = 'created';
const String EVENT_MODIFIED = 'modified';
const String EVENT_UPDATED = 'updated';
const String EVENT_REMOVED = 'removed';

/// The standard Angel service actions.
const List<String> ACTIONS = const [
  ACTION_INDEX,
  ACTION_READ,
  ACTION_CREATE,
  ACTION_MODIFY,
  ACTION_UPDATE,
  ACTION_REMOVE
];

/// The standard Angel service events.
const List<String> EVENTS = const [
  EVENT_INDEXED,
  EVENT_READ,
  EVENT_CREATED,
  EVENT_MODIFIED,
  EVENT_UPDATED,
  EVENT_REMOVED
];

/// A notification from the server that something has occurred.
class WebSocketEvent {
  String eventName;
  var data;

  WebSocketEvent({String this.eventName, this.data});

  factory WebSocketEvent.fromJson(Map data) =>
      new WebSocketEvent(eventName: data['eventName'].toString(), data: data['data']);

  Map toJson() {
    return {'eventName': eventName, 'data': data};
  }
}

/// A command sent to the server, usually corresponding to a service method.
class WebSocketAction {
  String id;
  String eventName;
  var data;
  var params;

  WebSocketAction(
      {String this.id, String this.eventName, this.data, this.params});

  factory WebSocketAction.fromJson(Map data) => new WebSocketAction(
      id: data['id'].toString(),
      eventName: data['eventName'].toString(),
      data: data['data'],
      params: data['params']);

  Map toJson() {
    return {'id': id, 'eventName': eventName, 'data': data, 'params': params};
  }
}
