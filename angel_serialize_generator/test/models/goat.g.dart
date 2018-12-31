// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goat.dart';

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class Goat implements _Goat {
  const Goat({this.integer: 34, List<int> this.list: const [34, 35]});

  @override
  final int integer;

  @override
  final List<int> list;

  Goat copyWith({int integer, List<int> list}) {
    return new Goat(integer: integer ?? this.integer, list: list ?? this.list);
  }

  bool operator ==(other) {
    return other is _Goat &&
        other.integer == integer &&
        const ListEquality<int>(const DefaultEquality<int>())
            .equals(other.list, list);
  }

  @override
  int get hashCode {
    return hashObjects([integer, list]);
  }

  Map<String, dynamic> toJson() {
    return GoatSerializer.toMap(this);
  }
}

// **************************************************************************
// SerializerGenerator
// **************************************************************************

abstract class GoatSerializer {
  static Goat fromMap(Map map) {
    return new Goat(
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
  static const List<String> allFields = const <String>[integer, list];

  static const String integer = 'integer';

  static const String list = 'list';
}
