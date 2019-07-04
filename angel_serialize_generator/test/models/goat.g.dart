// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goat.dart';

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class Goat implements _Goat {
  const Goat({this.integer = 34, this.list = const [34, 35]});

  @override
  final int integer;

  @override
  final List<int> list;

  Goat copyWith({int integer, List<int> list}) {
    return Goat(integer: integer ?? this.integer, list: list ?? this.list);
  }

  bool operator ==(other) {
    return other is _Goat &&
        other.integer == integer &&
        ListEquality<int>(DefaultEquality<int>()).equals(other.list, list);
  }

  @override
  int get hashCode {
    return hashObjects([integer, list]);
  }

  @override
  String toString() {
    return "Goat(integer=$integer, list=$list)";
  }

  Map<String, dynamic> toJson() {
    return GoatSerializer.toMap(this);
  }
}

// **************************************************************************
// SerializerGenerator
// **************************************************************************

const GoatSerializer goatSerializer = GoatSerializer();

class GoatEncoder extends Converter<Goat, Map> {
  const GoatEncoder();

  @override
  Map convert(Goat model) => GoatSerializer.toMap(model);
}

class GoatDecoder extends Converter<Map, Goat> {
  const GoatDecoder();

  @override
  Goat convert(Map map) => GoatSerializer.fromMap(map);
}

class GoatSerializer extends Codec<Goat, Map> {
  const GoatSerializer();

  @override
  get encoder => const GoatEncoder();
  @override
  get decoder => const GoatDecoder();
  static Goat fromMap(Map map) {
    return Goat(
        integer: map['integer'] as int ?? 34,
        list: map['list'] is Iterable
            ? (map['list'] as Iterable).cast<int>().toList()
            : const [34, 35]);
  }

  static Map<String, dynamic> toMap(_Goat model) {
    if (model == null) {
      return null;
    }
    return {'integer': model.integer, 'list': model.list};
  }
}

abstract class GoatFields {
  static const List<String> allFields = <String>[integer, list];

  static const String integer = 'integer';

  static const String list = 'list';
}
