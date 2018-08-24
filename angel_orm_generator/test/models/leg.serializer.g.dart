// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm_generator.test.models.leg;

// **************************************************************************
// SerializerGenerator
// **************************************************************************

abstract class LegSerializer {
  static Leg fromMap(Map map) {
    return new Leg(
        id: map['id'] as String,
        foot: map['foot'] as dynamic,
        name: map['name'] as String,
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

  static Map<String, dynamic> toMap(Leg model) {
    if (model == null) {
      return null;
    }
    return {
      'id': model.id,
      'foot': model.foot,
      'name': model.name,
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String()
    };
  }
}

abstract class LegFields {
  static const List<String> allFields = const <String>[
    id,
    foot,
    name,
    createdAt,
    updatedAt
  ];

  static const String id = 'id';

  static const String foot = 'foot';

  static const String name = 'name';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';
}
