import 'package:test/test.dart';
import 'models/has_car.dart';
import 'common.dart';

main() {
  PostgresExecutor executor;

  setUp(() async {
    executor = await connectToPostgres(['has_car']);
  });

  test('insert', () async {
    var query = HasCarQuery()..values.type = CarType.sedan;
    var result = await query.insert(executor);
    expect(result.type, CarType.sedan);
  });

  group('query', () {
    HasCar initialValue;

    setUp(() async {
      var query = HasCarQuery();
      query.values.type = CarType.sedan;
      initialValue = await query.insert(executor);
    });

    test('query by enum', () async {
      // Check for mismatched type
      var query = HasCarQuery()..where.type.equals(CarType.atv);
      expect(await query.get(executor), isEmpty);

      query = HasCarQuery()..where.type.equals(initialValue.type);
      expect(await query.getOne(executor), initialValue);
    });
  });
}
