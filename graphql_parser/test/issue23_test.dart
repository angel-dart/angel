import 'package:graphql_parser/graphql_parser.dart';
import 'package:test/test.dart';

/// This is an *extremely* verbose test, but basically it
/// parses both documents, and makes sure that $memberId has
/// a valid value.
///
/// Resolves https://github.com/angel-dart/graphql/issues/23.
void main() {
  void testStr<T>(String name, String text) {
    test('name', () {
      final List<Token> tokens = scan(text);
      final Parser parser = Parser(tokens);

      if (parser.errors.isNotEmpty) {
        print(parser.errors.toString());
      }
      expect(parser.errors, isEmpty);

      // Parse the GraphQL document using recursive descent
      final DocumentContext doc = parser.parseDocument();

      expect(doc.definitions, isNotNull);
      expect(doc.definitions, isNotEmpty);

      // Sanity check
      var queryDef = doc.definitions[0] as OperationDefinitionContext;
      expect(queryDef.isQuery, true);
      expect(queryDef.name, 'customerMemberAttributes');
      expect(queryDef.variableDefinitions.variableDefinitions, hasLength(1));
      var memberIdDef = queryDef.variableDefinitions.variableDefinitions[0];
      expect(memberIdDef.variable.name, 'memberId');

      // Find $memberId
      var customerByCustomerId = queryDef.selectionSet.selections[0];
      var customerMemberAttributesByCustomerId =
          customerByCustomerId.field.selectionSet.selections[0];
      var nodes0 =
          customerMemberAttributesByCustomerId.field.selectionSet.selections[0];
      var customerMemberAttributeId = nodes0.field.selectionSet.selections[0];
      expect(customerMemberAttributeId.field.fieldName.name,
          'customerMemberAttributeId');
      var memberAttr = nodes0.field.selectionSet.selections[1];
      expect(memberAttr.field.fieldName.name,
          'memberAttributesByCustomerMemberAttributeId');
      expect(memberAttr.field.arguments, hasLength(1));
      var condition = memberAttr.field.arguments[0];
      expect(condition.name, 'condition');
      expect(condition.value, TypeMatcher<ObjectValueContext>());
      var conditionValue = condition.value as ObjectValueContext;
      var memberId = conditionValue.fields
          .singleWhere((f) => f.nameToken.text == 'memberId');
      expect(memberId.value, TypeMatcher<T>());
      print('Found \$memberId: Instance of $T');
    });
  }

  testStr<VariableContext>('member id as var', memberIdAsVar);
  testStr<NumberValueContext>('member id as constant', memberIdAsConstant);
}

final String memberIdAsVar = r'''
query customerMemberAttributes($memberId: Int!){
  customerByCustomerId(customerId: 7) {
    customerMemberAttributesByCustomerId {
      nodes {
        customerMemberAttributeId
        memberAttributesByCustomerMemberAttributeId(condition: {memberId: $memberId}) {
          nodes {
            memberAttributeId
          }
        }
      }
    }
  }
}
''';

final String memberIdAsConstant = r'''
query customerMemberAttributes($memberId: Int!){
  customerByCustomerId(customerId: 7) {
    customerMemberAttributesByCustomerId {
      nodes {
        customerMemberAttributeId
        memberAttributesByCustomerMemberAttributeId(condition: {memberId: 7}) {
          nodes {
            memberAttributeId
          }
        }
      }
    }
  }
}
''';
