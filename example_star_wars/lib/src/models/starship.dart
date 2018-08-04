import 'package:angel_model/angel_model.dart';
import 'package:angel_serialize/angel_serialize.dart';

@serializable
class Starship extends Model {
  String name;
  int length;

  Starship({this.name, this.length});
}
