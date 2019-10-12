import 'dart:convert';
import 'package:angel_migration/angel_migration.dart';
import 'package:angel_orm/angel_orm.dart';
import 'package:angel_serialize/angel_serialize.dart';
import 'package:collection/collection.dart';
part 'has_map.g.dart';

// String _boolToCustom(bool v) => v ? 'yes' : 'no';
// bool _customToBool(v) => v == 'yes';

@orm
@serializable
abstract class _HasMap {
  Map get value;

  List get list;

  // TODO: Support custom serializers
  // @SerializableField(
  //     serializer: #_boolToCustom,
  //     deserializer: #_customToBool,
  //     serializesTo: String)
  // bool get customBool;
}
