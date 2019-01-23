import 'package:test/test.dart';
import 'models/has_map.dart';
import 'common.dart';

main() {
  PostgresExecutor executor;

  setUp(() async {
    executor = await connectToPostgres(['has_map']);
  });

  test('insert', () async {
    var query = HasMapQuery()..values.value = {'foo': 'bar'};
    var model = await query.insert(executor);
    print(model.toJson());
    expect(model, HasMap(value: {'foo': 'bar'}));
  });

  test('insert', () async {
    var query = HasMapQuery()..values.value = {'foo': 'bar'};
    var model = await query.insert(executor);
    print(model.toJson());

    query = HasMapQuery()..values.copyFrom(model);
    expect(await query.updateOne(executor), model);
  });

  group('query', () {
    HasMap initialValue;

    setUp(() async {
      var query = HasMapQuery()..values.value = {'foo': 'bar'};
      initialValue = await query.insert(executor);
    });

    test('get all', () async {
      var query = HasMapQuery();
      expect(await query.get(executor), [initialValue]);
    });

    test('map equals', () async {
      var query = HasMapQuery();
      query.where.value.equals({'foo': 'bar'});
      expect(await query.get(executor), [initialValue]);
    });

    test('property equals', () async {
      var query = HasMapQuery();
      query.where.value['foo'].asString((b) => b.equals('bar'));
      expect(await query.get(executor), [initialValue]);

      query = HasMapQuery();
      query.where.value['foo'].asString((b) => b.equals('baz'));
      expect(await query.get(executor), []);
    });
  });
}
