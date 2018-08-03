import 'package:angel_framework/angel_framework.dart';
import 'package:angel_graphql/angel_graphql.dart';
import 'package:angel_serialize/angel_serialize.dart';
import 'package:graphql_schema/graphql_schema.dart';
import 'package:graphql_server/graphql_server.dart';
import 'package:graphql_server/mirrors.dart';
import 'package:logging/logging.dart';

main() async {
  var app = new Angel();
  var http = new AngelHttp(app);
  hierarchicalLoggingEnabled = true;
  app.logger = new Logger('angel_graphql')
    ..onRecord.listen((rec) {
      print(rec);
      if (rec.error != null) print(rec.error);
      if (rec.stackTrace != null) print(rec.stackTrace);
    });

  var todoService = app.use('api/todos', new MapService()) as Service;

  var api = objectType(
    'Query',
    description: 'A simple API that manages your to-do list.',
    fields: [
      field(
        'todo',
        type: listType(convertDartType(Todo).nonNullable()),
        resolve: resolveFromService(todoService),
        arguments: [
          new GraphQLFieldArgument('id', graphQLId),
        ],
      ),
    ],
  );

  var schema = graphQLSchema(query: api);

  app.all('/graphql', graphQLHttp(new GraphQL(schema)));
  app.get('/graphiql', graphiql());

  await todoService.create({'text': 'Clean your room!', 'completed': true});
  await todoService.create({'text': 'Take out the trash', 'completed': false});
  await todoService.create(
      {'text': 'Become a billionaire at the age of 5', 'completed': false});

  var server = await http.startServer('127.0.0.1', 3000);
  var uri =
      new Uri(scheme: 'http', host: server.address.address, port: server.port);
  var graphiqlUri = uri.replace(path: 'graphiql');
  print('Listening at $uri');
  print('Access graphiql at $graphiqlUri');
}

@serializable
@GraphQLDocumentation(
    description: 'A task that might not be completed yet. **Yay! Markdown!**')
class Todo extends Model {
  String text;

  @GraphQLDocumentation(deprecationReason: 'Use `completion_status` instead.')
  bool completed;

  CompletionStatus completionStatus;

  Todo({this.text, this.completed, this.completionStatus});
}

@GraphQLDocumentation(description: 'The completion status of a to-do item.')
enum CompletionStatus {
  COMPLETE, INCOMPLETE }
