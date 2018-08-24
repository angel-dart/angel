// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm_generator.test.models.fruit;

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class Fruit extends _Fruit {
  Fruit(
      {this.id, this.treeId, this.commonName, this.createdAt, this.updatedAt});

  @override
  final String id;

  @override
  final int treeId;

  @override
  final String commonName;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  Fruit copyWith(
      {String id,
      int treeId,
      String commonName,
      DateTime createdAt,
      DateTime updatedAt}) {
    return new Fruit(
        id: id ?? this.id,
        treeId: treeId ?? this.treeId,
        commonName: commonName ?? this.commonName,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt);
  }

  bool operator ==(other) {
    return other is _Fruit &&
        other.id == id &&
        other.treeId == treeId &&
        other.commonName == commonName &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  Map<String, dynamic> toJson() {
    return FruitSerializer.toMap(this);
  }
}
