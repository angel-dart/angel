import 'dart:math' as math;
import 'package:graphql_parser/graphql_parser.dart';
import 'package:test/test.dart';
import 'common.dart';

main() {
  test('boolean', () {
    expect('true', equalsParsed(true));
    expect('false', equalsParsed(false));
  });

  test('number', () {
    expect('1', equalsParsed(1));
    expect('1.0', equalsParsed(1.0));
    expect('-1', equalsParsed(-1));
    expect('-1.0', equalsParsed(-1.0));
    expect('6.26e-34', equalsParsed(6.26 * math.pow(10, -34)));
    expect('-6.26e-34', equalsParsed(-6.26 * math.pow(10, -34)));
    expect('-6.26e34', equalsParsed(-6.26 * math.pow(10, 34)));
  });

  test('array', () {
    expect('[]', equalsParsed([]));
    expect('[1,2]', equalsParsed([1, 2]));
    expect('[1,2,       3]', equalsParsed([1, 2, 3]));
    expect('["a"]', equalsParsed(['a']));
  });

  test('string', () {
    expect('""', equalsParsed(''));
    expect('"a"', equalsParsed('a'));
    expect('"abc"', equalsParsed('abc'));
    expect('"\\""', equalsParsed('"'));
    expect('"\\b"', equalsParsed('\b'));
    expect('"\\f"', equalsParsed('\f'));
    expect('"\\n"', equalsParsed('\n'));
    expect('"\\r"', equalsParsed('\r'));
    expect('"\\t"', equalsParsed('\t'));
    expect('"\\u0123"', equalsParsed('\u0123'));
    expect('"\\u0123\\u4567"', equalsParsed('\u0123\u4567'));
  });

  test('exceptions', () {
    expect(() => parseValue('[1'), throwsSyntaxError);
  });
}

ValueContext parseValue(String text) => parse(text).parseValue();
Matcher equalsParsed(value) => new _EqualsParsed(value);

class _EqualsParsed extends Matcher {
  final value;

  _EqualsParsed(this.value);

  @override
  Description describe(Description description) =>
      description.add('equals $value when parsed as a GraphQL value');

  @override
  bool matches(String item, Map matchState) {
    var p = parse(item);
    var v = p.parseValue();
    return equals(value).matches(v.value, matchState);
  }
}
