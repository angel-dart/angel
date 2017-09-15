// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// Generator: PostgresOrmGenerator
// **************************************************************************

import 'dart:async';
import 'package:angel_orm/angel_orm.dart';
import 'package:postgres/postgres.dart';
import 'tree.dart';
import 'fruit.orm.g.dart';

class TreeQuery {
  final Map<TreeQuery, bool> _unions = {};

  String _sortKey;

  String _sortMode;

  int limit;

  int offset;

  final List<TreeQueryWhere> _or = [];

  final TreeQueryWhere where = new TreeQueryWhere();

  void union(TreeQuery query) {
    _unions[query] = false;
  }

  void unionAll(TreeQuery query) {
    _unions[query] = true;
  }

  void sortDescending(String key) {
    _sortMode = 'Descending';
    _sortKey = ('trees.' + key);
  }

  void sortAscending(String key) {
    _sortMode = 'Ascending';
    _sortKey = ('trees.' + key);
  }

  void or(TreeQueryWhere selector) {
    _or.add(selector);
  }

  String toSql([String prefix]) {
    var buf = new StringBuffer();
    buf.write(prefix != null
        ? prefix
        : 'SELECT trees.id, trees.rings, trees.created_at, trees.updated_at FROM "trees"');
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

  static Tree parseRow(List row) {
    var result = new Tree.fromJson({
      'id': row[0].toString(),
      'rings': row[1],
      'created_at': row[2],
      'updated_at': row[3]
    });
    if (row.length > 4) {
      result.fruits =
          FruitQuery.parseRow([row[4], row[5], row[6], row[7], row[8]]);
    }
    return result;
  }

  Stream<Tree> get(PostgreSQLConnection connection) {
    StreamController<Tree> ctrl = new StreamController<Tree>();
    connection.query(toSql()).then((rows) async {
      var futures = rows.map((row) async {
        var parsed = parseRow(row);
        var fruitQuery = new FruitQuery();
        fruitQuery.where.treeId.equals(row[0]);
        parsed.fruits =
            await fruitQuery.get(connection).toList().catchError((_) => []);
        return parsed;
      });
      var output = await Future.wait(futures);
      output.forEach(ctrl.add);
      ctrl.close();
    }).catchError(ctrl.addError);
    return ctrl.stream;
  }

  static Future<Tree> getOne(int id, PostgreSQLConnection connection) {
    var query = new TreeQuery();
    query.where.id.equals(id);
    return query.get(connection).first.catchError((_) => null);
  }

  Stream<Tree> update(PostgreSQLConnection connection,
      {int rings, DateTime createdAt, DateTime updatedAt}) {
    var buf = new StringBuffer(
        'UPDATE "trees" SET ("rings", "created_at", "updated_at") = (@rings, @createdAt, @updatedAt) ');
    var whereClause = where.toWhereClause();
    if (whereClause != null) {
      buf.write(whereClause);
    }
    var __ormNow__ = new DateTime.now();
    var ctrl = new StreamController<Tree>();
    connection.query(
        buf.toString() +
            ' RETURNING "id", "rings", "created_at", "updated_at";',
        substitutionValues: {
          'rings': rings,
          'createdAt': createdAt != null ? createdAt : __ormNow__,
          'updatedAt': updatedAt != null ? updatedAt : __ormNow__
        }).then((rows) async {
      var futures = rows.map((row) async {
        var parsed = parseRow(row);
        var fruitQuery = new FruitQuery();
        fruitQuery.where.treeId.equals(row[0]);
        parsed.fruits =
            await fruitQuery.get(connection).toList().catchError((_) => []);
        return parsed;
      });
      var output = await Future.wait(futures);
      output.forEach(ctrl.add);
      ctrl.close();
    }).catchError(ctrl.addError);
    return ctrl.stream;
  }

  Stream<Tree> delete(PostgreSQLConnection connection) {
    StreamController<Tree> ctrl = new StreamController<Tree>();
    connection
        .query(toSql('DELETE FROM "trees"') +
            ' RETURNING "id", "rings", "created_at", "updated_at";')
        .then((rows) async {
      var futures = rows.map((row) async {
        var parsed = parseRow(row);
        var fruitQuery = new FruitQuery();
        fruitQuery.where.treeId.equals(row[0]);
        parsed.fruits =
            await fruitQuery.get(connection).toList().catchError((_) => []);
        return parsed;
      });
      var output = await Future.wait(futures);
      output.forEach(ctrl.add);
      ctrl.close();
    }).catchError(ctrl.addError);
    return ctrl.stream;
  }

  static Future<Tree> deleteOne(int id, PostgreSQLConnection connection) {
    var query = new TreeQuery();
    query.where.id.equals(id);
    return query.delete(connection).first;
  }

  static Future<Tree> insert(PostgreSQLConnection connection,
      {int rings, DateTime createdAt, DateTime updatedAt}) async {
    var __ormNow__ = new DateTime.now();
    var result = await connection.query(
        'INSERT INTO "trees" ("rings", "created_at", "updated_at") VALUES (@rings, @createdAt, @updatedAt) RETURNING "id", "rings", "created_at", "updated_at";',
        substitutionValues: {
          'rings': rings,
          'createdAt': createdAt != null ? createdAt : __ormNow__,
          'updatedAt': updatedAt != null ? updatedAt : __ormNow__
        });
    var output = parseRow(result[0]);
    var fruitQuery = new FruitQuery();
    fruitQuery.where.treeId.equals(result[0][0]);
    output.fruits =
        await fruitQuery.get(connection).toList().catchError((_) => []);
    return output;
  }

  static Future<Tree> insertTree(PostgreSQLConnection connection, Tree tree) {
    return TreeQuery.insert(connection,
        rings: tree.rings,
        createdAt: tree.createdAt,
        updatedAt: tree.updatedAt);
  }

  static Future<Tree> updateTree(PostgreSQLConnection connection, Tree tree) {
    var query = new TreeQuery();
    query.where.id.equals(int.parse(tree.id));
    return query
        .update(connection,
            rings: tree.rings,
            createdAt: tree.createdAt,
            updatedAt: tree.updatedAt)
        .first;
  }

  static Stream<Tree> getAll(PostgreSQLConnection connection) =>
      new TreeQuery().get(connection);
}

class TreeQueryWhere {
  final NumericSqlExpressionBuilder<int> id =
      new NumericSqlExpressionBuilder<int>();

  final NumericSqlExpressionBuilder<int> rings =
      new NumericSqlExpressionBuilder<int>();

  final DateTimeSqlExpressionBuilder createdAt =
      new DateTimeSqlExpressionBuilder('trees.created_at');

  final DateTimeSqlExpressionBuilder updatedAt =
      new DateTimeSqlExpressionBuilder('trees.updated_at');

  String toWhereClause({bool keyword}) {
    final List<String> expressions = [];
    if (id.hasValue) {
      expressions.add('trees.id ' + id.compile());
    }
    if (rings.hasValue) {
      expressions.add('trees.rings ' + rings.compile());
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
