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
  final Map<CarQuery, bool> _unions = {};

  String _sortKey;

  String _sortMode;

  int limit;

  int offset;

  final List<CarQueryWhere> _or = [];

  final CarQueryWhere where = new CarQueryWhere();

  void union(CarQuery query) {
    _unions[query] = false;
  }

  void unionAll(CarQuery query) {
    _unions[query] = true;
  }

  void sortDescending(String key) {
    _sortMode = 'Descending';
    _sortKey = key;
  }

  void sortAscending(String key) {
    _sortMode = 'Ascending';
    _sortKey = key;
  }

  void or(CarQueryWhere selector) {
    _or.add(selector);
  }

  String toSql([String prefix]) {
    var buf = new StringBuffer();
    buf.write(prefix != null ? prefix : 'SELECT * FROM "cars"');
    var whereClause = where.toWhereClause();
    if (whereClause != null) {
      buf.write(' ' + whereClause);
    }
    _or.forEach((x) {
      var whereClause = x.toWhereClause(keyword: false);
      if (whereClause != null) {
        buf.write(' OR (' + whereClause + ')');
      }
    });
    if (prefix == null) {
      if (limit != null) {
        buf.write(' LIMIT ' + limit.toString());
      }
      if (offset != null) {
        buf.write(' OFFSET ' + offset.toString());
      }
      if (_sortMode == 'Descending') {
        buf.write(' ORDER BY "' + _sortKey + '" DESC');
      }
      if (_sortMode == 'Ascending') {
        buf.write(' ORDER BY "' + _sortKey + '" ASC');
      }
      _unions.forEach((query, all) {
        buf.write(' UNION');
        if (all) {
          buf.write(' ALL');
        }
        buf.write(' (');
        var sql = query.toSql().replaceAll(';', '');
        buf.write(sql + ')');
      });
      buf.write(';');
    }
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
            ' RETURNING "id", "make", "description", "family_friendly", "recalled_at", "created_at", "updated_at";',
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
    StreamController<Car> ctrl = new StreamController<Car>();
    connection
        .query(toSql('DELETE FROM "cars"') +
            ' RETURNING "id", "make", "description", "family_friendly", "recalled_at", "created_at", "updated_at";')
        .then((rows) {
      rows.map(parseRow).forEach(ctrl.add);
      ctrl.close();
    }).catchError(ctrl.addError);
    return ctrl.stream;
  }

  static Future<Car> deleteOne(int id, PostgreSQLConnection connection) async {
    var result = await connection.query(
        'DELETE FROM "cars" WHERE id = @id RETURNING "id", "make", "description", "family_friendly", "recalled_at", "created_at", "updated_at";',
        substitutionValues: {'id': id});
    return parseRow(result[0]);
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
        'INSERT INTO "cars" ("make", "description", "family_friendly", "recalled_at", "created_at", "updated_at") VALUES (@make, @description, @familyFriendly, @recalledAt, @createdAt, @updatedAt) RETURNING "id", "make", "description", "family_friendly", "recalled_at", "created_at", "updated_at";',
        substitutionValues: {
          'make': make,
          'description': description,
          'familyFriendly': familyFriendly,
          'recalledAt': recalledAt,
          'createdAt': createdAt != null ? createdAt : __ormNow__,
          'updatedAt': updatedAt != null ? updatedAt : __ormNow__
        });
    return parseRow(result[0]);
  }

  static Future<Car> insertCar(PostgreSQLConnection connection, Car car) {
    return CarQuery.insert(connection,
        make: car.make,
        description: car.description,
        familyFriendly: car.familyFriendly,
        recalledAt: car.recalledAt,
        createdAt: car.createdAt,
        updatedAt: car.updatedAt);
  }

  static Future<Car> updateCar(PostgreSQLConnection connection, Car car) {
    var query = new CarQuery();
    query.where.id.equals(int.parse(car.id));
    return query
        .update(connection,
            make: car.make,
            description: car.description,
            familyFriendly: car.familyFriendly,
            recalledAt: car.recalledAt,
            createdAt: car.createdAt,
            updatedAt: car.updatedAt)
        .first;
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
