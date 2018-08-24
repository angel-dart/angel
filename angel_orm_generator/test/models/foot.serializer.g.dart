// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm_generator.test.models.foot;

// **************************************************************************
// SerializerGenerator
// **************************************************************************

abstract class FootSerializer {
  static Foot fromMap(Map map) {
    return new Foot(
        id: map['id'] as String,
        legId: map['leg_id'] as int,
        nToes: map['n_toes'] as int,
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

  static Map<String, dynamic> toMap(Foot model) {
    if (model == null) {
      return null;
    }
    return {
      'id': model.id,
      'leg_id': model.legId,
      'n_toes': model.nToes,
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String()
    };
  }
}

abstract class FootFields {
  static const List<String> allFields = const <String>[
    id,
    legId,
    nToes,
    createdAt,
    updatedAt
  ];

  static const String id = 'id';

  static const String legId = 'leg_id';

  static const String nToes = 'n_toes';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';
}
