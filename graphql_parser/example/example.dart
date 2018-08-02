import 'package:graphql_parser/graphql_parser.dart';

final String INPUT = '''
{
  project(name: "GraphQL") {
    tagline
  }
}
  '''
    .trim();

main() {
  var tokens = scan(INPUT);
  var parser = new Parser(tokens);
  var doc = parser.parseDocument();

  var operation = doc.definitions.first as OperationDefinitionContext;

  var projectField = operation.selectionSet.selections.first.field;
  print(projectField.fieldName.name); // project
  print(projectField.arguments.first.name); // name
  print(projectField.arguments.first.valueOrVariable.value.value); // GraphQL

  var taglineField = projectField.selectionSet.selections.first.field;
  print(taglineField.fieldName.name); // tagline
}
