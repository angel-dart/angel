// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// OrmGenerator
// **************************************************************************

import 'dart:async';
import 'order.dart';
import 'package:postgres/postgres.dart';
part 'order.postgresql.orm.g.dart';

abstract class OrderOrm {
  factory OrderOrm.postgreSql(PostgreSQLConnection connection) =
      _PostgreSqlOrderOrmImpl;

  Future<List<Order>> getAll();
  Future<Order> getById(id);
  Future<Order> update(Order model);
  OrderQuery query();
}

class OrderQuery {}
