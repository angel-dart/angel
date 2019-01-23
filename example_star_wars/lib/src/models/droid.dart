import 'package:angel_model/angel_model.dart';
import 'package:angel_serialize/angel_serialize.dart';
import 'package:collection/collection.dart';
import 'character.dart';
import 'episode.dart';
part 'droid.g.dart';

@serializable
abstract class _Droid extends Model implements Character  {
  String get id;

  String get name;

  List<Episode> get appearsIn; 

  List<Character> get friends;
}
