library angel.models.user;

import 'package:angel_mongo/model.dart';
import 'package:source_gen/generators/json_serializable.dart';

part 'user.g.dart';

@JsonSerializable()
class User extends Model with _$UserSerializerMixin {
  @JsonKey('email')
  String email;

  @JsonKey('username')
  String username;

  @JsonKey('password')
  String password;

  @JsonKey('roles')
  final List<String> roles = [];

  factory User.fromJson(Map json) => _$UserFromJson(json);

  User(
      {String id,
      this.email,
      this.username,
      this.password,
      List<String> roles: const []}) {
    this.id = id;

    if (roles != null) {
      this.roles.addAll(roles);
    }
  }
}
