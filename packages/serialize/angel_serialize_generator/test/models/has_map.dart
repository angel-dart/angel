import 'dart:convert';
import 'package:angel_serialize/angel_serialize.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
part 'has_map.g.dart';

Map _fromString(v) => json.decode(v.toString()) as Map;

String _toString(Map v) => json.encode(v);

@serializable
abstract class _HasMap {
  @SerializableField(
      serializer: #_toString,
      deserializer: #_fromString,
      isNullable: false,
      serializesTo: String)
  Map get value;
}
