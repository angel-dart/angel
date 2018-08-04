import 'episode.dart';

abstract class Character {
  String get id;

  String get name;

  List<Episode> get appearsIn;

  List<Character> get friends;
}
