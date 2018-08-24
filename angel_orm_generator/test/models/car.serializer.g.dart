// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm.generator.models.car;

// **************************************************************************
// SerializerGenerator
// **************************************************************************

abstract class CarSerializer {
  static Car fromMap(Map map) {
    return new Car(
        id: map['id'] as String,
        make: map['make'] as String,
        description: map['description'] as String,
        familyFriendly: map['family_friendly'] as bool,
        recalledAt: map['recalled_at'] != null
            ? (map['recalled_at'] is DateTime
                ? (map['recalled_at'] as DateTime)
                : DateTime.parse(map['recalled_at'].toString()))
            : null,
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

  static Map<String, dynamic> toMap(Car model) {
    if (model == null) {
      return null;
    }
    return {
      'id': model.id,
      'make': model.make,
      'description': model.description,
      'family_friendly': model.familyFriendly,
      'recalled_at': model.recalledAt?.toIso8601String(),
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String()
    };
  }
}

abstract class CarFields {
  static const List<String> allFields = const <String>[
    id,
    make,
    description,
    familyFriendly,
    recalledAt,
    createdAt,
    updatedAt
  ];

  static const String id = 'id';

  static const String make = 'make';

  static const String description = 'description';

  static const String familyFriendly = 'family_friendly';

  static const String recalledAt = 'recalled_at';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';
}
