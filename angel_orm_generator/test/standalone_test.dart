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
      ..familyFriendly.equals(true)
      ..recalledAt.lessThanOrEqualTo(y2k, includeTime: false);
    var whereClause = query.where.compile(tableName: 'cars');
    print('Where clause: $whereClause');
    expect(whereClause,
        'WHERE cars.family_friendly = TRUE AND cars.recalled_at <= \'2000-01-01\'');
  });

  test('parseRow', () {
    var row = [
      0,
      'Mazda',
      'CX9',
      true,
      dateYmdHms.format(y2k),
      dateYmdHms.format(y2k),
      dateYmdHms.format(y2k)
    ];
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
          ferrari = await CarQuery.insert(connection,
              make: 'Ferrari',
              description: 'Vroom vroom!',
              familyFriendly: false);
        });

        tearDown(() => connection.close());

        test('where clause is applied', () async {
          var query = new CarQuery()..where.familyFriendly.equals(true);
          var cars = await query.get(connection);
          expect(cars, isEmpty);

          var sportsCars = new CarQuery()..where.familyFriendly.notEquals(true);
          cars = await sportsCars.get(connection);
          print(cars.map((c) => c.toJson()));

          var car = cars.first;
          expect(car.make, ferrari.make);
          expect(car.description, ferrari.description);
          expect(car.familyFriendly, ferrari.familyFriendly);
          expect(car.recalledAt, isNull);
        });

        test('union', () async {
          var query1 = new CarQuery()..where.make.like('%Fer%');
          var query2 = new CarQuery()..where.familyFriendly.equals(true);
          var query3 = new CarQuery()..where.description.equals('Submarine');
          query1
            ..union(query2)
            ..unionAll(query3);
          print(query1.compile());

          var cars = await query1.get(connection);
          expect(cars, hasLength(1));
        });

        test('or clause', () async {
          var query = new CarQuery()
            ..where.make.like('Fer%')
            ..orWhere((where) =>
                where..familyFriendly.equals(true)..make.equals('Honda'));
          print(query.compile());
          var cars = await query.get(connection);
          expect(cars, hasLength(1));
        });

        test('limit obeyed', () async {
          var query = new CarQuery()..limit(0);
          print(query.compile());
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
            ..where.make.equals('Ferrari')
            ..orWhere((w) => w.familyFriendly.equals(true));

          print(query.compile(preamble: 'DELETE FROM "cars"'));
          var cars = await query.get(connection);
          expect(cars, hasLength(1));
          expect(cars.first.toJson(), ferrari.toJson());
        });

        test('update', () async {
          var query = new CarQuery()..where.id.equals(int.parse(ferrari.id));
          var cars = await query.update(connection, make: 'Hyundai');
          expect(cars, hasLength(1));
          expect(cars.first.make, 'Hyundai');
        });

        test('update car', () async {
          var cloned = ferrari.copyWith(make: 'Angel');
          var car = await CarQuery.updateCar(connection, cloned);
          print(car.toJson());
          expect(car.toJson(), cloned.toJson());
        });
      });
    });

    test('insert', () async {
      var recalledAt = new DateTime.now();
      var car = await CarQuery.insert(connection,
          make: 'Honda',
          description: 'Hello',
          familyFriendly: true,
          recalledAt: recalledAt);
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
      var car = await CarQuery.insertCar(connection, beetle);
      print(car.toJson());
      expect(car.make, beetle.make);
      expect(car.description, beetle.description);
      expect(car.familyFriendly, beetle.familyFriendly);
      expect(dateYmdHms.format(car.recalledAt),
          dateYmdHms.format(beetle.recalledAt));
    });
  });
}
