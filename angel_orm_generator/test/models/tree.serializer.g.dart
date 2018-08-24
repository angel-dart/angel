// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm_generator.test.models.tree;

// **************************************************************************
// SerializerGenerator
// **************************************************************************

abstract class TreeSerializer {
  static Tree fromMap(Map map) {
    return new Tree(
        id: map['id'] as String,
        rings: map['rings'] as int,
        fruits: map['fruits'] as List<dynamic>,
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

  static Map<String, dynamic> toMap(Tree model) {
    if (model == null) {
      return null;
    }
    return {
      'id': model.id,
      'rings': model.rings,
      'fruits': model.fruits,
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String()
    };
  }
}

abstract class TreeFields {
  static const List<String> allFields = const <String>[
    id,
    rings,
    fruits,
    createdAt,
    updatedAt
  ];

  static const String id = 'id';

  static const String rings = 'rings';

  static const String fruits = 'fruits';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';
}
