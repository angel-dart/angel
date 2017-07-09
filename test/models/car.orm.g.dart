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
    var compiled = other.where.toWhereClause(keyword: false);
    if (compiled != null) {
      _and.add(compiled);
    }
  }

  void or(CarQuery other) {
    var compiled = other.where.toWhereClause(keyword: false);
    if (compiled != null) {
      _or.add(compiled);
    }
  }

  void not(CarQuery other) {
    var compiled = other.where.toWhereClause(keyword: false);
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
    if (_and.isNotEmpty) {
      buf.write(' AND (' + _and.join(',') + ')');
    }
    if (_or.isNotEmpty) {
      buf.write(' OR (' + _or.join(',') + ')');
    }
    if (_not.isNotEmpty) {
      buf.write(' NOT (' + _not.join(',') + ')');
    }
    buf.write(';');
    return buf.toString();
  }

  static Car parseRow(List row) {
    return new Car.fromJson({
      'id': row[0].toString(),
      'make': row[1],
      'description': row[2],
      'family_friendly': row[3],
      'recalled_at': row[4],
      'created_at': row[5],
      'updated_at': row[6]
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

  Stream<Car> update(PostgreSQLConnection connection,
      {String make,
      String description,
      bool familyFriendly,
      DateTime recalledAt,
      DateTime createdAt,
      DateTime updatedAt}) {
    var buf = new StringBuffer(
        'UPDATE "cars" SET ("make", "description", "family_friendly", "recalled_at", "created_at", "updated_at") = (@make, @description, @familyFriendly, @recalledAt, @createdAt, @updatedAt) ');
    var whereClause = where.toWhereClause();
    if (whereClause == null) {
      buf.write('WHERE "id" = @id');
    } else {
      buf.write(whereClause);
    }
    var __ormNow__ = new DateTime.now();
    var ctrl = new StreamController<Car>();
    connection.query(
        buf.toString() +
            ' RETURNING ("id", "make", "description", "family_friendly", "recalled_at", "created_at", "updated_at");',
        substitutionValues: {
          'make': make,
          'description': description,
          'familyFriendly': familyFriendly,
          'recalledAt': recalledAt,
          'createdAt': createdAt != null ? createdAt : __ormNow__,
          'updatedAt': updatedAt != null ? updatedAt : __ormNow__
        }).then((rows) {
      rows.map(parseRow).forEach(ctrl.add);
      ctrl.close();
    }).catchError(ctrl.addError);
    return ctrl.stream;
  }

  Stream<Car> delete(PostgreSQLConnection connection) {
    var query = 'DELETE FROM "cars" RETURNING ("id", "make", "description", "family_friendly", "recalled_at", "created_at", "updated_at");';
    StreamController<Car> ctrl = new StreamController<Car>();
    connection.execute(query).then((rows) {
      print('Rows: $rows');
      rows.map(parseRow).forEach(ctrl.add);
      ctrl.close();
    }).catchError(ctrl.addError);
    return ctrl.stream;
  }

  static Future<Car> deleteOne(int id, PostgreSQLConnection connection) async {
    var __ormBeforeDelete__ = await CarQuery.getOne(id, connection);
    var result = await connection.execute('DELETE FROM "cars" WHERE id = @id;',
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
    var nRows = await connection.execute(
        'INSERT INTO "cars" ("make", "description", "family_friendly", "recalled_at", "created_at", "updated_at") VALUES (@make, @description, @familyFriendly, @recalledAt, @createdAt, @updatedAt);',
        substitutionValues: {
          'make': make,
          'description': description,
          'familyFriendly': familyFriendly,
          'recalledAt': recalledAt,
          'createdAt': createdAt != null ? createdAt : __ormNow__,
          'updatedAt': updatedAt != null ? updatedAt : __ormNow__
        });
    if (nRows < 1) {
      throw new StateError('Insertion into "cars" table failed.');
    }
    var currVal = await connection.query(
        'SELECT * FROM "cars" WHERE id = currval(pg_get_serial_sequence(\'cars\', \'id\'));');
    return parseRow(currVal[0]);
  }

  static Stream<Car> getAll(PostgreSQLConnection connection) =>
      new CarQuery().get(connection);
}

class CarQueryWhere {
  final NumericSqlExpressionBuilder<int> id =
      new NumericSqlExpressionBuilder<int>();

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

  String toWhereClause({bool keyword}) {
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
    return expressions.isEmpty
        ? null
        : ((keyword != false ? 'WHERE ' : '') + expressions.join(' AND '));
  }
}
