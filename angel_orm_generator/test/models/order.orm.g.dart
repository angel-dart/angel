// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// Generator: PostgresOrmGenerator
// **************************************************************************

import 'dart:async';
import 'package:angel_orm/angel_orm.dart';
import 'package:postgres/postgres.dart';
import 'order.dart';

class OrderQuery {
  final Map<OrderQuery, bool> _unions = {};

  String _sortKey;

  String _sortMode;

  int limit;

  int offset;

  final List<OrderQueryWhere> _or = [];

  final OrderQueryWhere where = new OrderQueryWhere();

  void union(OrderQuery query) {
    _unions[query] = false;
  }

  void unionAll(OrderQuery query) {
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

  void or(OrderQueryWhere selector) {
    _or.add(selector);
  }

  String toSql([String prefix]) {
    var buf = new StringBuffer();
    buf.write(prefix != null
        ? prefix
        : 'SELECT id, customer_id, employee_id, order_date, shipper_id, created_at, updated_at FROM "orders"');
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

  static Order parseRow(List row) {
    var result = new Order.fromJson({
      'id': row[0].toString(),
      'customer_id': row[1],
      'employee_id': row[2],
      'order_date': row[3],
      'shipper_id': row[4],
      'created_at': row[5],
      'updated_at': row[6]
    });
    return result;
  }

  Stream<Order> get(PostgreSQLConnection connection) {
    StreamController<Order> ctrl = new StreamController<Order>();
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

  static Future<Order> getOne(int id, PostgreSQLConnection connection) {
    var query = new OrderQuery();
    query.where.id.equals(id);
    return query.get(connection).first.catchError((_) => null);
  }

  Stream<Order> update(PostgreSQLConnection connection,
      {int customerId,
      int employeeId,
      DateTime orderDate,
      int shipperId,
      DateTime createdAt,
      DateTime updatedAt}) {
    var buf = new StringBuffer(
        'UPDATE "orders" SET ("customer_id", "employee_id", "order_date", "shipper_id", "created_at", "updated_at") = (@customerId, @employeeId, @orderDate, @shipperId, @createdAt, @updatedAt) ');
    var whereClause = where.toWhereClause();
    if (whereClause != null) {
      buf.write(whereClause);
    }
    var __ormNow__ = new DateTime.now();
    var ctrl = new StreamController<Order>();
    connection.query(
        buf.toString() +
            ' RETURNING "id", "customer_id", "employee_id", "order_date", "shipper_id", "created_at", "updated_at";',
        substitutionValues: {
          'customerId': customerId,
          'employeeId': employeeId,
          'orderDate': orderDate,
          'shipperId': shipperId,
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

  Stream<Order> delete(PostgreSQLConnection connection) {
    StreamController<Order> ctrl = new StreamController<Order>();
    connection
        .query(toSql('DELETE FROM "orders"') +
            ' RETURNING "id", "customer_id", "employee_id", "order_date", "shipper_id", "created_at", "updated_at";')
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

  static Future<Order> deleteOne(int id, PostgreSQLConnection connection) {
    var query = new OrderQuery();
    query.where.id.equals(id);
    return query.delete(connection).first;
  }

  static Future<Order> insert(PostgreSQLConnection connection,
      {int customerId,
      int employeeId,
      DateTime orderDate,
      int shipperId,
      DateTime createdAt,
      DateTime updatedAt}) async {
    var __ormNow__ = new DateTime.now();
    var result = await connection.query(
        'INSERT INTO "orders" ("customer_id", "employee_id", "order_date", "shipper_id", "created_at", "updated_at") VALUES (@customerId, @employeeId, @orderDate, @shipperId, @createdAt, @updatedAt) RETURNING "id", "customer_id", "employee_id", "order_date", "shipper_id", "created_at", "updated_at";',
        substitutionValues: {
          'customerId': customerId,
          'employeeId': employeeId,
          'orderDate': orderDate,
          'shipperId': shipperId,
          'createdAt': createdAt != null ? createdAt : __ormNow__,
          'updatedAt': updatedAt != null ? updatedAt : __ormNow__
        });
    var output = parseRow(result[0]);
    return output;
  }

  static Future<Order> insertOrder(
      PostgreSQLConnection connection, Order order) {
    return OrderQuery.insert(connection,
        customerId: order.customerId,
        employeeId: order.employeeId,
        orderDate: order.orderDate,
        shipperId: order.shipperId,
        createdAt: order.createdAt,
        updatedAt: order.updatedAt);
  }

  static Future<Order> updateOrder(
      PostgreSQLConnection connection, Order order) {
    var query = new OrderQuery();
    query.where.id.equals(int.parse(order.id));
    return query
        .update(connection,
            customerId: order.customerId,
            employeeId: order.employeeId,
            orderDate: order.orderDate,
            shipperId: order.shipperId,
            createdAt: order.createdAt,
            updatedAt: order.updatedAt)
        .first;
  }

  static Stream<Order> getAll(PostgreSQLConnection connection) =>
      new OrderQuery().get(connection);

  static joinCustomers(PostgreSQLConnection connection) {
  }
}

class OrderQueryWhere {
  final NumericSqlExpressionBuilder<int> id =
      new NumericSqlExpressionBuilder<int>();

  final NumericSqlExpressionBuilder<int> customerId =
      new NumericSqlExpressionBuilder<int>();

  final NumericSqlExpressionBuilder<int> employeeId =
      new NumericSqlExpressionBuilder<int>();

  final DateTimeSqlExpressionBuilder orderDate =
      new DateTimeSqlExpressionBuilder('orders.order_date');

  final NumericSqlExpressionBuilder<int> shipperId =
      new NumericSqlExpressionBuilder<int>();

  final DateTimeSqlExpressionBuilder createdAt =
      new DateTimeSqlExpressionBuilder('orders.created_at');

  final DateTimeSqlExpressionBuilder updatedAt =
      new DateTimeSqlExpressionBuilder('orders.updated_at');

  String toWhereClause({bool keyword}) {
    final List<String> expressions = [];
    if (id.hasValue) {
      expressions.add('orders.id ' + id.compile());
    }
    if (customerId.hasValue) {
      expressions.add('orders.customer_id ' + customerId.compile());
    }
    if (employeeId.hasValue) {
      expressions.add('orders.employee_id ' + employeeId.compile());
    }
    if (orderDate.hasValue) {
      expressions.add(orderDate.compile());
    }
    if (shipperId.hasValue) {
      expressions.add('orders.shipper_id ' + shipperId.compile());
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

class OrderFields {
  static const id = 'id';

  static const customerId = 'customer_id';

  static const employeeId = 'employee_id';

  static const orderDate = 'order_date';

  static const shipperId = 'shipper_id';

  static const createdAt = 'created_at';

  static const updatedAt = 'updated_at';
}
