import 'package:graphql_parser/graphql_parser.dart';
import 'package:test/test.dart';
import 'common.dart';

main() {
  test('nullable', () {
    expect('foo', isType('foo', isNullable: true));
  });

  test('non-nullable', () {
    expect('foo!', isType('foo', isNullable: false));
  });

  group('list type', () {
    group('nullable list type', () {
      test('with nullable', () {
        expect('[foo]', isListType(isType('foo', isNullable: true)));
      });

      test('with non-nullable', () {
        expect('[foo!]', isListType(isType('foo', isNullable: false)));
      });
    });

    group('non-nullable list type', () {
      test('with nullable', () {
        expect('[foo]!',
            isListType(isType('foo', isNullable: true), isNullable: false));
      });

      test('with non-nullable', () {
        expect('[foo!]!',
            isListType(isType('foo', isNullable: false), isNullable: false));
      });
    });

    test('exceptions', () {
      var throwsSyntaxError = predicate((x) {
        var parser = parse(x.toString())..parseType();
        return parser.errors.isNotEmpty;
      }, 'fails to parse type');

      expect('[foo', throwsSyntaxError);
      expect('[', throwsSyntaxError);
    });
  });
}

TypeContext parseType(String text) => parse(text).parseType();

Matcher isListType(Matcher innerType, {bool isNullable}) =>
    _IsListType(innerType, isNullable: isNullable != false);

Matcher isType(String name, {bool isNullable}) =>
    _IsType(name, nonNull: isNullable != true);

class _IsListType extends Matcher {
  final Matcher innerType;
  final bool isNullable;

  _IsListType(this.innerType, {this.isNullable});

  @override
  Description describe(Description description) {
    var tok = isNullable != false ? 'nullable' : 'non-nullable';
    var desc = description.add('is $tok list type with an inner type that ');
    return innerType.describe(desc);
  }

  @override
  bool matches(item, Map matchState) {
    var type = item is TypeContext ? item : parseType(item.toString());
    if (type.listType == null) return false;
    if (type.isNullable != (isNullable != false)) return false;
    return innerType.matches(type.listType.innerType, matchState);
  }
}

class _IsType extends Matcher {
  final String name;
  final bool nonNull;

  _IsType(this.name, {this.nonNull});

  @override
  Description describe(Description description) {
    if (nonNull == true) {
      return description.add('is non-null type named "$name"');
    } else {
      return description.add('is nullable type named "$name"');
    }
  }

  @override
  bool matches(item, Map matchState) {
    var type = item is TypeContext ? item : parseType(item.toString());
    if (type.typeName == null) return false;
    var result = type.typeName.name == name;
    return result && type.isNullable == !(nonNull == true);
  }
}
