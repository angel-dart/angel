// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// Generator: PostgresOrmGenerator
// **************************************************************************

import 'dart:async';
import 'package:angel_orm/angel_orm.dart';
import 'package:postgres/postgres.dart';
import 'fruit.dart';

class FruitQuery {
  final Map<FruitQuery, bool> _unions = {};

  String _sortKey;

  String _sortMode;

  int limit;

  int offset;

  final List<FruitQueryWhere> _or = [];

  final FruitQueryWhere where = new FruitQueryWhere();

  void union(FruitQuery query) {
    _unions[query] = false;
  }

  void unionAll(FruitQuery query) {
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

  void or(FruitQueryWhere selector) {
    _or.add(selector);
  }

  String toSql([String prefix]) {
    var buf = new StringBuffer();
    buf.write(prefix != null
        ? prefix
        : 'SELECT id, tree_id, common_name, created_at, updated_at FROM "fruits"');
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

  static Fruit parseRow(List row) {
    var result = new Fruit.fromJson({
      'id': row[0].toString(),
      'tree_id': row[1],
      'common_name': row[2],
      'created_at': row[3],
      'updated_at': row[4]
    });
    return result;
  }

  Stream<Fruit> get(PostgreSQLConnection connection) {
    StreamController<Fruit> ctrl = new StreamController<Fruit>();
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

  static Future<Fruit> getOne(int id, PostgreSQLConnection connection) {
    var query = new FruitQuery();
    query.where.id.equals(id);
    return query.get(connection).first.catchError((_) => null);
  }

  Stream<Fruit> update(PostgreSQLConnection connection,
      {int treeId, String commonName, DateTime createdAt, DateTime updatedAt}) {
    var buf = new StringBuffer(
        'UPDATE "fruits" SET ("tree_id", "common_name", "created_at", "updated_at") = (@treeId, @commonName, @createdAt, @updatedAt) ');
    var whereClause = where.toWhereClause();
    if (whereClause != null) {
      buf.write(whereClause);
    }
    var __ormNow__ = new DateTime.now();
    var ctrl = new StreamController<Fruit>();
    connection.query(
        buf.toString() +
            ' RETURNING "id", "tree_id", "common_name", "created_at", "updated_at";',
        substitutionValues: {
          'treeId': treeId,
          'commonName': commonName,
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

  Stream<Fruit> delete(PostgreSQLConnection connection) {
    StreamController<Fruit> ctrl = new StreamController<Fruit>();
    connection
        .query(toSql('DELETE FROM "fruits"') +
            ' RETURNING "id", "tree_id", "common_name", "created_at", "updated_at";')
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

  static Future<Fruit> deleteOne(int id, PostgreSQLConnection connection) {
    var query = new FruitQuery();
    query.where.id.equals(id);
    return query.delete(connection).first;
  }

  static Future<Fruit> insert(PostgreSQLConnection connection,
      {int treeId,
      String commonName,
      DateTime createdAt,
      DateTime updatedAt}) async {
    var __ormNow__ = new DateTime.now();
    var result = await connection.query(
        'INSERT INTO "fruits" ("tree_id", "common_name", "created_at", "updated_at") VALUES (@treeId, @commonName, @createdAt, @updatedAt) RETURNING "id", "tree_id", "common_name", "created_at", "updated_at";',
        substitutionValues: {
          'treeId': treeId,
          'commonName': commonName,
          'createdAt': createdAt != null ? createdAt : __ormNow__,
          'updatedAt': updatedAt != null ? updatedAt : __ormNow__
        });
    var output = parseRow(result[0]);
    return output;
  }

  static Future<Fruit> insertFruit(
      PostgreSQLConnection connection, Fruit fruit) {
    return FruitQuery.insert(connection,
        treeId: fruit.treeId,
        commonName: fruit.commonName,
        createdAt: fruit.createdAt,
        updatedAt: fruit.updatedAt);
  }

  static Future<Fruit> updateFruit(
      PostgreSQLConnection connection, Fruit fruit) {
    var query = new FruitQuery();
    query.where.id.equals(int.parse(fruit.id));
    return query
        .update(connection,
            treeId: fruit.treeId,
            commonName: fruit.commonName,
            createdAt: fruit.createdAt,
            updatedAt: fruit.updatedAt)
        .first;
  }

  static Stream<Fruit> getAll(PostgreSQLConnection connection) =>
      new FruitQuery().get(connection);
}

class FruitQueryWhere {
  final NumericSqlExpressionBuilder<int> id =
      new NumericSqlExpressionBuilder<int>();

  final NumericSqlExpressionBuilder<int> treeId =
      new NumericSqlExpressionBuilder<int>();

  final StringSqlExpressionBuilder commonName =
      new StringSqlExpressionBuilder();

  final DateTimeSqlExpressionBuilder createdAt =
      new DateTimeSqlExpressionBuilder('fruits.created_at');

  final DateTimeSqlExpressionBuilder updatedAt =
      new DateTimeSqlExpressionBuilder('fruits.updated_at');

  String toWhereClause({bool keyword}) {
    final List<String> expressions = [];
    if (id.hasValue) {
      expressions.add('fruits.id ' + id.compile());
    }
    if (treeId.hasValue) {
      expressions.add('fruits.tree_id ' + treeId.compile());
    }
    if (commonName.hasValue) {
      expressions.add('fruits.common_name ' + commonName.compile());
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

class FruitFields {
  static const id = 'id';

  static const treeId = 'tree_id';

  static const commonName = 'common_name';

  static const createdAt = 'created_at';

  static const updatedAt = 'updated_at';
}
