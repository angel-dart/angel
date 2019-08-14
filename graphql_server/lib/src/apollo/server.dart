import 'dart:async';
import 'remote_client.dart';
import 'transport.dart';

abstract class Server {
  final RemoteClient client;
  final Duration keepAliveInterval;
  final Completer _done = Completer();
  StreamSubscription<OperationMessage> _sub;
  bool _init = false;
  Timer _timer;

  Future get done => _done.future;

  Server(this.client, {this.keepAliveInterval}) {
    _sub = client.stream.listen(
        (msg) async {
          if ((msg.type == OperationMessage.gqlConnectionInit) && !_init) {
            try {
              Map connectionParams;
              if (msg.payload is Map) {
                connectionParams = msg.payload as Map;
              } else if (msg.payload != null) {
                throw FormatException(
                    '${msg.type} payload must be a map (object).');
              }

              var connect = await onConnect(client, connectionParams);
              if (!connect) throw false;
              _init = true;
              client.sink
                  .add(OperationMessage(OperationMessage.gqlConnectionAck));

              if (keepAliveInterval != null) {
                client.sink.add(
                    OperationMessage(OperationMessage.gqlConnectionKeepAlive));
                _timer ??= Timer.periodic(keepAliveInterval, (timer) {
                  client.sink.add(OperationMessage(
                      OperationMessage.gqlConnectionKeepAlive));
                });
              }
            } catch (e) {
              if (e == false) {
                _reportError('The connection was rejected.');
              } else {
                _reportError(e.toString());
              }
            }
          } else if (_init) {
            if (msg.type == OperationMessage.gqlStart) {
              if (msg.id == null) {
                throw FormatException('${msg.type} id is required.');
              }
              if (msg.payload == null) {
                throw FormatException('${msg.type} payload is required.');
              } else if (msg.payload is! Map) {
                throw FormatException(
                    '${msg.type} payload must be a map (object).');
              }
              var payload = msg.payload as Map;
              var query = payload['query'];
              var variables = payload['variables'];
              var operationName = payload['operationName'];
              if (query == null || query is! String) {
                throw FormatException(
                    '${msg.type} payload must contain a string named "query".');
              }
              if (variables != null && variables is! Map) {
                throw FormatException(
                    '${msg.type} payload\'s "variables" field must be a map (object).');
              }
              if (operationName != null && operationName is! String) {
                throw FormatException(
                    '${msg.type} payload\'s "operationName" field must be a string.');
              }
              var result = await onOperation(
                  msg.id,
                  query as String,
                  (variables as Map)?.cast<String, dynamic>(),
                  operationName as String);
              var data = result.data;

              if (result.errors.isNotEmpty) {
                client.sink.add(OperationMessage(OperationMessage.gqlData,
                    id: msg.id, payload: {'errors': result.errors.toList()}));
              } else {
                if (data is Map &&
                    data.keys.length == 1 &&
                    data.containsKey('data')) {
                  data = data['data'];
                }

                if (data is Stream) {
                  await for (var event in data) {
                    if (event is Map &&
                        event.keys.length == 1 &&
                        event.containsKey('data')) {
                      event = event['data'];
                    }
                    client.sink.add(OperationMessage(OperationMessage.gqlData,
                        id: msg.id, payload: {'data': event}));
                  }
                } else {
                  client.sink.add(OperationMessage(OperationMessage.gqlData,
                      id: msg.id, payload: {'data': data}));
                }
              }

              // c.complete();
              client.sink.add(
                  OperationMessage(OperationMessage.gqlComplete, id: msg.id));
            } else if (msg.type == OperationMessage.gqlConnectionTerminate) {
              await _sub?.cancel();
            }
          }
        },
        onError: _done.completeError,
        onDone: () {
          _done.complete();
          _timer?.cancel();
        });
  }

  void _reportError(String message) {
    client.sink.add(OperationMessage(OperationMessage.gqlConnectionError,
        payload: {'message': message}));
  }

  FutureOr<bool> onConnect(RemoteClient client, [Map connectionParams]);

  FutureOr<GraphQLResult> onOperation(String id, String query,
      [Map<String, dynamic> variables, String operationName]);
}
