import 'package:graphql_parser/graphql_parser.dart';
import 'package:test/test.dart';

import 'common.dart';
import 'type_test.dart';
import 'value_test.dart';

main() {
  test('no default value', () {
    expect(r'$foo: bar',
        isVariableDefinition('foo', type: isType('bar', isNullable: true)));
  });

  test('default value', () {
    expect(
        r'$foo: int! = 2',
        isVariableDefinition('foo',
            type: isType('int', isNullable: false), defaultValue: isValue(2)));
  });

  test('exceptions', () {
    var throwsSyntaxError = predicate((x) {
      var parser = parse(x.toString())..parseVariableDefinition();
      return parser.errors.isNotEmpty;
    }, 'fails to parse variable definition');

    var throwsSyntaxErrorOnDefinitions = predicate((x) {
      var parser = parse(x.toString())..parseVariableDefinitions();
      return parser.errors.isNotEmpty;
    }, 'fails to parse variable definitions');

    expect(r'$foo', throwsSyntaxError);
    expect(r'$foo:', throwsSyntaxError);
    expect(r'$foo: int =', throwsSyntaxError);

    expect(r'($foo: int = 2', throwsSyntaxErrorOnDefinitions);
  });
}

VariableDefinitionContext parseVariableDefinition(String text) =>
    parse(text).parseVariableDefinition();

Matcher isVariableDefinition(String name,
        {Matcher type, Matcher defaultValue}) =>
    _IsVariableDefinition(name, type, defaultValue);

class _IsVariableDefinition extends Matcher {
  final String name;
  final Matcher type, defaultValue;

  _IsVariableDefinition(this.name, this.type, this.defaultValue);

  @override
  Description describe(Description description) {
    var desc = description.add('is variable definition with name "$name"');

    if (type != null) {
      desc = type.describe(desc.add(' with type that '));
    }

    if (defaultValue != null) {
      desc = type.describe(desc.add(' with default value that '));
    }

    return desc;
  }

  @override
  bool matches(item, Map matchState) {
    var def = item is VariableDefinitionContext
        ? item
        : parseVariableDefinition(item.toString());
    if (def == null) return false;
    if (def.variable.name != name) return false;
    bool result = true;

    if (type != null) {
      result == result && type.matches(def.type, matchState);
    }

    if (defaultValue != null) {
      result =
          result && defaultValue.matches(def.defaultValue.value, matchState);
    }

    return result;
  }
}
