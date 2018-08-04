import 'package:graphql_schema/graphql_schema.dart';

@GraphQLDocumentation(
    description: 'The episodes of the Star Wars original trilogy.')
enum Episode {
  NEWHOPE,
  EMPIRE,
  JEDI,
}
