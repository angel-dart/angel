import 'package:angel_validate/angel_validate.dart';
import 'package:test/test.dart';

final Validator todoSchema = new Validator({
  'id': [isInt, isPositive],
  'text*': isString,
  'completed*': isBool
}, defaultValues: {
  'completed': false
});

main() {
  test('todo', () {
    expect(() {
      todoSchema
          .enforce({'id': 'fool', 'text': 'Hello, world!', 'completed': 4});
    }, throwsA(new isInstanceOf<ValidationException>()));
  });
}
