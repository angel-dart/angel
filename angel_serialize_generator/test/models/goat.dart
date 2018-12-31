import 'package:angel_serialize/angel_serialize.dart';
import 'package:collection/collection.dart';
part 'goat.g.dart';

@Serializable(autoIdAndDateFields: false)
abstract class _Goat {
  @DefaultValue(34)
  int get integer;

  @DefaultValue([34, 35])
  List<int> get list;
}
