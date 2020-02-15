import 'package:angel_framework/angel_framework.dart';
import 'package:angel_typed_service/angel_typed_service.dart';
import 'package:test/test.dart';

main() {
  var svc = TypedService<String, Todo>(MapService());

  test('force model', () {
    expect(() => TypedService<String, int>(MapService()), throwsException);
  });

  test('serialize', () {
    expect(svc.serialize({'foo': 'bar'}), {'foo': 'bar'});
    expect(() => svc.serialize(2), throwsArgumentError);
    var now = DateTime.now();
    var t = Todo(
        id: '3', text: 'a', completed: false, createdAt: now, updatedAt: now);
    var m = svc.serialize(t);
    print(m);
    expect(m..remove('_identityHashCode')..remove('idAsInt'), {
      'id': '3',
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'text': 'a',
      'completed': false
    });
  });

  test('deserialize date', () {
    var now = DateTime.now();
    var m = svc.deserialize({
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String()
    });
    expect(m, const TypeMatcher<Todo>());
    expect(m.createdAt.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
  });

  test('deserialize date w/ underscore', () {
    var now = DateTime.now();
    var m = svc.deserialize({
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String()
    });
    expect(m, const TypeMatcher<Todo>());
    expect(m.createdAt.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
  });
}

class Todo extends Model {
  String text;
  bool completed;
  @override
  DateTime createdAt, updatedAt;
  Todo({String id, this.text, this.completed, this.createdAt, this.updatedAt})
      : super(id: id);
}
