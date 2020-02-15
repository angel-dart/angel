import 'package:graphql_schema/graphql_schema.dart';
part 'episode.g.dart';

@GraphQLDocumentation(
    description: 'The episodes of the Star Wars original trilogy.')
@graphQLClass
enum Episode {
  NEWHOPE,
  EMPIRE,
  JEDI,
}
