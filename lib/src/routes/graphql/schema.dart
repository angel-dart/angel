import 'package:angel_framework/angel_framework.dart';
import 'package:graphql_schema/graphql_schema.dart';
import 'todo.dart';

/// Creates a GraphQL schema that manages an in-memory store of
/// Todo items.
GraphQLSchema createSchema(Angel app) {
  var queryType = objectType(
    'TodoQuery',
    fields: todoQueryFields(app),
  );

  var mutationType = objectType(
    'TodoMutation',
    fields: todoMutationFields(app),
  );

  return graphQLSchema(
    queryType: queryType,
    mutationType: mutationType,
  );
}
