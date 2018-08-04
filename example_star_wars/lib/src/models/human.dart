import 'package:angel_model/angel_model.dart';

import 'character.dart';
import 'episode.dart';
import 'starship.dart';

class Human extends Model implements Character {
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
