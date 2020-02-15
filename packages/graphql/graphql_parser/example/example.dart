import 'package:graphql_parser/graphql_parser.dart';

final String text = '''
{
  project(name: "GraphQL") {
    tagline
  }
}
  '''
    .trim();

main() {
  var tokens = scan(text);
  var parser = Parser(tokens);
  var doc = parser.parseDocument();

  var operation = doc.definitions.first as OperationDefinitionContext;

  var projectField = operation.selectionSet.selections.first.field;
  print(projectField.fieldName.name); // project
  print(projectField.arguments.first.name); // name
  print(projectField.arguments.first.value); // GraphQL

  var taglineField = projectField.selectionSet.selections.first.field;
  print(taglineField.fieldName.name); // tagline
}
