import 'package:angel_serialize/angel_serialize.dart';

import 'episode.dart';

@serializable
abstract class Character {
  String get id;

  String get name;

  List<Episode> get appearsIn;

  List<Character> get friends;
}
