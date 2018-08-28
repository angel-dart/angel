// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// OrmGenerator
// **************************************************************************

import 'car.dart';
import 'dart:async';
import 'package:postgres/postgres.dart';
part 'car.postgresql.orm.g.dart';

abstract class CarOrm {
  factory CarOrm.postgreSql(PostgreSQLConnection connection) =
      _PostgreSqlCarOrmImpl;

  Future<List<Car>> getAll();
  Future<Car> getById(id);
  Future<Car> update(Car model);
  CarQuery query();
}

class CarQuery {}
