// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm_generator.test.models.leg;

// **************************************************************************
// Generator: JsonModelGenerator
// **************************************************************************

class Leg extends _Leg {
  @override
  String id;

  @override
  Foot foot;

  @override
  String name;

  @override
  DateTime createdAt;

  @override
  DateTime updatedAt;

  Leg({this.id, this.foot, this.name, this.createdAt, this.updatedAt});

  factory Leg.fromJson(Map data) {
    return new Leg(
        id: data['id'],
        foot: data['foot'] == null
            ? null
            : (data['foot'] is Foot
                ? data['foot']
                : new Foot.fromJson(data['foot'])),
        name: data['name'],
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
        'foot': foot,
        'name': name,
        'created_at': createdAt == null ? null : createdAt.toIso8601String(),
        'updated_at': updatedAt == null ? null : updatedAt.toIso8601String()
      };

  static Leg parse(Map map) => new Leg.fromJson(map);

  Leg clone() {
    return new Leg.fromJson(toJson());
  }
}
