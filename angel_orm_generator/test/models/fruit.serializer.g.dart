// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm_generator.test.models.fruit;

// **************************************************************************
// SerializerGenerator
// **************************************************************************

abstract class FruitSerializer {
  static Fruit fromMap(Map map) {
    return new Fruit(
        id: map['id'] as String,
        treeId: map['tree_id'] as int,
        commonName: map['common_name'] as String,
        createdAt: map['created_at'] != null
            ? (map['created_at'] is DateTime
                ? (map['created_at'] as DateTime)
                : DateTime.parse(map['created_at'].toString()))
            : null,
        updatedAt: map['updated_at'] != null
            ? (map['updated_at'] is DateTime
                ? (map['updated_at'] as DateTime)
                : DateTime.parse(map['updated_at'].toString()))
            : null);
  }

  static Map<String, dynamic> toMap(Fruit model) {
    if (model == null) {
      return null;
    }
    return {
      'id': model.id,
      'tree_id': model.treeId,
      'common_name': model.commonName,
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String()
    };
  }
}

abstract class FruitFields {
  static const List<String> allFields = const <String>[
    id,
    treeId,
    commonName,
    createdAt,
    updatedAt
  ];

  static const String id = 'id';

  static const String treeId = 'tree_id';

  static const String commonName = 'common_name';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';
}
