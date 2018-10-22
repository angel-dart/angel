// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// OrmGenerator
// **************************************************************************

import 'dart:async';
import 'package:postgres/postgres.dart';
import 'role.dart';
part 'role.postgresql.orm.g.dart';

abstract class RoleOrm {
  factory RoleOrm.postgreSql(PostgreSQLConnection connection) =
      _PostgreSqlRoleOrmImpl;

  Future<List<Role>> getAll();
  Future<Role> getById(String id);
  Future<Role> deleteById(String id);
  Future<Role> createRole(Role model);
  Future<Role> updateRole(Role model);
  RoleQuery query();
}

class RoleQuery {}
