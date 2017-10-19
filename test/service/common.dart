import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/common.dart';
import 'package:angel_websocket/base_websocket_client.dart';
import 'package:angel_websocket/server.dart';
import 'package:test/test.dart';

class Todo extends Model {
  String text;
  String when;

  Todo({String this.text, String this.when});
}

class TodoService extends TypedService<Todo> {
  TodoService() : super(new MapService()) {
    configuration['ws:filter'] = (HookedServiceEvent e, WebSocketContext socket) {
      print('Hello, service filter world!');
      return true;
    };
  }
}

testIndex(BaseWebSocketClient client) async {
  var Todos = client.service('api/todos');
  Todos.index();

  var indexed = await Todos.onIndexed.first;
  print('indexed: ${indexed.toJson()}');

  expect(indexed.data, isList);
  expect(indexed.data, isEmpty);
}
