import 'package:graphql_parser/graphql_parser.dart';
import 'package:matcher/matcher.dart';
import 'package:test/test.dart';
import 'common.dart';

main() {
  test('argument', () {
    expect('foo: 2', isArgument('foo', 2));
    expect(r'foo: $bar', isArgument('foo', 'bar'));
  });

  test('exception', () {
    expect(() => parseArgument('foo'), throwsSyntaxError);
    expect(() => parseArgument('foo:'), throwsSyntaxError);
  });
}

ArgumentContext parseArgument(String text) => parse(text).parseArgument();

Matcher isArgument(String name, value) => new _IsArgument(name, value);

class _IsArgument extends Matcher {
  final String name;
  final value;

  _IsArgument(this.name, this.value);

  @override
  Description describe(Description description) {
    return description.add('is an argument named "$name" with value $value');
  }

  @override
  bool matches(item, Map matchState) {
    var arg = item is ArgumentContext ? item : parseArgument(item);
    if (arg == null) return false;
    return equals(name).matches(arg.name, matchState) &&
        equals(value).matches(
            arg.valueOrVariable.value?.value ??
                arg.valueOrVariable.variable?.name,
            matchState);
  }
}
