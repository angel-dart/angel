import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/common.dart';
import 'package:test/test.dart';

main() {
  var svc = new TypedService<Todo>(new MapService());

  test('force model', () {
    expect(() => new TypedService<String>(null), throwsException);
  });

  test('serialize', () {
    expect(svc.serialize({'foo': 'bar'}), {'foo': 'bar'});
    expect(
        svc.serialize([
          {'foo': 'bar'}
        ]),
        [
          {'foo': 'bar'}
        ]);
    expect(() => svc.serialize(2), throwsArgumentError);
    var now = new DateTime.now();
    var t =
        new Todo(text: 'a', completed: false, createdAt: now, updatedAt: now);
    var m = svc.serialize(t);
    print(m);
    expect(m, {
      'id': null,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'text': 'a',
      'completed': false
    });
  });

  test('deserialize date', () {
    var now = new DateTime.now();
    var m = svc.deserialize({
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String()
    });
    expect(m, new isInstanceOf<Todo>());
    var t = m as Todo;
    expect(t.createdAt.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
  });

  test('deserialize date w/ underscore', () {
    var now = new DateTime.now();
    var m = svc.deserialize({
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String()
    });
    expect(m, new isInstanceOf<Todo>());
    var t = m as Todo;
    expect(t.createdAt.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
  });
}

class Todo extends Model {
  String text;
  bool completed;
  @override
  DateTime createdAt, updatedAt;
  Todo({this.text, this.completed, this.createdAt, this.updatedAt});
}
