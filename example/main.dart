import 'dart:async';
import 'package:angel_client/angel_client.dart';

Future doSomething(Angel app) async {
  var userService = app
      .service<String, Map<String, dynamic>>('api/users')
      .map(User.fromMap, User.toMap);

  var users = await userService.index();
  print('Name: ${users.first.name}');
}

class User {
  final String name;

  User({this.name});

  static User fromMap(Map data) => User(name: data['name'] as String);

  static Map<String, String> toMap(User user) => {'name': user.name};
}
