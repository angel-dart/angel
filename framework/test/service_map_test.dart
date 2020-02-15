import 'package:angel_framework/angel_framework.dart';
import 'package:test/test.dart';

void main() {
  MapService inner;
  Service<String, Todo> mapped;

  setUp(() {
    inner = MapService();
    mapped = inner.map<Todo>(Todo.fromMap, Todo.toMap);
  });

  test('create', () async {
    var result = await mapped.create(
      Todo(text: 'hello', complete: false),
    );
    print(result);
    expect(
      result,
      Todo(text: 'hello', complete: false),
    );
  });

  group('after create', () {
    Todo result;
    String id;

    setUp(() async {
      result = await mapped.create(Todo(text: 'hello', complete: false));
      id = result.id;
    });

    test('index', () async {
      expect(await mapped.index(), [result]);
    });

    test('modify', () async {
      var newTodo = Todo(text: 'yes', complete: true);
      expect(await mapped.update(id, newTodo), newTodo);
    });

    test('update', () async {
      var newTodo = Todo(id: 'hmmm', text: 'yes', complete: true);
      expect(await mapped.update(id, newTodo), newTodo);
    });

    test('read', () async {
      expect(await mapped.read(id), result);
    });

    test('remove', () async {
      expect(await mapped.remove(id), result);
    });
  });
}

class Todo {
  final String id, text;
  final bool complete;

  Todo({this.id, this.text, this.complete});

  static Todo fromMap(Map<String, dynamic> json) {
    return Todo(
        id: json['id'] as String,
        text: json['text'] as String,
        complete: json['complete'] as bool);
  }

  static Map<String, dynamic> toMap(Todo model) {
    return {'id': model.id, 'text': model.text, 'complete': model.complete};
  }

  @override
  bool operator ==(other) =>
      other is Todo && other.text == text && other.complete == complete;

  @override
  String toString() => '$id:$text($complete)';
}
