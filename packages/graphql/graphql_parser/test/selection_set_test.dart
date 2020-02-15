import 'package:graphql_parser/graphql_parser.dart';
import 'package:test/test.dart';
import 'common.dart';
import 'field_test.dart';
import 'fragment_spread_test.dart';
import 'inline_fragment_test.dart';

main() {
  test('empty', () {
    expect('{}', isSelectionSet([]));
  });

  test('with commas', () {
    expect(
        '{foo, bar: baz}',
        isSelectionSet([
          isField(fieldName: isFieldName('foo')),
          isField(fieldName: isFieldName('bar', alias: 'baz'))
        ]));
  });

  test('no commas', () {
    expect(
        '''
        {
          foo
          bar: baz ...quux
          ... on foo {bar, baz}
        }'''
            .split('\n')
            .map((s) => s.trim())
            .join(' '),
        isSelectionSet([
          isField(fieldName: isFieldName('foo')),
          isField(fieldName: isFieldName('bar', alias: 'baz')),
          isFragmentSpread('quux'),
          isInlineFragment('foo',
              selectionSet: isSelectionSet([
                isField(fieldName: isFieldName('bar')),
                isField(fieldName: isFieldName('baz')),
              ]))
        ]));
  });

  test('exceptions', () {
    var throwsSyntaxError = predicate((x) {
      var parser = parse(x.toString())..parseSelectionSet();
      return parser.errors.isNotEmpty;
    }, 'fails to parse selection set');

    expect('{foo,bar,baz', throwsSyntaxError);
  });
}

SelectionSetContext parseSelectionSet(String text) =>
    parse(text).parseSelectionSet();

Matcher isSelectionSet(List<Matcher> selections) => _IsSelectionSet(selections);

class _IsSelectionSet extends Matcher {
  final List<Matcher> selections;

  _IsSelectionSet(this.selections);

  @override
  Description describe(Description description) {
    return description
        .add('is selection set with ${selections.length} selection(s)');
  }

  @override
  bool matches(item, Map matchState) {
    var set =
        item is SelectionSetContext ? item : parseSelectionSet(item.toString());

    // if (set != null) {
    //   print('Item: $set has ${set.selections.length} selection(s):');
    //   for (var s in set.selections) {
    //     print('  * $s (${s.span.text})');
    //   }
    // }

    if (set == null) return false;
    if (set.selections.length != selections.length) return false;

    for (int i = 0; i < set.selections.length; i++) {
      var sel = set.selections[i];
      if (!selections[i].matches(
          sel.field ?? sel.fragmentSpread ?? sel.inlineFragment, matchState)) {
        return false;
      }
    }

    return true;
  }
}
