// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// Generator: PostgresServiceGenerator
// **************************************************************************

import 'dart:async';
import 'package:angel_framework/angel_framework.dart';
import 'package:postgres/postgres.dart';
import 'order.dart';
import 'order.orm.g.dart';

class OrderService extends Service {
  final PostgreSQLConnection connection;

  final bool allowRemoveAll;

  final bool allowQuery;

  OrderService(this.connection,
      {this.allowRemoveAll: false, this.allowQuery: false});

  OrderQuery buildQuery(Map params) {
    var query = new OrderQuery();
    if (params['query'] is Map) {
      query.where.id.equals(params['query']['id']);
      query.where.customerId.equals(params['query']['customer_id']);
      query.where.employeeId.equals(params['query']['employee_id']);
      query.where.orderDate.equals(params['query']['order_date'] is String
          ? DateTime.parse(params['query']['order_date'])
          : params['query']['order_date'] != null
              ? params['query']['order_date'] is String
                  ? DateTime.parse(params['query']['order_date'])
                  : params['query']['order_date']
              : new DateTime.now());
      query.where.shipperId.equals(params['query']['shipper_id']);
      query.where.createdAt.equals(params['query']['created_at'] is String
          ? DateTime.parse(params['query']['created_at'])
          : params['query']['created_at'] != null
              ? params['query']['created_at'] is String
                  ? DateTime.parse(params['query']['created_at'])
                  : params['query']['created_at']
              : new DateTime.now());
      query.where.updatedAt.equals(params['query']['updated_at'] is String
          ? DateTime.parse(params['query']['updated_at'])
          : params['query']['updated_at'] != null
              ? params['query']['updated_at'] is String
                  ? DateTime.parse(params['query']['updated_at'])
                  : params['query']['updated_at']
              : new DateTime.now());
    }
    return query;
  }

  int toId(id) {
    if (id is int) {
      return id;
    } else {
      if (id == 'null' || id == null) {
        return null;
      } else {
        return int.parse(id.toString());
      }
    }
  }

  Order applyData(data) {
    if (data is Order || data == null) {
      return data;
    }
    if (data is Map) {
      var query = new Order();
      if (data.containsKey('customer_id')) {
        query.customerId = data['customer_id'];
      }
      if (data.containsKey('employee_id')) {
        query.employeeId = data['employee_id'];
      }
      if (data.containsKey('order_date')) {
        query.orderDate = data['order_date'] is String
            ? DateTime.parse(data['order_date'])
            : data['order_date'] != null
                ? data['order_date'] is String
                    ? DateTime.parse(data['order_date'])
                    : data['order_date']
                : new DateTime.now();
      }
      if (data.containsKey('shipper_id')) {
        query.shipperId = data['shipper_id'];
      }
      if (data.containsKey('created_at')) {
        query.createdAt = data['created_at'] is String
            ? DateTime.parse(data['created_at'])
            : data['created_at'] != null
                ? data['created_at'] is String
                    ? DateTime.parse(data['created_at'])
                    : data['created_at']
                : new DateTime.now();
      }
      if (data.containsKey('updated_at')) {
        query.updatedAt = data['updated_at'] is String
            ? DateTime.parse(data['updated_at'])
            : data['updated_at'] != null
                ? data['updated_at'] is String
                    ? DateTime.parse(data['updated_at'])
                    : data['updated_at']
                : new DateTime.now();
      }
      return query;
    } else
      throw new AngelHttpException.badRequest(message: 'Invalid data.');
  }

  Future<List<Order>> index([Map params]) {
    return buildQuery(params).get(connection).toList();
  }

  Future<Order> create(data, [Map params]) {
    return OrderQuery.insertOrder(connection, applyData(data));
  }

  Future<Order> read(id, [Map params]) {
    var query = buildQuery(params);
    query.where.id.equals(toId(id));
    return query.get(connection).first.catchError((_) {
      new AngelHttpException.notFound(
          message: 'No record found for ID ' + id.toString());
    });
  }

  Future<Order> remove(id, [Map params]) {
    var query = buildQuery(params);
    query.where.id.equals(toId(id));
    return query.delete(connection).first.catchError((_) {
      new AngelHttpException.notFound(
          message: 'No record found for ID ' + id.toString());
    });
  }

  Future<Order> update(id, data, [Map params]) {
    return OrderQuery.updateOrder(connection, applyData(data));
  }

  Future<Order> modify(id, data, [Map params]) async {
    var query = await read(toId(id), params);
    if (data is Order) {
      query = data;
    }
    if (data is Map) {
      if (data.containsKey('customer_id')) {
        query.customerId = data['customer_id'];
      }
      if (data.containsKey('employee_id')) {
        query.employeeId = data['employee_id'];
      }
      if (data.containsKey('order_date')) {
        query.orderDate = data['order_date'] is String
            ? DateTime.parse(data['order_date'])
            : data['order_date'] != null
                ? data['order_date'] is String
                    ? DateTime.parse(data['order_date'])
                    : data['order_date']
                : new DateTime.now();
      }
      if (data.containsKey('shipper_id')) {
        query.shipperId = data['shipper_id'];
      }
      if (data.containsKey('created_at')) {
        query.createdAt = data['created_at'] is String
            ? DateTime.parse(data['created_at'])
            : data['created_at'] != null
                ? data['created_at'] is String
                    ? DateTime.parse(data['created_at'])
                    : data['created_at']
                : new DateTime.now();
      }
      if (data.containsKey('updated_at')) {
        query.updatedAt = data['updated_at'] is String
            ? DateTime.parse(data['updated_at'])
            : data['updated_at'] != null
                ? data['updated_at'] is String
                    ? DateTime.parse(data['updated_at'])
                    : data['updated_at']
                : new DateTime.now();
      }
    }
    return await OrderQuery.updateOrder(connection, query);
  }
}
