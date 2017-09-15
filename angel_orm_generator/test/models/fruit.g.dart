// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm_generator.test.models.fruit;

// **************************************************************************
// Generator: JsonModelGenerator
// **************************************************************************

class Fruit extends _Fruit {
  @override
  String id;

  @override
  int treeId;

  @override
  String commonName;

  @override
  DateTime createdAt;

  @override
  DateTime updatedAt;

  Fruit(
      {this.id, this.treeId, this.commonName, this.createdAt, this.updatedAt});

  factory Fruit.fromJson(Map data) {
    return new Fruit(
        id: data['id'],
        treeId: data['tree_id'],
        commonName: data['common_name'],
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
        'tree_id': treeId,
        'common_name': commonName,
        'created_at': createdAt == null ? null : createdAt.toIso8601String(),
        'updated_at': updatedAt == null ? null : updatedAt.toIso8601String()
      };

  static Fruit parse(Map map) => new Fruit.fromJson(map);

  Fruit clone() {
    return new Fruit.fromJson(toJson());
  }
}
