import 'package:graphql_schema/graphql_schema.dart';

final GraphQLSchema todoSchema = new GraphQLSchema(
    query: objectType('Todo', [
  field('text', type: graphQLString.nonNullable()),
  field('created_at', type: graphQLDate)
]));

main() {
  // Validation
  var validation = todoSchema.query
      .validate('@root', {'foo': 'bar', 'text': null, 'created_at': 24});

  if (validation.successful) {
    print('This is valid data!!!');
  } else {
    print('Invalid data.');
    validation.errors.forEach((s) => print('  * $s'));
  }

  // Serialization
  print(todoSchema.query.serialize({
    'text': 'Clean your room!',
    'created_at': new DateTime.now().subtract(new Duration(days: 10))
  }));
}
