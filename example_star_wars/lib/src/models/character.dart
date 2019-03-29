import 'package:graphql_schema/graphql_schema.dart';
import 'episode.dart';
part 'character.g.dart';

@graphQLClass
abstract class Character {
  String get id;

  String get name;

  // List<Episode> get appearsIn;
}
