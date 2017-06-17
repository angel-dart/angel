// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// Generator: AngelQueryBuilderGenerator
// Target: class _Car
// **************************************************************************

import 'dart:async';
import 'package:query_builder/query_builder.dart';
import 'package:postgres/postgres.dart';
import 'package:query_builder_sql/query_builder_sql.dart';
import 'car.dart';

class CarRepository {
  final PostgreSQLConnection connection;

  CarRepository(this.connection);

  CarRepositoryQuery all() => new CarRepositoryQuery(connection);

  CarRepositoryQuery whereId(String id) {
    return all().where('id', id);
  }

  CarRepositoryQuery whereCreatedAt(DateTime createdAt, {bool time: true}) {
    return all().whereDate('created_at', createdAt, time: time != false);
  }

  CarRepositoryQuery whereUpdatedAt(DateTime updatedAt, {bool time: true}) {
    return all().whereDate('updated_at', updatedAt, time: time != false);
  }
}

class CarRepositoryQuery extends SqlRepositoryQuery<Car> {
  final PostgreSQLConnection connection;

  CarRepositoryQuery(this.connection) : super('cars');

  CarRepositoryQuery whereId(String id) {
    return this.where('id', id);
  }

  CarRepositoryQuery whereCreatedAt(DateTime createdAt, {bool time: true}) {
    return this.whereDate('created_at', createdAt, time: time != false);
  }

  CarRepositoryQuery whereUpdatedAt(DateTime updatedAt, {bool time: true}) {
    return this.whereDate('updated_at', updatedAt, time: time != false);
  }

  CarRepositoryQuery orWhereId(String id) {
    return or(whereId(id));
  }

  CarRepositoryQuery orWhereCreatedAt(DateTime createdAt, {bool time}) {
    return or(whereCreatedAt(createdAt, time: time != false));
  }

  CarRepositoryQuery orWhereUpdatedAt(DateTime updatedAt, {bool time}) {
    return or(whereUpdatedAt(updatedAt, time: time != false));
  }

  @override
  CarRepositoryQuery latest([String fieldName]) {
    return super.latest(fieldName);
  }

  @override
  CarRepositoryQuery oldest([String fieldName]) {
    return super.oldest(fieldName);
  }

  @override
  CarRepositoryQuery where(String fieldName, dynamic value) {
    return super.where(fieldName, value);
  }

  @override
  CarRepositoryQuery whereNot(String fieldName, dynamic value) {
    return super.whereNot(fieldName, value);
  }

  @override
  CarRepositoryQuery whereNull(String fieldName) {
    return super.whereNull(fieldName);
  }

  @override
  CarRepositoryQuery whereNotNull(String fieldName) {
    return super.whereNotNull(fieldName);
  }

  @override
  CarRepositoryQuery distinct(Iterable fieldNames) {
    return super.distinct(fieldNames);
  }

  @override
  CarRepositoryQuery groupBy(String fieldName) {
    return super.groupBy(fieldName);
  }

  @override
  CarRepositoryQuery inRandomOrder() {
    return super.inRandomOrder();
  }

  @override
  CarRepositoryQuery orderBy(String fieldName, [OrderBy orderBy]) {
    return super.orderBy(fieldName, orderBy);
  }

  @override
  CarRepositoryQuery select(Iterable selectors) {
    return super.select(selectors);
  }

  @override
  CarRepositoryQuery skip(int count) {
    return super.skip(count);
  }

  @override
  CarRepositoryQuery take(int count) {
    return super.take(count);
  }

  @override
  CarRepositoryQuery join(
      String otherTable, String nearColumn, String farColumn,
      [JoinType joinType]) {
    return super.join(otherTable, nearColumn, farColumn, joinType);
  }

  @override
  CarRepositoryQuery union(RepositoryQuery other, [UnionType type]) {
    return super.union(other, type);
  }

  @override
  CarRepositoryQuery whereBetween(
      String fieldName, dynamic lower, dynamic upper) {
    return super.whereBetween(fieldName, lower, upper);
  }

  @override
  CarRepositoryQuery whereDate(String fieldName, DateTime date, {bool time}) {
    return super.whereDate(fieldName, date, time: time);
  }

  @override
  CarRepositoryQuery whereDay(String fieldName, int day) {
    return super.whereDay(fieldName, day);
  }

  @override
  CarRepositoryQuery whereEquality(
      String fieldName, dynamic value, Equality equality) {
    return super.whereEquality(fieldName, value, equality);
  }

  @override
  CarRepositoryQuery whereIn(String fieldName, Iterable values) {
    return super.whereIn(fieldName, values);
  }

  @override
  CarRepositoryQuery whereLike(String fieldName, dynamic value) {
    return super.whereLike(fieldName, value);
  }

  @override
  CarRepositoryQuery whereMonth(String fieldName, int month) {
    return super.whereMonth(fieldName, month);
  }

  @override
  CarRepositoryQuery whereNotBetween(
      String fieldName, dynamic lower, dynamic upper) {
    return super.whereNotBetween(fieldName, lower, upper);
  }

  @override
  CarRepositoryQuery whereNotIn(String fieldName, Iterable values) {
    return super.whereNotIn(fieldName, values);
  }

  @override
  CarRepositoryQuery whereYear(String fieldName, int year) {
    return super.whereYear(fieldName, year);
  }

  @override
  CarRepositoryQuery selfJoin(String t1, String t2) {
    return super.selfJoin(t1, t2);
  }

  @override
  CarRepositoryQuery or(RepositoryQuery other) {
    return super.or(other);
  }

  @override
  CarRepositoryQuery not(RepositoryQuery other) {
    return super.not(other);
  }

  @override
  get() {
    return new Stream.fromFuture(connection.query(toSql()).then((rows) {}));
  }
}
