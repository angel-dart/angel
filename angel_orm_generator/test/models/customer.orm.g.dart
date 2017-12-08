// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// Generator: PostgresOrmGenerator
// **************************************************************************

import 'dart:async';
import 'package:angel_orm/angel_orm.dart';
import 'package:postgres/postgres.dart';
import 'customer.dart';

class CustomerQuery {
  final Map<CustomerQuery, bool> _unions = {};

  String _sortKey;

  String _sortMode;

  int limit;

  int offset;

  final List<CustomerQueryWhere> _or = [];

  final CustomerQueryWhere where = new CustomerQueryWhere();

  void union(CustomerQuery query) {
    _unions[query] = false;
  }

  void unionAll(CustomerQuery query) {
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

  void or(CustomerQueryWhere selector) {
    _or.add(selector);
  }

  String toSql([String prefix]) {
    var buf = new StringBuffer();
    buf.write(prefix != null
        ? prefix
        : 'SELECT id, created_at, updated_at FROM "customers"');
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

  static Customer parseRow(List row) {
    var result = new Customer.fromJson(
        {'id': row[0].toString(), 'created_at': row[1], 'updated_at': row[2]});
    return result;
  }

  Stream<Customer> get(PostgreSQLConnection connection) {
    StreamController<Customer> ctrl = new StreamController<Customer>();
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

  static Future<Customer> getOne(int id, PostgreSQLConnection connection) {
    var query = new CustomerQuery();
    query.where.id.equals(id);
    return query.get(connection).first.catchError((_) => null);
  }

  Stream<Customer> update(PostgreSQLConnection connection,
      {DateTime createdAt, DateTime updatedAt}) {
    var buf = new StringBuffer(
        'UPDATE "customers" SET ("created_at", "updated_at") = (CAST (@createdAt AS timestamp), CAST (@updatedAt AS timestamp)) ');
    var whereClause = where.toWhereClause();
    if (whereClause != null) {
      buf.write(whereClause);
    }
    var __ormNow__ = new DateTime.now();
    var ctrl = new StreamController<Customer>();
    connection.query(
        buf.toString() + ' RETURNING "id", "created_at", "updated_at";',
        substitutionValues: {
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

  Stream<Customer> delete(PostgreSQLConnection connection) {
    StreamController<Customer> ctrl = new StreamController<Customer>();
    connection
        .query(toSql('DELETE FROM "customers"') +
            ' RETURNING "id", "created_at", "updated_at";')
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

  static Future<Customer> deleteOne(int id, PostgreSQLConnection connection) {
    var query = new CustomerQuery();
    query.where.id.equals(id);
    return query.delete(connection).first;
  }

  static Future<Customer> insert(PostgreSQLConnection connection,
      {DateTime createdAt, DateTime updatedAt}) async {
    var __ormNow__ = new DateTime.now();
    var result = await connection.query(
        'INSERT INTO "customers" ("created_at", "updated_at") VALUES (CAST (@createdAt AS timestamp), CAST (@updatedAt AS timestamp)) RETURNING "id", "created_at", "updated_at";',
        substitutionValues: {
          'createdAt': createdAt != null ? createdAt : __ormNow__,
          'updatedAt': updatedAt != null ? updatedAt : __ormNow__
        });
    var output = parseRow(result[0]);
    return output;
  }

  static Future<Customer> insertCustomer(
      PostgreSQLConnection connection, Customer customer) {
    return CustomerQuery.insert(connection,
        createdAt: customer.createdAt, updatedAt: customer.updatedAt);
  }

  static Future<Customer> updateCustomer(
      PostgreSQLConnection connection, Customer customer) {
    var query = new CustomerQuery();
    query.where.id.equals(int.parse(customer.id));
    return query
        .update(connection,
            createdAt: customer.createdAt, updatedAt: customer.updatedAt)
        .first;
  }

  static Stream<Customer> getAll(PostgreSQLConnection connection) =>
      new CustomerQuery().get(connection);
}

class CustomerQueryWhere {
  final NumericSqlExpressionBuilder<int> id =
      new NumericSqlExpressionBuilder<int>();

  final DateTimeSqlExpressionBuilder createdAt =
      new DateTimeSqlExpressionBuilder('customers.created_at');

  final DateTimeSqlExpressionBuilder updatedAt =
      new DateTimeSqlExpressionBuilder('customers.updated_at');

  String toWhereClause({bool keyword}) {
    final List<String> expressions = [];
    if (id.hasValue) {
      expressions.add('customers.id ' + id.compile());
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

class CustomerFields {
  static const id = 'id';

  static const createdAt = 'created_at';

  static const updatedAt = 'updated_at';
}
