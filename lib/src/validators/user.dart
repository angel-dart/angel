import 'package:angel_validate/angel_validate.dart';

// Validators can be used on the server, in the browser, and even in Flutter.
//
// It is highly recommended that you read the documentation:
// https://github.com/angel-dart/validate
final Validator USER = new Validator({
  'email': [isString, isNotEmpty, isEmail],
  'username': [isString, isNotEmpty],
  'password': [isString, isNotEmpty]
});

final Validator CREATE_USER = USER.extend({})
  ..requiredFields.addAll(['email', 'username', 'password'])
  ..forbiddenFields.addAll(['salt', 'roles']);
