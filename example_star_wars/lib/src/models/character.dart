import 'package:angel_model/angel_model.dart';
import 'episode.dart';

abstract class _Character extends Model {
  String get id;

  String get name;

  List<Episode> get appearsIn;

  List<Character> get friends;
}
