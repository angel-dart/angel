// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// OrmGenerator
// **************************************************************************

import 'dart:async';
import 'foot.dart';
import 'package:postgres/postgres.dart';
part 'foot.postgresql.orm.g.dart';

abstract class FootOrm {
  factory FootOrm.postgreSql(PostgreSQLConnection connection) =
      _PostgreSqlFootOrmImpl;

  Future<List<Foot>> getAll();
  Future<Foot> getById(id);
  Future<Foot> update(Foot model);
  FootQuery query();
}

class FootQuery {}
