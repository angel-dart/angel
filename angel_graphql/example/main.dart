import 'package:angel_framework/angel_framework.dart';
import 'package:angel_graphql/angel_graphql.dart';
import 'package:graphql_schema/graphql_schema.dart';
import 'package:graphql_server/graphql_server.dart';

main() async {
  var app = new Angel();
  var http = new AngelHttp(app);

  var todoService = app.use('api/todos', new MapService()) as Service;

  var todo = objectType('todo', [
    field(
      'text',
      type: graphQLString,
    ),
  ]);

  var api = objectType('api', [
    field(
      'todos',
      type: listType(todo),
      resolve: resolveFromService(todoService),
    ),
  ]);

  var schema = graphQLSchema(query: api);

  app.all('/graphql', graphQLHttp(new GraphQL(schema)));
  app.get('/graphiql', graphiql());

  await todoService.create({'text': 'Clean your room!', 'completed': true});

  var server = await http.startServer('127.0.0.1', 3000);
  var uri =
      new Uri(scheme: 'http', host: server.address.address, port: server.port);
  var graphiqlUri = uri.replace(path: 'graphiql');
  print('Listening at $uri');
  print('Access graphiql at $graphiqlUri');
}
