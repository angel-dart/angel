// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm_generator.test.models.tree;

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class Tree extends _Tree {
  Tree(
      {this.id,
      this.rings,
      List<dynamic> fruits,
      this.createdAt,
      this.updatedAt})
      : this.fruits = new List.unmodifiable(fruits ?? []);

  @override
  final String id;

  @override
  final int rings;

  @override
  final List<dynamic> fruits;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  Tree copyWith(
      {String id,
      int rings,
      List<dynamic> fruits,
      DateTime createdAt,
      DateTime updatedAt}) {
    return new Tree(
        id: id ?? this.id,
        rings: rings ?? this.rings,
        fruits: fruits ?? this.fruits,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt);
  }

  bool operator ==(other) {
    return other is _Tree &&
        other.id == id &&
        other.rings == rings &&
        const ListEquality<dynamic>(const DefaultEquality())
            .equals(other.fruits, fruits) &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return hashObjects([id, rings, fruits, createdAt, updatedAt]);
  }

  Map<String, dynamic> toJson() {
    return TreeSerializer.toMap(this);
  }
}
