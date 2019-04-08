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

  @ManyToMany(_RoleUser)
  List<_Role> get roles;
}

@serializable
@orm
abstract class _RoleUser {
  @belongsTo
  _Role get role;

  @belongsTo
  _User get user;
}

@serializable
@orm
abstract class _Role extends Model {
  String name;

  @ManyToMany(_RoleUser)
  List<_User> get users;
}
