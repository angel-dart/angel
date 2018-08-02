import 'dart:math' as math;
import 'package:graphql_parser/graphql_parser.dart';
import 'package:test/test.dart';
import 'common.dart';

main() {
  test('boolean', () {
    expect('true', isValue(true));
    expect('false', isValue(false));
  });

  test('number', () {
    expect('1', isValue(1));
    expect('1.0', isValue(1.0));
    expect('-1', isValue(-1));
    expect('-1.0', isValue(-1.0));
    expect('6.26e-34', isValue(6.26 * math.pow(10, -34)));
    expect('-6.26e-34', isValue(-6.26 * math.pow(10, -34)));
    expect('-6.26e34', isValue(-6.26 * math.pow(10, 34)));
  });

  test('array', () {
    expect('[]', isValue([]));
    expect('[1,2]', isValue([1, 2]));
    expect('[1,2,       3]', isValue([1, 2, 3]));
    expect('["a"]', isValue(['a']));
  });

  test('string', () {
    expect('""', isValue(''));
    expect('"a"', isValue('a'));
    expect('"abc"', isValue('abc'));
    expect('"\\""', isValue('"'));
    expect('"\\b"', isValue('\b'));
    expect('"\\f"', isValue('\f'));
    expect('"\\n"', isValue('\n'));
    expect('"\\r"', isValue('\r'));
    expect('"\\t"', isValue('\t'));
    expect('"\\u0123"', isValue('\u0123'));
    expect('"\\u0123\\u4567"', isValue('\u0123\u4567'));
  });

  test('exceptions', () {
    expect(() => parseValue('[1'), throwsSyntaxError);
  });
}

ValueContext parseValue(String text) => parse(text).parseValue();
Matcher isValue(value) => new _IsValue(value);

class _IsValue extends Matcher {
  final value;

  _IsValue(this.value);

  @override
  Description describe(Description description) =>
      description.add('equals $value when parsed as a GraphQL value');

  @override
  bool matches(item, Map matchState) {
    var v = item is ValueContext ? item : parseValue(item.toString());
    return equals(value).matches(v.value, matchState);
  }
}
