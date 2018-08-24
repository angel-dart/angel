// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm_generator.test.models.foot;

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class Foot extends _Foot {
  Foot({this.id, this.legId, this.nToes, this.createdAt, this.updatedAt});

  @override
  final String id;

  @override
  final int legId;

  @override
  final int nToes;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  Foot copyWith(
      {String id,
      int legId,
      int nToes,
      DateTime createdAt,
      DateTime updatedAt}) {
    return new Foot(
        id: id ?? this.id,
        legId: legId ?? this.legId,
        nToes: nToes ?? this.nToes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt);
  }

  bool operator ==(other) {
    return other is _Foot &&
        other.id == id &&
        other.legId == legId &&
        other.nToes == nToes &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  Map<String, dynamic> toJson() {
    return FootSerializer.toMap(this);
  }
}
