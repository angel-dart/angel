import 'package:graphql_parser/graphql_parser.dart';
import 'package:test/test.dart';
import 'common.dart';
import 'argument_test.dart';
import 'directive_test.dart';
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
      expect(() => parseFieldName('foo:'), throwsSyntaxError);
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
          'foo: bar @bar @baz: 2 @quux (one: 1)',
          isField(
              fieldName: isFieldName('foo', alias: 'bar'),
              directives: isDirectiveList([
                isDirective('bar'),
                isDirective('baz', valueOrVariable: isValue(2)),
                isDirective('quux', argument: isArgument('one', 1))
              ])));
    });
  });
}

FieldContext parseField(String text) => parse(text).parseField();

FieldNameContext parseFieldName(String text) => parse(text).parseFieldName();

Matcher isArgumentList(List<Matcher> arguments) =>
    new _IsArgumentList(arguments);

Matcher isDirectiveList(List<Matcher> directives) =>
    new _IsDirectiveList(directives);

Matcher isField(
        {Matcher fieldName,
        Matcher arguments,
        Matcher directives,
        Matcher selectionSet}) =>
    new _IsField(fieldName, arguments, directives, selectionSet);

Matcher isFieldName(String name, {String alias}) =>
    new _IsFieldName(name, alias);

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
    var field = item is FieldContext ? item : parseField(item);
    if (field == null) return false;
    if (fieldName != null && !fieldName.matches(field.fieldName, matchState))
      return false;
    if (arguments != null && !arguments.matches(field.arguments, matchState))
      return false;
    return true;
  }
}

class _IsFieldName extends Matcher {
  final String name, alias;

  _IsFieldName(this.name, this.alias);

  @override
  Description describe(Description description) {
    if (alias != null)
      return description.add('is field with name "$name" and alias "$alias"');
    return description.add('is field with name "$name"');
  }

  @override
  bool matches(item, Map matchState) {
    var fieldName = item is FieldNameContext ? item : parseFieldName(item);
    if (alias != null)
      return fieldName.alias?.name == name && fieldName.alias?.alias == alias;
    else
      return fieldName.name == name;
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
    var args =
        item is List<ArgumentContext> ? item : parse(item).parseArguments();

    if (args.length != arguments.length) return false;

    for (int i = 0; i < args.length; i++) {
      if (!arguments[i].matches(args[i], matchState)) return false;
    }

    return true;
  }
}

class _IsDirectiveList extends Matcher {
  final List<Matcher> directives;

  _IsDirectiveList(this.directives);

  @override
  Description describe(Description description) {
    return description.add('is list of ${directives.length} directive(s)');
  }

  @override
  bool matches(item, Map matchState) {
    var args =
        item is List<DirectiveContext> ? item : parse(item).parseDirectives();

    if (args.length != directives.length) return false;

    for (int i = 0; i < args.length; i++) {
      if (!directives[i].matches(args[i], matchState)) return false;
    }

    return true;
  }
}
