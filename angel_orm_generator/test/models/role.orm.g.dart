// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// OrmGenerator
// **************************************************************************

import 'dart:async';
import 'role.dart';
part 'role.postgresql.orm.dart';

abstract class RoleOrm {
  Future<List<Role>> getAll();
  Future<Role> getById(id);
  Future<Role> update(Role model);
  RoleQuery query();
}

class RoleQuery {}
