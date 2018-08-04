import 'package:graphql_parser/graphql_parser.dart';
import 'package:test/test.dart';
import 'common.dart';
import 'argument_test.dart';
import 'directive_test.dart';
import 'field_test.dart';
import 'fragment_spread_test.dart';
import 'selection_set_test.dart';

main() {
  test('no directives', () {
    expect(
        '... on foo {bar, baz: quux}',
        isInlineFragment('foo',
            selectionSet: isSelectionSet([
              isField(fieldName: isFieldName('bar')),
              isField(fieldName: isFieldName('baz', alias: 'quux'))
            ])));
  });

  test('with directives', () {
    expect(
        '... on foo @bar @baz: 2 @quux(one: 1) {... bar}',
        isInlineFragment('foo',
            directives: isDirectiveList([
              isDirective('bar'),
              isDirective('baz', valueOrVariable: equals(2)),
              isDirective('quux', argument: isArgument('one', 1))
            ]),
            selectionSet: isSelectionSet([isFragmentSpread('bar')])));
  });

  test('exceptions', () {
    expect(() => parseInlineFragment('... on foo'), throwsSyntaxError);
    expect(() => parseInlineFragment('... on foo @bar'), throwsSyntaxError);
    expect(() => parseInlineFragment('... on'), throwsSyntaxError);
    expect(() => parseInlineFragment('...'), throwsSyntaxError);
  });
}

InlineFragmentContext parseInlineFragment(String text) =>
    parse(text).parseInlineFragment();

Matcher isInlineFragment(String name,
        {Matcher directives, Matcher selectionSet}) =>
    new _IsInlineFragment(name, directives, selectionSet);

class _IsInlineFragment extends Matcher {
  final String name;
  final Matcher directives, selectionSet;

  _IsInlineFragment(this.name, this.directives, this.selectionSet);

  @override
  Description describe(Description description) {
    return description.add('is an inline fragment named "$name"');
  }

  @override
  bool matches(item, Map matchState) {
    var fragment = item is InlineFragmentContext
        ? item
        : parseInlineFragment(item.toString());
    if (fragment == null) return false;
    if (fragment.typeCondition.typeName.name != name) return false;
    if (directives != null &&
        !directives.matches(fragment.directives, matchState)) return false;
    if (selectionSet != null &&
        !selectionSet.matches(fragment.selectionSet, matchState)) return false;
    return true;
  }
}
