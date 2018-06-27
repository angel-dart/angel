import 'package:angel_model/angel_model.dart';
import 'package:angel_serialize/angel_serialize.dart';
part 'with_enum.g.dart';
part 'with_enum.serializer.g.dart';

@Serializable(autoIdAndDateFields: false)
abstract class _WithEnum {
  WithEnumType get type;
}

enum WithEnumType { a, b, c }
