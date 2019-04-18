import 'dart:async';
import 'remote_client.dart';
import 'transport.dart';

abstract class Server {
  final RemoteClient client;
  final Completer _done = Completer();
  StreamSubscription<OperationMessage> _sub;
  bool _init = false;

  Future get done => _done.future;

  Server(this.client) {
    _sub = client.stream.listen((msg) async {
      if (msg.type == OperationMessage.gqlConnectionInit && !_init) {
        try {
          Map connectionParams = null;
          if (msg.payload is Map)
            connectionParams = msg.payload as Map;
          else if (msg.payload != null)
            throw FormatException(
                '${msg.type} payload must be a map (object).');

          var connect = await onConnect(client, connectionParams);
          if (!connect) throw false;
          _init = true;
          client.sink.add(OperationMessage(OperationMessage.gqlConnectionAck));
        } catch (e) {
          if (e == false)
            _reportError('The connection was rejected.');
          else
            _reportError(e.toString());
        }
      } else if (_init) {
        if (msg.type == OperationMessage.gqlStart) {
          if (msg.id == null)
            throw FormatException('${msg.type} id is required.');
          if (msg.payload == null)
            throw FormatException('${msg.type} payload is required.');
          else if (msg.payload is! Map)
            throw FormatException(
                '${msg.type} payload must be a map (object).');
          var payload = msg.payload as Map;
          var query = payload['query'];
          var variables = payload['variables'];
          var operationName = payload['operationName'];
          if (query == null || query is! String)
            throw FormatException(
                '${msg.type} payload must contain a string named "query".');
          if (variables != null && variables is! Map)
            throw FormatException(
                '${msg.type} payload\'s "variables" field must be a map (object).');
          if (operationName != null && operationName is! String)
            throw FormatException(
                '${msg.type} payload\'s "operationName" field must be a string.');
          var result = await onOperation(
              msg.id,
              query as String,
              (variables as Map).cast<String, dynamic>(),
              operationName as String);
          var data = result.data;

          if (data is Stream) {
            await for (var event in data) {
              client.sink.add(OperationMessage(OperationMessage.gqlData,
                  id: msg.id,
                  payload: {'data': event, 'errors': result.errors}));
            }
          } else {
            client.sink.add(OperationMessage(OperationMessage.gqlData,
                id: msg.id, payload: {'data': data, 'errors': result.errors}));
          }

          client.sink
              .add(OperationMessage(OperationMessage.gqlComplete, id: msg.id));
        } else if (msg.type == OperationMessage.gqlConnectionTerminate) {
          await _sub?.cancel();
        }
      }
    }, onError: _done.completeError, onDone: _done.complete);
  }

  void _reportError(String message) {
    client.sink.add(OperationMessage(OperationMessage.gqlConnectionError,
        payload: {'message': message}));
  }

  FutureOr<bool> onConnect(RemoteClient client, [Map connectionParams]);

  FutureOr<GraphQLResult> onOperation(String id, String query,
      [Map<String, dynamic> variables, String operationName]);
}
