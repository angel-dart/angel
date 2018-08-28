// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// OrmGenerator
// **************************************************************************

import 'dart:async';
import 'fruit.dart';
import 'package:postgres/postgres.dart';
part 'fruit.postgresql.orm.g.dart';

abstract class FruitOrm {
  factory FruitOrm.postgreSql(PostgreSQLConnection connection) =
      _PostgreSqlFruitOrmImpl;

  Future<List<Fruit>> getAll();
  Future<Fruit> getById(id);
  Future<Fruit> update(Fruit model);
  FruitQuery query();
}

class FruitQuery {}
