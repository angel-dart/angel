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

  var queryType = objectType(
    'Query',
    description: 'A simple API that manages your to-do list.',
    fields: [
      field(
        'todos',
        listOf(convertDartType(Todo).nonNullable()),
        resolve: resolveViaServiceIndex(todoService),
      ),
      field(
        'todo',
        convertDartType(Todo),
        resolve: resolveViaServiceRead(todoService),
        inputs: [
          new GraphQLFieldInput('id', graphQLId.nonNullable()),
        ],
      ),
    ],
  );

  var mutationType = objectType(
    'Mutation',
    description: 'Modify the to-do list.',
    fields: [
      field(
        'create',
        graphQLString,
      ),
    ],
  );

  var schema = graphQLSchema(
    queryType: queryType,
    mutationType: mutationType,
  );

  app.all('/graphql', graphQLHttp(new GraphQL(schema)));
  app.get('/graphiql', graphiQL());

  await todoService
      .create({'text': 'Clean your room!', 'completion_status': 'COMPLETE'});
  await todoService.create(
      {'text': 'Take out the trash', 'completion_status': 'INCOMPLETE'});
  await todoService.create({
    'text': 'Become a billionaire at the age of 5',
    'completion_status': 'INCOMPLETE'
  });

  var server = await http.startServer('127.0.0.1', 3000);
  var uri =
      new Uri(scheme: 'http', host: server.address.address, port: server.port);
  var graphiqlUri = uri.replace(path: 'graphiql');
  print('Listening at $uri');
  print('Access graphiql at $graphiqlUri');
}

@GraphQLDocumentation(description: 'Any object with a .text (String) property.')
abstract class HasText {
  String get text;
}

@serializable
@GraphQLDocumentation(
    description: 'A task that might not be completed yet. **Yay! Markdown!**')
class Todo extends Model implements HasText {
  String text;

  @GraphQLDocumentation(deprecationReason: 'Use `completion_status` instead.')
  bool completed;

  CompletionStatus completionStatus;

  Todo({this.text, this.completed, this.completionStatus});
}

@GraphQLDocumentation(description: 'The completion status of a to-do item.')
enum CompletionStatus { COMPLETE, INCOMPLETE }
