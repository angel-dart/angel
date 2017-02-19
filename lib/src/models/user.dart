library angel.models.user;

import 'package:angel_framework/common.dart';

class User extends Model {
  String email, username, password;
  final List<String> roles = [];

  User(
      {String id,
      this.email,
      this.username,
      this.password,
      Iterable<String> roles: const []}) {
    this.id = id;
    this.roles.addAll(roles ?? []);
  }
}
