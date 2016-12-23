import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/src/defs.dart';
import 'package:angel_websocket/base_websocket_client.dart';
import 'package:test/test.dart';

class Todo extends MemoryModel {
  String text;
  String when;

  Todo({String this.text, String this.when});
}

class TodoService extends MemoryService<Todo> {}

testIndex(BaseWebSocketClient client) async {
  var Todos = client.service('api/todos');
  Todos.index();

  var indexed = await Todos.onIndexed.first;
  print('indexed: ${indexed.toJson()}');

  expect(indexed.data, isList);
  expect(indexed.data, isEmpty);
}
