// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// Generator: PostgresServiceGenerator
// **************************************************************************

import 'dart:async';
import 'package:angel_framework/angel_framework.dart';
import 'package:postgres/postgres.dart';
import 'car.dart';
import 'car.orm.g.dart';

class CarService extends Service {
  final PostgreSQLConnection connection;

  final bool allowRemoveAll;

  final bool allowQuery;

  CarService(this.connection,
      {this.allowRemoveAll: false, this.allowQuery: false});

  CarQuery buildQuery(Map params) {
    var query = new CarQuery();
    if (params['query'] is Map) {
      query.where.id.equals(params['query']['id']);
      query.where.make.equals(params['query']['make']);
      query.where.description.equals(params['query']['description']);
      query.where.familyFriendly.equals(params['query']['family_friendly']);
      query.where.recalledAt.equals(params['query']['recalled_at'] is String
          ? DateTime.parse(params['query']['recalled_at'])
          : params['query']['recalled_at'] != null
              ? params['query']['recalled_at'] is String
                  ? DateTime.parse(params['query']['recalled_at'])
                  : params['query']['recalled_at']
              : new DateTime.now());
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

  Car applyData(data) {
    if (data is Car || data == null) {
      return data;
    }
    if (data is Map) {
      var query = new Car();
      if (data.containsKey('make')) {
        query.make = data['make'];
      }
      if (data.containsKey('description')) {
        query.description = data['description'];
      }
      if (data.containsKey('family_friendly')) {
        query.familyFriendly = data['family_friendly'];
      }
      if (data.containsKey('recalled_at')) {
        query.recalledAt = data['recalled_at'] is String
            ? DateTime.parse(data['recalled_at'])
            : data['recalled_at'] != null
                ? data['recalled_at'] is String
                    ? DateTime.parse(data['recalled_at'])
                    : data['recalled_at']
                : new DateTime.now();
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

  Future<List<Car>> index([Map params]) {
    return buildQuery(params).get(connection).toList();
  }

  Future<Car> create(data, [Map params]) {
    return CarQuery.insertCar(connection, applyData(data));
  }

  Future<Car> read(id, [Map params]) {
    var query = buildQuery(params);
    query.where.id.equals(toId(id));
    return query.get(connection).first.catchError((_) {
      new AngelHttpException.notFound(
          message: 'No record found for ID ' + id.toString());
    });
  }

  Future<Car> remove(id, [Map params]) {
    var query = buildQuery(params);
    query.where.id.equals(toId(id));
    return query.delete(connection).first.catchError((_) {
      new AngelHttpException.notFound(
          message: 'No record found for ID ' + id.toString());
    });
  }

  Future<Car> update(id, data, [Map params]) {
    return CarQuery.updateCar(connection, applyData(data));
  }

  Future<Car> modify(id, data, [Map params]) async {
    var query = await read(toId(id), params);
    if (data is Car) {
      query = data;
    }
    if (data is Map) {
      if (data.containsKey('make')) {
        query.make = data['make'];
      }
      if (data.containsKey('description')) {
        query.description = data['description'];
      }
      if (data.containsKey('family_friendly')) {
        query.familyFriendly = data['family_friendly'];
      }
      if (data.containsKey('recalled_at')) {
        query.recalledAt = data['recalled_at'] is String
            ? DateTime.parse(data['recalled_at'])
            : data['recalled_at'] != null
                ? data['recalled_at'] is String
                    ? DateTime.parse(data['recalled_at'])
                    : data['recalled_at']
                : new DateTime.now();
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
    return await CarQuery.updateCar(connection, query);
  }
}
