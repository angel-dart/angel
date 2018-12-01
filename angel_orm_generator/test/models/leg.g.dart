// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm_generator.test.models.leg;

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class Leg extends _Leg {
  Leg({this.id, this.foot, this.name, this.createdAt, this.updatedAt});

  @override
  final String id;

  @override
  final dynamic foot;

  @override
  final String name;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  Leg copyWith(
      {String id,
      dynamic foot,
      String name,
      DateTime createdAt,
      DateTime updatedAt}) {
    return new Leg(
        id: id ?? this.id,
        foot: foot ?? this.foot,
        name: name ?? this.name,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt);
  }

  bool operator ==(other) {
    return other is _Leg &&
        other.id == id &&
        other.foot == foot &&
        other.name == name &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return hashObjects([id, foot, name, createdAt, updatedAt]);
  }

  Map<String, dynamic> toJson() {
    return LegSerializer.toMap(this);
  }
}
