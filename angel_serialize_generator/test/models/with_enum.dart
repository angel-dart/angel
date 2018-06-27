import 'package:angel_serialize/angel_serialize.dart';
import 'package:collection/collection.dart';
part 'with_enum.g.dart';
part 'with_enum.serializer.g.dart';

@Serializable(autoIdAndDateFields: false)
abstract class _WithEnum {
  WithEnumType get type;

  List<int> get finalList;
}

enum WithEnumType { a, b, c }
