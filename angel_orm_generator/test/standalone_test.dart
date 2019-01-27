/// Test for queries without relationships.
library angel_orm_generator.test.car_test;

import 'package:angel_orm/angel_orm.dart';
import 'package:test/test.dart';
import 'models/car.dart';
import 'common.dart';

final DateTime y2k = new DateTime.utc(2000, 1, 1);

main() {
  test('to where', () {
    var query = new CarQuery();
    query.where
      ..familyFriendly.isTrue
      ..recalledAt.lessThanOrEqualTo(y2k, includeTime: false);
    var whereClause = query.where.compile(tableName: 'cars');
    print('Where clause: $whereClause');
    expect(whereClause,
        'cars.family_friendly = TRUE AND cars.recalled_at <= \'2000-01-01\'');
  });

  test('parseRow', () {
    var row = [0, 'Mazda', 'CX9', true, y2k, y2k, y2k];
    print(row);
    var car = new CarQuery().deserialize(row);
    print(car.toJson());
    expect(car.id, '0');
    expect(car.make, 'Mazda');
    expect(car.description, 'CX9');
    expect(car.familyFriendly, true);
    expect(y2k.toIso8601String(), startsWith(car.recalledAt.toIso8601String()));
    expect(y2k.toIso8601String(), startsWith(car.createdAt.toIso8601String()));
    expect(y2k.toIso8601String(), startsWith(car.updatedAt.toIso8601String()));
  });

  group('queries', () {
    PostgresExecutor connection;

    setUp(() async {
      connection = await connectToPostgres(['car']);
    });

    group('selects', () {
      test('select all', () async {
        var cars = await new CarQuery().get(connection);
        expect(cars, []);
      });

      group('with data', () {
        Car ferrari;

        setUp(() async {
          var query = new CarQuery();
          query.values
            ..make = 'Ferrari東'
            ..description = 'Vroom vroom!'
            ..familyFriendly = false;
          ferrari = await query.insert(connection);
        });

        tearDown(() => connection.close());

        test('where clause is applied', () async {
          var query = new CarQuery()..where.familyFriendly.isTrue;
          var cars = await query.get(connection);
          expect(cars, isEmpty);

          var sportsCars = new CarQuery()..where.familyFriendly.isFalse;
          cars = await sportsCars.get(connection);
          print(cars.map((c) => c.toJson()));

          var car = cars.first;
          expect(car.make, ferrari.make);
          expect(car.description, ferrari.description);
          expect(car.familyFriendly, ferrari.familyFriendly);
          expect(car.recalledAt, isNull);
        });

        test('union', () async {
          var query1 = new CarQuery()..where.make.like((_) => '%Fer%');
          var query2 = new CarQuery()..where.familyFriendly.isTrue;
          var query3 = new CarQuery()..where.description.equals('Submarine');
          var union = query1.union(query2).unionAll(query3);
          print(union.compile(Set()));
          var cars = await union.get(connection);
          expect(cars, hasLength(1));
        });

        test('or clause', () async {
          var query = new CarQuery()
            ..where.make.like((_) => 'Fer%')
            ..orWhere((where) => where
              ..familyFriendly.isTrue
              ..make.equals('Honda'));
          print(query.compile(Set()));
          var cars = await query.get(connection);
          expect(cars, hasLength(1));
        });

        test('limit obeyed', () async {
          var query = new CarQuery()..limit(0);
          print(query.compile(Set()));
          var cars = await query.get(connection);
          expect(cars, isEmpty);
        });

        test('get one', () async {
          var id = int.parse(ferrari.id);
          var query = new CarQuery()..where.id.equals(id);
          var car = await query.getOne(connection);
          expect(car, ferrari);
        });

        test('delete one', () async {
          var id = int.parse(ferrari.id);
          var query = new CarQuery()..where.id.equals(id);
          var car = await query.deleteOne(connection);
          expect(car.toJson(), ferrari.toJson());

          var cars = await new CarQuery().get(connection);
          expect(cars, isEmpty);
        });

        test('delete stream', () async {
          var query = new CarQuery()
            ..where.make.equals('Ferrari東')
            ..orWhere((w) => w.familyFriendly.isTrue);
          print(query.compile(Set(), preamble: 'DELETE FROM "cars"'));

          var cars = await query.delete(connection);
          expect(cars, hasLength(1));
          expect(cars.first.toJson(), ferrari.toJson());
        });

        test('update', () async {
          var query = new CarQuery()
            ..where.id.equals(int.parse(ferrari.id))
            ..values.make = 'Hyundai';
          var cars = await query.update(connection);
          expect(cars, hasLength(1));
          expect(cars.first.make, 'Hyundai');
        });

        test('update car', () async {
          var cloned = ferrari.copyWith(make: 'Angel');
          var query = new CarQuery()..values.copyFrom(cloned);
          var car = await query.updateOne(connection);
          print(car.toJson());
          expect(car.toJson(), cloned.toJson());
        });
      });
    });

    test('insert', () async {
      var recalledAt = new DateTime.now();
      var query = new CarQuery();
      var now = new DateTime.now();
      query.values
        ..make = 'Honda'
        ..description = 'Hello'
        ..familyFriendly = true
        ..recalledAt = recalledAt
        ..createdAt = now
        ..updatedAt = now;
      var car = await query.insert(connection);
      expect(car.id, isNotNull);
      expect(car.make, 'Honda');
      expect(car.description, 'Hello');
      expect(car.familyFriendly, isTrue);
      expect(dateYmdHms.format(car.recalledAt), dateYmdHms.format(recalledAt));
      expect(car.createdAt, allOf(isNotNull, equals(car.updatedAt)));
    });

    test('insert car', () async {
      var recalledAt = new DateTime.now();
      var beetle = new Car(
          make: 'Beetle',
          description: 'Herbie',
          familyFriendly: true,
          recalledAt: recalledAt);
      var query = new CarQuery()..values.copyFrom(beetle);
      var car = await query.insert(connection);
      print(car.toJson());
      expect(car.make, beetle.make);
      expect(car.description, beetle.description);
      expect(car.familyFriendly, beetle.familyFriendly);
      expect(dateYmdHms.format(car.recalledAt),
          dateYmdHms.format(beetle.recalledAt));
    });
  });
}
