library angel.models.user;

import 'dart:convert';
import 'package:angel_mongo/model.dart';

class User extends Model {
  String email;
  String username;
  String password;
  final List<String> roles = [];

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

  factory User.fromJson(String json) => new User.fromMap(JSON.decode(json));

  factory User.fromMap(Map data) => new User(
      id: data['id'],
      email: data['email'],
      username: data['username'],
      password: data['password'],
      roles: data['roles']);

  Map toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'password': password,
      'roles': roles
    };
  }
}
