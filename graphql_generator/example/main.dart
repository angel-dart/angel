import 'package:graphql_schema/graphql_schema.dart';
part 'main.g.dart';

@graphQLClass
class Todo {
  String text;

  @GraphQLDocumentation(description: 'Whether this item is complete.')
  bool isComplete;
}

void main() {
  print(todoGraphQLType.fields.map((f) => f.name));
}
