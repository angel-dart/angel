// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm_generator.test.models.tree;

// **************************************************************************
// Generator: JsonModelGenerator
// **************************************************************************

class Tree extends _Tree {
  @override
  String id;

  @override
  int rings;

  @override
  List<Fruit> fruits;

  @override
  DateTime createdAt;

  @override
  DateTime updatedAt;

  Tree({this.id, this.rings, this.fruits, this.createdAt, this.updatedAt});

  factory Tree.fromJson(Map data) {
    return new Tree(
        id: data['id'],
        rings: data['rings'],
        fruits: data['fruits'] is List
            ? data['fruits']
                .map((x) =>
                    x == null ? null : (x is Fruit ? x : new Fruit.fromJson(x)))
                .toList()
            : null,
        createdAt: data['created_at'] is DateTime
            ? data['created_at']
            : (data['created_at'] is String
                ? DateTime.parse(data['created_at'])
                : null),
        updatedAt: data['updated_at'] is DateTime
            ? data['updated_at']
            : (data['updated_at'] is String
                ? DateTime.parse(data['updated_at'])
                : null));
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'rings': rings,
        'fruits': fruits,
        'created_at': createdAt == null ? null : createdAt.toIso8601String(),
        'updated_at': updatedAt == null ? null : updatedAt.toIso8601String()
      };

  static Tree parse(Map map) => new Tree.fromJson(map);

  Tree clone() {
    return new Tree.fromJson(toJson());
  }
}
