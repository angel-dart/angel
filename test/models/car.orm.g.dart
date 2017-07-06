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

  String toSql() {
    var buf = new StringBuffer('SELECT * FROM "cars"');
    var whereClause = where.toWhereClause();
    if (whereClause != null) {
      buf.write(' ' + whereClause);
    }
    buf.write(';');
    return buf.toString();
  }

  static Car parseRow(List row) {
    return new Car.fromJson({
      'id': row[0].toString(),
      'make': row[1],
      'description': row[2],
      'family_friendly': row[3] == 1,
      'recalled_at': DATE_YMD_HMS.parse(row[4]),
      'created_at': DATE_YMD_HMS.parse(row[5]),
      'updated_at': DATE_YMD_HMS.parse(row[6])
    });
  }

  Stream<Car> get(PostgreSQLConnection connection) {
    StreamController<Car> ctrl = new StreamController<Car>();
    connection.query(toSql()).then((rows) {
      rows.map(parseRow).forEach(ctrl.add);
      ctrl.close();
    }).catchError(ctrl.addError);
    return ctrl.stream;
  }

  static Future<Car> getOne(int id, PostgreSQLConnection connection) {
    return connection.query('SELECT * FROM "cars" WHERE "id" = @id;',
        substitutionValues: {'id': id}).then((rows) => parseRow(rows.first));
  }

  Future<Car> update(int id, PostgreSQLConnection connection,
      {String make,
      String description,
      bool familyFriendly,
      DateTime recalledAt,
      DateTime createdAt,
      DateTime updatedAt}) async {
    var __ormNow__ = new DateTime.now();
    var result = await connection.query(
        'UPDATE "cars" SET ("make", "description", "family_friendly", "recalled_at", "created_at", "updated_at") = (@make, @description, @familyFriendly, @recalledAt, @createdAt, @updatedAt) WHERE "id" = @id RETURNING ("id", "make", "description", "family_friendly", "recalled_at", "created_at", "updated_at");',
        substitutionValues: {
          'make': make,
          'description': description,
          'familyFriendly': familyFriendly,
          'recalledAt': recalledAt,
          'createdAt': createdAt != null ? createdAt : __ormNow__,
          'updatedAt': updatedAt != null ? updatedAt : __ormNow__,
          'id': id
        });
    return parseRow(result);
  }

  Future<Car> delete(int id, PostgreSQLConnection connection) async {
    var __ormBeforeDelete__ = await CarQuery.getOne(id, connection);
    var result = await connection.execute(
        'DELETE FROM "cars" WHERE id = @id LIMIT 1;',
        substitutionValues: {'id': id});
    if (result != 1) {
      new StateError('DELETE query deleted ' +
          result +
          ' row(s), instead of exactly 1 row.');
    }
    return __ormBeforeDelete__;
  }

  static Future<Car> insert(PostgreSQLConnection connection,
      {String make,
      String description,
      bool familyFriendly,
      DateTime recalledAt,
      DateTime createdAt,
      DateTime updatedAt}) async {
    var __ormNow__ = new DateTime.now();
    var result = await connection.query(
        'INSERT INTO "cars" ("make", "description", "family_friendly", "recalled_at", "created_at", "updated_at") VALUES (@make, @description, @familyFriendly, @recalledAt, @createdAt, @updatedAt) RETURNING ("id", "make", "description", "family_friendly", "recalled_at", "created_at", "updated_at");',
        substitutionValues: {
          'make': make,
          'description': description,
          'familyFriendly': familyFriendly,
          'recalledAt': recalledAt,
          'createdAt': createdAt != null ? createdAt : __ormNow__,
          'updatedAt': updatedAt != null ? updatedAt : __ormNow__
        });
    return parseRow(result);
  }

  static Stream<Car> getAll(PostgreSQLConnection connection) =>
      new CarQuery().get(connection);
}

class CarQueryWhere {
  final StringSqlExpressionBuilder id = new StringSqlExpressionBuilder();

  final StringSqlExpressionBuilder make = new StringSqlExpressionBuilder();

  final StringSqlExpressionBuilder description =
      new StringSqlExpressionBuilder();

  final BooleanSqlExpressionBuilder familyFriendly =
      new BooleanSqlExpressionBuilder();

  final DateTimeSqlExpressionBuilder recalledAt =
      new DateTimeSqlExpressionBuilder('recalled_at');

  final DateTimeSqlExpressionBuilder createdAt =
      new DateTimeSqlExpressionBuilder('created_at');

  final DateTimeSqlExpressionBuilder updatedAt =
      new DateTimeSqlExpressionBuilder('updated_at');

  String toWhereClause() {
    final List<String> expressions = [];
    if (id.hasValue) {
      expressions.add('"id" ' + id.compile());
    }
    if (make.hasValue) {
      expressions.add('"make" ' + make.compile());
    }
    if (description.hasValue) {
      expressions.add('"description" ' + description.compile());
    }
    if (familyFriendly.hasValue) {
      expressions.add('"family_friendly" ' + familyFriendly.compile());
    }
    if (recalledAt.hasValue) {
      expressions.add(recalledAt.compile());
    }
    if (createdAt.hasValue) {
      expressions.add(createdAt.compile());
    }
    if (updatedAt.hasValue) {
      expressions.add(updatedAt.compile());
    }
    return expressions.isEmpty ? null : ('WHERE ' + expressions.join(' AND '));
  }
}
