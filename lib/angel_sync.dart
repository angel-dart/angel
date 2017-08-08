import 'dart:async';
import 'package:angel_websocket/server.dart';
import 'package:pub_sub/pub_sub.dart' as pub_sub;

/// Synchronizes WebSockets using `package:pub_sub`.
class PubSubWebSocketSynchronizer extends WebSocketSynchronizer {
  /// The event name used to synchronize events on the server.
  static const String eventName = 'angel_sync::event';

  final StreamController<WebSocketEvent> _stream =
      new StreamController<WebSocketEvent>();

  pub_sub.ClientSubscription _subscription;

  final pub_sub.Client client;

  PubSubWebSocketSynchronizer(this.client) {
    client.subscribe(eventName).then((sub) {
      _subscription = sub
        ..listen((Map data) {
          if (!_stream.isClosed) _stream.add(new WebSocketEvent.fromJson(data));
        }, onError: _stream.addError);
    }).catchError(_stream.addError);
  }

  @override
  Stream<WebSocketEvent> get stream => _stream.stream;

  Future close() {
    if (_subscription != null) {
      _subscription.unsubscribe().then((_) => client.close());
    } else
      client.close();
    return new Future.value();
  }

  @override
  void notifyOthers(WebSocketEvent e) {
    client.publish(eventName, e.toJson()).catchError(_stream.addError);
  }
}
