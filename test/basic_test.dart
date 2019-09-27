import 'package:angel_validate/angel_validate.dart';
import 'package:test/test.dart';

final Validator emailSchema =
    Validator({'to': isEmail}, customErrorMessages: {'to': 'Hello, world!'});

final Validator todoSchema = Validator({
  'id': [isInt, isPositive],
  'text*': isString,
  'completed*': isBool,
  'foo,bar': [isTrue]
}, defaultValues: {
  'completed': false
});

main() {
  test('custom error message', () {
    var result = emailSchema.check({'to': 2});

    expect(result.errors, isList);
    expect(result.errors, hasLength(1));
    expect(result.errors.first, equals('Hello, world!'));
  });

  test('requireField', () => expect(requireField('foo'), 'foo*'));

  test('requireFields',
      () => expect(requireFields(['foo', 'bar']), 'foo*, bar*'));

  test('todo', () {
    expect(() {
      todoSchema
          .enforce({'id': 'fool', 'text': 'Hello, world!', 'completed': 4});
      // ignore: deprecated_member_use
    }, throwsA(isInstanceOf<ValidationException>()));
  });

  test('filter', () {
    var inputData = {'foo': 'bar', 'a': 'b', '1': 2};
    var only = filter(inputData, ['foo']);
    expect(only, equals({'foo': 'bar'}));
  });

  test('comma in schema', () {
    expect(todoSchema.rules.keys, allOf(contains('foo'), contains('bar')));
    expect([todoSchema.rules['foo'].first, todoSchema.rules['bar'].first],
        everyElement(predicate((x) => x == isTrue)));
  });
}
