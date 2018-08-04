import 'package:angel_model/angel_model.dart';

import 'character.dart';
import 'episode.dart';

class Droid extends Model implements Character {
  String name;
  List<Character> friends;
  List<Episode> appearsIn;
  String primaryFunction;

  Droid({this.name, this.friends, this.appearsIn, this.primaryFunction});
}
