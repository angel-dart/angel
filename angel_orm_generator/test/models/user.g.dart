// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm_generator.test.models.user;

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class User extends _User {
  User(
      {this.id,
      this.username,
      this.password,
      this.email,
      List<Role> roles,
      this.createdAt,
      this.updatedAt})
      : this.roles = new List.unmodifiable(roles ?? []);

  @override
  final String id;

  @override
  final String username;

  @override
  final String password;

  @override
  final String email;

  @override
  final List<Role> roles;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  User copyWith(
      {String id,
      String username,
      String password,
      String email,
      List<Role> roles,
      DateTime createdAt,
      DateTime updatedAt}) {
    return new User(
        id: id ?? this.id,
        username: username ?? this.username,
        password: password ?? this.password,
        email: email ?? this.email,
        roles: roles ?? this.roles,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt);
  }

  bool operator ==(other) {
    return other is _User &&
        other.id == id &&
        other.username == username &&
        other.password == password &&
        other.email == email &&
        const ListEquality<Role>(const DefaultEquality<Role>())
            .equals(other.roles, roles) &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return hashObjects(
        [id, username, password, email, roles, createdAt, updatedAt]);
  }

  Map<String, dynamic> toJson() {
    return UserSerializer.toMap(this);
  }
}
