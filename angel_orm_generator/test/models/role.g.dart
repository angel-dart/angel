// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm_generator.test.models.role;

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class Role extends _Role {
  Role({this.id, this.name, this.createdAt, this.updatedAt});

  @override
  final String id;

  @override
  final String name;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  Role copyWith(
      {String id, String name, DateTime createdAt, DateTime updatedAt}) {
    return new Role(
        id: id ?? this.id,
        name: name ?? this.name,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt);
  }

  bool operator ==(other) {
    return other is _Role &&
        other.id == id &&
        other.name == name &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  Map<String, dynamic> toJson() {
    return RoleSerializer.toMap(this);
  }
}
