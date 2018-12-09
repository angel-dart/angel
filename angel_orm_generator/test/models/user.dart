library angel_orm_generator.test.models.user;

import 'package:angel_migration/angel_migration.dart';
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

  List<_Role> get roles => userRoles.map((m) => m.role).toList();
}

@serializable
@orm
abstract class _Role extends Model {
  String name;

  @hasMany
  List<_UserRole> get userRoles;

  List<_User> get users => userRoles.map((m) => m.user).toList();
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
