// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm_generator.test.models.role;

// **************************************************************************
// Generator: JsonModelGenerator
// **************************************************************************

class Role extends _Role {
  @override
  String id;

  @override
  String name;

  @override
  DateTime createdAt;

  @override
  DateTime updatedAt;

  Role({this.id, this.name, this.createdAt, this.updatedAt});

  factory Role.fromJson(Map data) {
    return new Role(
        id: data['id'],
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
        'name': name,
        'created_at': createdAt == null ? null : createdAt.toIso8601String(),
        'updated_at': updatedAt == null ? null : updatedAt.toIso8601String()
      };

  static Role parse(Map map) => new Role.fromJson(map);

  Role clone() {
    return new Role.fromJson(toJson());
  }
}
