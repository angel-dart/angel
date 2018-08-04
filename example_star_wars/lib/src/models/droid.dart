import 'package:angel_model/angel_model.dart';
import 'package:angel_serialize/angel_serialize.dart';

import 'character.dart';
import 'episode.dart';

@serializable
class Droid extends Model implements Character {
  String name;
  List<Character> friends;
  List<Episode> appearsIn;
  String primaryFunction;

  Droid({this.name, this.friends, this.appearsIn, this.primaryFunction});
}
