// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm_generator.test.models.foot;

// **************************************************************************
// Generator: JsonModelGenerator
// Target: class _Foot
// **************************************************************************

class Foot extends _Foot {
  @override
  String id;

  @override
  int legId;

  @override
  int nToes;

  @override
  DateTime createdAt;

  @override
  DateTime updatedAt;

  Foot({this.id, this.legId, this.nToes, this.createdAt, this.updatedAt});

  factory Foot.fromJson(Map data) {
    return new Foot(
        id: data['id'],
        legId: data['leg_id'],
        nToes: data['n_toes'],
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
        'leg_id': legId,
        'n_toes': nToes,
        'created_at': createdAt == null ? null : createdAt.toIso8601String(),
        'updated_at': updatedAt == null ? null : updatedAt.toIso8601String()
      };

  static Foot parse(Map map) => new Foot.fromJson(map);

  Foot clone() {
    return new Foot.fromJson(toJson());
  }
}
