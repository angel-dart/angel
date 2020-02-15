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
    var isSyntaxError = predicate((x) {
      var parser = parse(x.toString())..parseArgument();
      return parser.errors.isNotEmpty;
    }, 'fails to parse argument');

    var isSyntaxErrorOnArguments = predicate((x) {
      var parser = parse(x.toString())..parseArguments();
      return parser.errors.isNotEmpty;
    }, 'fails to parse arguments');

    expect('foo', isSyntaxError);
    expect('foo:', isSyntaxError);
    expect(r'(foo: $bar', isSyntaxErrorOnArguments);
  });
}

ArgumentContext parseArgument(String text) => parse(text).parseArgument();

List<ArgumentContext> parseArgumentList(String text) =>
    parse(text).parseArguments();

Matcher isArgument(String name, value) => _IsArgument(name, value);

Matcher isArgumentList(List<Matcher> arguments) => _IsArgumentList(arguments);

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

    var v = arg.value;
    return equals(name).matches(arg.name, matchState) &&
        ((v is VariableContext && equals(value).matches(v.name, matchState)) ||
            equals(value).matches(arg.value.computeValue({}), matchState));
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
