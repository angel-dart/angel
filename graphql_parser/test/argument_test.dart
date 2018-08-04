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
    expect(() => parseArgumentList(r'(foo: $bar'), throwsSyntaxError);
  });
}

ArgumentContext parseArgument(String text) => parse(text).parseArgument();
List<ArgumentContext> parseArgumentList(String text) =>
    parse(text).parseArguments();

Matcher isArgument(String name, value) => new _IsArgument(name, value);

Matcher isArgumentList(List<Matcher> arguments) =>
    new _IsArgumentList(arguments);

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
    var arg = item is ArgumentContext ? item : parseArgument(item.toString());
    if (arg == null) return false;
    print(arg.span.highlight());
    return equals(name).matches(arg.name, matchState) &&
        equals(value).matches(
            arg.valueOrVariable.value?.value ??
                arg.valueOrVariable.variable?.name,
            matchState);
  }
}

class _IsArgumentList extends Matcher {
  final List<Matcher> arguments;

  _IsArgumentList(this.arguments);

  @override
  Description describe(Description description) {
    return description.add('is list of ${arguments.length} argument(s)');
  }

  @override
  bool matches(item, Map matchState) {
    var args = item is List<ArgumentContext>
        ? item
        : parse(item.toString()).parseArguments();

    if (args.length != arguments.length) return false;

    for (int i = 0; i < args.length; i++) {
      if (!arguments[i].matches(args[i], matchState)) return false;
    }

    return true;
  }
}
