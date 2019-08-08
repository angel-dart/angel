import 'package:graphql_parser/graphql_parser.dart';
import 'package:test/test.dart';
import 'common.dart';
import 'argument_test.dart';
import 'directive_test.dart';

main() {
  test('name only', () {
    expect(['...foo', '... foo'], everyElement(isFragmentSpread('foo')));
  });

  test('with directives', () {
    expect(
        '... foo @bar @baz: 2 @quux(one: 1)',
        isFragmentSpread('foo',
            directives: isDirectiveList([
              isDirective('bar'),
              isDirective('baz', valueOrVariable: equals(2)),
              isDirective('quux', argument: isArgument('one', 1))
            ])));
  });
}

FragmentSpreadContext parseFragmentSpread(String text) =>
    parse(text).parseFragmentSpread();

Matcher isFragmentSpread(String name, {Matcher directives}) =>
    _IsFragmentSpread(name, directives);

class _IsFragmentSpread extends Matcher {
  final String name;
  final Matcher directives;

  _IsFragmentSpread(this.name, this.directives);

  @override
  Description describe(Description description) {
    if (directives != null) {
      return directives.describe(
          description.add('is a fragment spread named "$name" that also '));
    }
    return description.add('is a fragment spread named "$name"');
  }

  @override
  bool matches(item, Map matchState) {
    var spread = item is FragmentSpreadContext
        ? item
        : parseFragmentSpread(item.toString());
    if (spread == null) return false;
    if (spread.name != name) return false;
    if (directives != null) {
      return directives.matches(spread.directives, matchState);
    } else {
      return true;
    }
  }
}
