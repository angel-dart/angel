library angel.models.user;

import 'dart:convert';
import 'package:angel_mongo/model.dart';

class User extends Model {
  String email;
  String username;
  String password;
  List<String> roles;

  User(
      {String this.email,
      String this.username,
      String this.password,
      List<String> roles}) {
    this.roles = roles ?? [];
  }

  factory User.fromJson(String json) => new User.fromMap(JSON.decode(json));

  factory User.fromMap(Map data) => new User(
      email: data["email"],
      username: data["username"],
      password: data["password"],
      roles: data["roles"]);

  Map toJson() {
    return {
      "email": email,
      "username": username,
      "password": password,
      "roles": roles
    };
  }
}
