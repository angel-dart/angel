import 'dart:io';
import 'package:angel_orm/angel_orm.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';
import 'models/car.dart';
import 'models/car.orm.g.dart';

final DateTime MILENNIUM = new DateTime.utc(2000, 1, 1);

main() {
  PostgreSQLConnection connection;

  setUp(() async {
    connection = new PostgreSQLConnection('127.0.0.1', 0, '');
    await connection.open();

    // Create temp table
    var query = await new File('test/models/car.sql').readAsString();
    await connection.execute(query);
  });

  tearDown(() async {
    // Drop `cars`
    await connection.execute('DROP TABLE `cars`;');
    await connection.close();
  });

  test('to where', () {
    var query = new CarQuery();
    query.where
      ..familyFriendly.equals(true)
      ..recalledAt.lessThanOrEqualTo(MILENNIUM, includeTime: false);
    var whereClause = query.where.toWhereClause();
    print('Where clause: $whereClause');
    expect(whereClause,
        "WHERE `family_friendly` = 1 AND `recalled_at` <= '00-01-01'");
  });

  test('parseRow', () {
    var row = [
      0,
      'Mazda',
      'CX9',
      1,
      DATE_YMD_HMS.format(MILENNIUM),
      DATE_YMD_HMS.format(MILENNIUM),
      DATE_YMD_HMS.format(MILENNIUM)
    ];
    print(row);
    var car = CarQuery.parseRow(row);
    print(car.toJson());
    expect(car.id, '0');
    expect(car.make, 'Mazda');
    expect(car.description, 'CX9');
    expect(car.familyFriendly, true);
    expect(MILENNIUM.toIso8601String(),
        startsWith(car.recalledAt.toIso8601String()));
    expect(MILENNIUM.toIso8601String(),
        startsWith(car.createdAt.toIso8601String()));
    expect(MILENNIUM.toIso8601String(),
        startsWith(car.updatedAt.toIso8601String()));
  });

  test('insert', () async {});
}
