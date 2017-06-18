// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// Generator: PostgresORMGenerator
// Target: class _Car
// **************************************************************************

import 'dart:async';
import 'package:angel_orm/angel_orm.dart';
import 'package:postgres/postgres.dart';
import 'car.dart';

class CarQuery {
  final List<String> _and = [];

  final List<String> _or = [];

  final List<String> _not = [];

  final CarQueryWhere where = new CarQueryWhere();

  void and(CarQuery other) {
    var compiled = other.where.toWhereClause();
    if (compiled != null) {
      _and.add(compiled);
    }
  }

  void or(CarQuery other) {
    var compiled = other.where.toWhereClause();
    if (compiled != null) {
      _or.add(compiled);
    }
  }

  void not(CarQuery other) {
    var compiled = other.where.toWhereClause();
    if (compiled != null) {
      _not.add(compiled);
    }
  }

  Stream<Car> get() {}

  Future<Car> getOne() {}

  Future<Car> update() {}

  Future<Car> delete() {}

  static Future<Car> insert(PostgreSQLConnection connection,
      {String make,
      String description,
      bool familyFriendly,
      DateTime recalledAt}) {}

  static Stream<Car> getAll() => new CarQuery().get();
}

class CarQueryWhere {
  final StringSqlExpressionBuilder make = new StringSqlExpressionBuilder();

  final StringSqlExpressionBuilder description =
      new StringSqlExpressionBuilder();

  final BooleanSqlExpressionBuilder familyFriendly =
      new BooleanSqlExpressionBuilder();

  final DateTimeSqlExpressionBuilder recalledAt =
      new DateTimeSqlExpressionBuilder('recalled_at');

  String toWhereClause() {
    final List<String> expressions = [];
    if (make.hasValue) {
      expressions.add('`make` ' + make.compile());
    }
    if (description.hasValue) {
      expressions.add('`description` ' + description.compile());
    }
    if (familyFriendly.hasValue) {
      expressions.add('`family_friendly` ' + familyFriendly.compile());
    }
    if (recalledAt.hasValue) {
      expressions.add(recalledAt.compile());
    }
    return expressions.isEmpty ? null : ('WHERE ' + expressions.join(' AND '));
  }
}
