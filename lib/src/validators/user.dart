import 'package:angel_validate/angel_validate.dart';

final Validator USER = new Validator({
  'email': [isString, isNotEmpty, isEmail],
  'username': [isString, isNotEmpty],
  'password': [isString, isNotEmpty]
});

final Validator CREATE_USER = USER.extend({})
  ..requiredFields.addAll(['email', 'username', 'password'])
  ..forbiddenFields.addAll(['salt', 'roles']);
