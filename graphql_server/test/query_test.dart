import 'package:graphql_schema/graphql_schema.dart';
import 'package:graphql_server/graphql_server.dart';
import 'package:test/test.dart';

void main() {
  test('todo', () async {
    var schema = graphQLSchema(
      query: objectType('todo', [
        field(
          'text',
          type: graphQLString,
          resolve: (obj, args) => obj['text'],
        ),
        field(
          'completed',
          type: graphQLBoolean,
          resolve: (obj, args) => obj['completed'],
        ),
      ]),
    );

    var graphql = new GraphQL(schema);
    var result = await graphql.parseAndExecute('{ text }', initialValue: {
      'text': 'Clean your room!',
      'completed': false,
    });

    print(result);
    expect(result, {'text': 'Clean your room!'});
  });
}

class Todo {
  final String text;
  final bool completed;

  Todo({this.text, this.completed});
}
