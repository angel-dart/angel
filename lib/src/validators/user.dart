import 'package:angel_validate/angel_validate.dart';

final Validator CREATE_USER = new Validator({
  'email*': [isString, isEmail],
  'username*': [isString, isNotEmpty],
  'password*': [isString, isNotEmpty]
});
