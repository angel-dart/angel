import 'package:graphql_parser/graphql_parser.dart';
import 'package:test/test.dart';

import 'common.dart';
import 'directive_test.dart';
import 'field_test.dart';
import 'selection_set_test.dart';
import 'type_test.dart';
import 'value_test.dart';
import 'variable_definition_test.dart';

main() {
  test('fragment', () {
    var fragment = parse('''
    fragment PostInfo on Post {
      description
      comments {
        id
      }
    }
    ''').parseFragmentDefinition();

    expect(fragment, isNotNull);
    expect(fragment.name, 'PostInfo');
    expect(fragment.typeCondition.typeName.name, 'Post');
    expect(
        fragment.selectionSet,
        isSelectionSet([
          isField(fieldName: isFieldName('description')),
          isField(
              fieldName: isFieldName('comments'),
              selectionSet:
                  isSelectionSet([isField(fieldName: isFieldName('id'))])),
        ]));
  });

  test('fragment exceptions', () {
    var throwsSyntaxError = predicate((x) {
      var parser = parse(x.toString())..parseFragmentDefinition();
      return parser.errors.isNotEmpty;
    }, 'fails to parse fragment definition');

    expect('fragment', throwsSyntaxError);
    expect('fragment foo', throwsSyntaxError);
    expect('fragment foo on', throwsSyntaxError);
    expect('fragment foo on bar', throwsSyntaxError);
  });

  group('operation', () {
    test('with selection set', () {
      var op = parse('{foo, bar: baz}').parseOperationDefinition();
      expect(op.variableDefinitions, isNull);
      expect(op.isQuery, isTrue);
      expect(op.isMutation, isFalse);
      expect(op.name, isNull);
      expect(
          op.selectionSet,
          isSelectionSet([
            isField(fieldName: isFieldName('foo')),
            isField(fieldName: isFieldName('bar', alias: 'baz'))
          ]));
    });

    test('mutation', () {
      var op = parse('mutation {foo, bar: baz}').parseOperationDefinition();
      expect(op.variableDefinitions, isNull);
      expect(op.isQuery, isFalse);
      expect(op.isMutation, isTrue);
      expect(op.name, isNull);
      expect(
          op.selectionSet,
          isSelectionSet([
            isField(fieldName: isFieldName('foo')),
            isField(fieldName: isFieldName('bar', alias: 'baz'))
          ]));
    });

    test('with operation type', () {
      var doc =
          parse(r'query foo ($one: [int] = 2) @foo @bar: 2 {foo, bar: baz}')
              .parseDocument();
      print(doc.span.highlight());
      expect(doc.definitions, hasLength(1));
      expect(doc.definitions.first is OperationDefinitionContext, isTrue);
      var op = doc.definitions.first as OperationDefinitionContext;
      expect(op.isMutation, isFalse);
      expect(op.isQuery, isTrue);

      expect(op.variableDefinitions.variableDefinitions, hasLength(1));
      expect(
          op.variableDefinitions.variableDefinitions.first,
          isVariableDefinition('one',
              type: isListType(isType('int'), isNullable: true),
              defaultValue: isValue(2)));

      expect(op.directives, hasLength(2));
      expect(op.directives[0], isDirective('foo'));
      expect(op.directives[1], isDirective('bar', valueOrVariable: equals(2)));

      expect(op.selectionSet, isNotNull);
      expect(
          op.selectionSet,
          isSelectionSet([
            isField(fieldName: isFieldName('foo')),
            isField(fieldName: isFieldName('bar', alias: 'baz'))
          ]));
    });

    test('exceptions', () {
      var throwsSyntaxError = predicate((x) {
        var parser = parse(x.toString())..parseOperationDefinition();
        return parser.errors.isNotEmpty;
      }, 'fails to parse operation definition');

      expect('query', throwsSyntaxError);
      expect('query foo()', throwsSyntaxError);
    });
  });
}
