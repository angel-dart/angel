library angel_orm_generator.test.models.user;

import 'package:angel_model/angel_model.dart';
import 'package:angel_orm/angel_orm.dart';
import 'package:angel_serialize/angel_serialize.dart';
import 'package:collection/collection.dart';
part 'user.g.dart';

@serializable
@orm
abstract class _User extends Model {
  String get username;
  String get password;
  String get email;

  @hasMany
  List<_UserRole> get userRoles;
}

@serializable
@orm
abstract class _Role extends Model {
  String name;

  @hasMany
  List<_UserRole> get userRoles;
}

@Serializable(autoIdAndDateFields: false)
@orm
abstract class _UserRole {
  int get id;

  @belongsTo
  _User get user;

  @belongsTo
  _Role get role;
}
