import 'package:angel_model/angel_model.dart';
import 'package:angel_serialize/angel_serialize.dart';
import 'package:graphql_schema/graphql_schema.dart';

import 'character.dart';
import 'episode.dart';
import 'starship.dart';

@serializable
class Human extends Model implements Character {
  @GraphQLDocumentation(description: "This human's name, of course.")
  String name;
  List<Character> friends;
  List<Episode> appearsIn;
  List<Starship> starships;
  int totalCredits;

  Human(
      {this.name,
      this.friends,
      this.appearsIn,
      this.starships,
      this.totalCredits});
}
