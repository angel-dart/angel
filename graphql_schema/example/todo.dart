import 'package:graphql_schema/graphql_schema.dart';

final GraphQLSchema todoSchema = new GraphQLSchema(
  queryType: objectType('Todo', fields: [
    field(
      'text',
      graphQLString.nonNullable(),
      resolve: resolveToNull,
    ),
    field(
      'created_at',
      graphQLDate,
      resolve: resolveToNull,
    ),
  ]),
);

main() {
  // Validation
  var validation = todoSchema.queryType.validate(
    '@root',
    {
      'foo': 'bar',
      'text': null,
      'created_at': 24,
    },
  );

  if (validation.successful) {
    print('This is valid data!!!');
  } else {
    print('Invalid data.');
    validation.errors.forEach((s) => print('  * $s'));
  }

  // Serialization
  print(todoSchema.queryType.serialize({
    'text': 'Clean your room!',
    'created_at': new DateTime.now().subtract(new Duration(days: 10))
  }));
}
