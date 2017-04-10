library angel.models.user;

import 'package:angel_framework/common.dart';

class User extends Model {
  @override
  String id;
  String email, username, password, salt;
  @override
  DateTime createdAt, updatedAt;

  User(
      {this.id,
      this.email,
      this.username,
      this.password,
      this.salt,
      this.createdAt,
      this.updatedAt});
}
