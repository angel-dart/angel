import 'package:angel/src/models/todo.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_graphql/angel_graphql.dart';
import 'package:graphql_schema/graphql_schema.dart';

/// Find or create an in-memory Todo store.
MapService _getTodoService(Angel app) {
  const key = 'todoService';

  // If there is already an existing singleton, return it.
  if (app.container.hasNamed(key)) {
    return app.container.findByName<MapService>(key);
  }

  // Create an in-memory service. We will use this
  // as the backend to store Todo objects, serialized to Maps.
  var mapService = MapService();

  // Register this service as a named singleton in the app container,
  // so that we do not inadvertently create another instance.
  app.container.registerNamedSingleton(key, mapService);

  return mapService;
}

/// Returns fields to be inserted into the query type.
Iterable<GraphQLObjectField> todoQueryFields(Angel app) {
  var todoService = _getTodoService(app);

  // Here, we use special resolvers to read data from our store.
  return [
    field(
      'todos',
      listOf(todoGraphQLType),
      resolve: resolveViaServiceIndex(todoService),
    ),
    field(
      'todo',
      todoGraphQLType,
      resolve: resolveViaServiceRead(todoService),
      inputs: [
        GraphQLFieldInput('id', graphQLString.nonNullable()),
      ],
    ),
  ];
}

/// Returns fields to be inserted into the query type.
Iterable<GraphQLObjectField> todoMutationFields(Angel app) {
  var todoService = _getTodoService(app);
  var todoInputType = todoGraphQLType.toInputObject('TodoInput');

  // This time, we use resolvers to modify the data in the store.
  return [
    field(
      'createTodo',
      todoGraphQLType,
      resolve: resolveViaServiceCreate(todoService),
      inputs: [
        GraphQLFieldInput('data', todoInputType.nonNullable()),
      ],
    ),
    field(
      'modifyTodo',
      todoGraphQLType,
      resolve: resolveViaServiceModify(todoService),
      inputs: [
        GraphQLFieldInput('id', graphQLString.nonNullable()),
        GraphQLFieldInput('data', todoInputType.nonNullable()),
      ],
    ),
  ];
}
