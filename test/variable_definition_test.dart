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
    expect(() => parseVariableDefinition(r'$foo'), throwsSyntaxError);
    expect(() => parseVariableDefinition(r'$foo:'), throwsSyntaxError);
    expect(() => parseVariableDefinition(r'$foo: int ='), throwsSyntaxError);
    expect(() => parse(r'($foo: int = 2').parseVariableDefinitions(),
        throwsSyntaxError);
  });
}

VariableDefinitionContext parseVariableDefinition(String text) =>
    parse(text).parseVariableDefinition();

Matcher isVariableDefinition(String name,
        {Matcher type, Matcher defaultValue}) =>
    new _IsVariableDefinition(name, type, defaultValue);

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
        : parseVariableDefinition(item);
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
