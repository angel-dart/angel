// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// Generator: PostgresOrmGenerator
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
    _sortKey = ('' + key);
  }

  void sortAscending(String key) {
    _sortMode = 'Ascending';
    _sortKey = ('' + key);
  }

  void or(CarQueryWhere selector) {
    _or.add(selector);
  }

  String toSql([String prefix]) {
    var buf = new StringBuffer();
    buf.write(prefix != null
        ? prefix
        : 'SELECT id, make, description, family_friendly, recalled_at, created_at, updated_at FROM "cars"');
    if (prefix == null) {}
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
    var result = new Car.fromJson({
      'id': row[0].toString(),
      'make': row[1],
      'description': row[2],
      'family_friendly': row[3],
      'recalled_at': row[4],
      'created_at': row[5],
      'updated_at': row[6]
    });
    return result;
  }

  Stream<Car> get(PostgreSQLConnection connection) {
    StreamController<Car> ctrl = new StreamController<Car>();
    connection.query(toSql()).then((rows) async {
      var futures = rows.map((row) async {
        var parsed = parseRow(row);
        return parsed;
      });
      var output = await Future.wait(futures);
      output.forEach(ctrl.add);
      ctrl.close();
    }).catchError(ctrl.addError);
    return ctrl.stream;
  }

  static Future<Car> getOne(int id, PostgreSQLConnection connection) {
    var query = new CarQuery();
    query.where.id.equals(id);
    return query.get(connection).first.catchError((_) => null);
  }

  Stream<Car> update(PostgreSQLConnection connection,
      {String make,
      String description,
      bool familyFriendly,
      DateTime recalledAt,
      DateTime createdAt,
      DateTime updatedAt}) {
    var buf = new StringBuffer(
        'UPDATE "cars" SET ("make", "description", "family_friendly", "recalled_at", "created_at", "updated_at") = (@make, @description, @familyFriendly, CAST (@recalledAt AS timestamp), CAST (@createdAt AS timestamp), CAST (@updatedAt AS timestamp)) ');
    var whereClause = where.toWhereClause();
    if (whereClause != null) {
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
        }).then((rows) async {
      var futures = rows.map((row) async {
        var parsed = parseRow(row);
        return parsed;
      });
      var output = await Future.wait(futures);
      output.forEach(ctrl.add);
      ctrl.close();
    }).catchError(ctrl.addError);
    return ctrl.stream;
  }

  Stream<Car> delete(PostgreSQLConnection connection) {
    StreamController<Car> ctrl = new StreamController<Car>();
    connection
        .query(toSql('DELETE FROM "cars"') +
            ' RETURNING "id", "make", "description", "family_friendly", "recalled_at", "created_at", "updated_at";')
        .then((rows) async {
      var futures = rows.map((row) async {
        var parsed = parseRow(row);
        return parsed;
      });
      var output = await Future.wait(futures);
      output.forEach(ctrl.add);
      ctrl.close();
    }).catchError(ctrl.addError);
    return ctrl.stream;
  }

  static Future<Car> deleteOne(int id, PostgreSQLConnection connection) {
    var query = new CarQuery();
    query.where.id.equals(id);
    return query.delete(connection).first;
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
        'INSERT INTO "cars" ("make", "description", "family_friendly", "recalled_at", "created_at", "updated_at") VALUES (@make, @description, @familyFriendly, CAST (@recalledAt AS timestamp), CAST (@createdAt AS timestamp), CAST (@updatedAt AS timestamp)) RETURNING "id", "make", "description", "family_friendly", "recalled_at", "created_at", "updated_at";',
        substitutionValues: {
          'make': make,
          'description': description,
          'familyFriendly': familyFriendly,
          'recalledAt': recalledAt,
          'createdAt': createdAt != null ? createdAt : __ormNow__,
          'updatedAt': updatedAt != null ? updatedAt : __ormNow__
        });
    var output = parseRow(result[0]);
    return output;
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
      new DateTimeSqlExpressionBuilder('cars.recalled_at');

  final DateTimeSqlExpressionBuilder createdAt =
      new DateTimeSqlExpressionBuilder('cars.created_at');

  final DateTimeSqlExpressionBuilder updatedAt =
      new DateTimeSqlExpressionBuilder('cars.updated_at');

  String toWhereClause({bool keyword}) {
    final List<String> expressions = [];
    if (id.hasValue) {
      expressions.add('cars.id ' + id.compile());
    }
    if (make.hasValue) {
      expressions.add('cars.make ' + make.compile());
    }
    if (description.hasValue) {
      expressions.add('cars.description ' + description.compile());
    }
    if (familyFriendly.hasValue) {
      expressions.add('cars.family_friendly ' + familyFriendly.compile());
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

class CarFields {
  static const id = 'id';

  static const make = 'make';

  static const description = 'description';

  static const familyFriendly = 'family_friendly';

  static const recalledAt = 'recalled_at';

  static const createdAt = 'created_at';

  static const updatedAt = 'updated_at';
}
