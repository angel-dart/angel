import 'package:graphql_parser/graphql_parser.dart';
import 'package:test/test.dart';

import 'argument_test.dart';
import 'common.dart';
import 'directive_test.dart';
import 'fragment_spread_test.dart';
import 'selection_set_test.dart';
import 'value_test.dart';

main() {
  group('field name', () {
    test('plain field name', () {
      expect('foo', isFieldName('foo'));
    });
    test('alias', () {
      expect('foo: bar', isFieldName('foo', alias: 'bar'));
    });
    test('exceptions', () {
      var throwsSyntaxError = predicate((x) {
        var parser = parse(x.toString())..parseFieldName();
        return parser.errors.isNotEmpty;
      }, 'fails to parse field name');

      expect('foo:', throwsSyntaxError);
    });
  });

  test('arguments', () {
    expect('()', isArgumentList([]));
    expect(r'(a: 2)', isArgumentList([isArgument('a', 2)]));
    expect(r'(a: 2, b: $c)',
        isArgumentList([isArgument('a', 2), isArgument('b', 'c')]));
  });

  group('field tests', () {
    test('plain field name', () {
      expect('foo', isField(fieldName: isFieldName('foo')));
    });

    test('aliased field name', () {
      expect('foo: bar', isField(fieldName: isFieldName('foo', alias: 'bar')));
    });

    test('with arguments', () {
      expect(
          r'foo (a: 2, b: $c)',
          isField(
              fieldName: isFieldName('foo'),
              arguments:
                  isArgumentList([isArgument('a', 2), isArgument('b', 'c')])));
    });

    test('with directives', () {
      expect(
          'foo: bar (a: 2) @bar @baz: 2 @quux (one: 1)',
          isField(
              fieldName: isFieldName('foo', alias: 'bar'),
              arguments: isArgumentList([isArgument('a', 2)]),
              directives: isDirectiveList([
                isDirective('bar'),
                isDirective('baz', valueOrVariable: isValue(2)),
                isDirective('quux', argument: isArgument('one', 1))
              ])));
    });

    test('with selection set', () {
      expect(
          'foo: bar {baz, ...quux}',
          isField(
              fieldName: isFieldName('foo', alias: 'bar'),
              selectionSet: isSelectionSet([
                isField(fieldName: isFieldName('baz')),
                isFragmentSpread('quux')
              ])));
    });
  });
}

FieldContext parseField(String text) => parse(text).parseField();

FieldNameContext parseFieldName(String text) => parse(text).parseFieldName();

Matcher isField(
        {Matcher fieldName,
        Matcher arguments,
        Matcher directives,
        Matcher selectionSet}) =>
    _IsField(fieldName, arguments, directives, selectionSet);

Matcher isFieldName(String name, {String alias}) => _IsFieldName(name, alias);

class _IsField extends Matcher {
  final Matcher fieldName, arguments, directives, selectionSet;

  _IsField(this.fieldName, this.arguments, this.directives, this.selectionSet);

  @override
  Description describe(Description description) {
    // Too lazy to make a real description...
    return description.add('is field');
  }

  @override
  bool matches(item, Map matchState) {
    var field = item is FieldContext ? item : parseField(item.toString());
    if (field == null) return false;
    if (fieldName != null && !fieldName.matches(field.fieldName, matchState)) {
      return false;
    }
    if (arguments != null && !arguments.matches(field.arguments, matchState)) {
      return false;
    }
    return true;
  }
}

class _IsFieldName extends Matcher {
  final String name, realName;

  _IsFieldName(this.name, this.realName);

  @override
  Description describe(Description description) {
    if (realName != null) {
      return description
          .add('is field with name "$name" and alias "$realName"');
    }
    return description.add('is field with name "$name"');
  }

  @override
  bool matches(item, Map matchState) {
    var fieldName =
        item is FieldNameContext ? item : parseFieldName(item.toString());
    if (realName != null) {
      return fieldName.alias?.alias == name &&
          fieldName.alias?.name == realName;
    } else {
      return fieldName.name == name;
    }
  }
}
