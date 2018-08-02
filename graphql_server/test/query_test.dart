import 'package:graphql_schema/graphql_schema.dart';
import 'package:graphql_server/graphql_server.dart';
import 'package:test/test.dart';

void main() {
  test('single element', () async {
    var todoType = objectType('todo',fields: [
      field(
        'text',
        type: graphQLString,
        resolve: (obj, args) => obj.text,
      ),
      field(
        'completed',
        type: graphQLBoolean,
        resolve: (obj, args) => obj.completed,
      ),
    ]);

    var schema = graphQLSchema(
      query: objectType('api', fields:[
        field(
          'todos',
          type: listType(todoType),
          resolve: (_, __) => [
                new Todo(
                  text: 'Clean your room!',
                  completed: false,
                )
              ],
        ),
      ]),
    );

    var graphql = new GraphQL(schema);
    var result = await graphql.parseAndExecute('{ todos { text } }');

    print(result);
    expect(result, {
      'todos': [
        {'text': 'Clean your room!'}
      ]
    });
  });
}

class Todo {
  final String text;
  final bool completed;

  Todo({this.text, this.completed});
}
