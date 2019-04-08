import 'dart:async';
import 'package:angel_orm/angel_orm.dart';
import 'package:test/test.dart';
import 'models/has_map.dart';

hasMapTests(FutureOr<QueryExecutor> Function() createExecutor,
    {FutureOr<void> Function(QueryExecutor) close}) {
  QueryExecutor executor;
  close ??= (_) => null;

  setUp(() async {
    executor = await createExecutor();
  });

  tearDown(() => close(executor));

  test('insert', () async {
    var query = HasMapQuery();
    query.values
      ..value = {'foo': 'bar'}
      ..list = ['1', 2, 3.0];
    var model = await query.insert(executor);
    print(model.toJson());
    expect(model, HasMap(value: {'foo': 'bar'}, list: ['1', 2, 3.0]));
  });

  test('update', () async {
    var query = HasMapQuery();
    query.values
      ..value = {'foo': 'bar'}
      ..list = ['1', 2, 3.0];
    var model = await query.insert(executor);
    print(model.toJson());

    query = HasMapQuery()..values.copyFrom(model);
    expect(await query.updateOne(executor), model);
  });

  group('query', () {
    HasMap initialValue;

    setUp(() async {
      var query = HasMapQuery();
      query.values
        ..value = {'foo': 'bar'}
        ..list = ['1', 2, 3.0];
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

      query = HasMapQuery();
      query.where.value.equals({'foo': 'baz'});
      expect(await query.get(executor), isEmpty);
    });

    test('list equals', () async {
      var query = HasMapQuery();
      query.where.list.equals(['1', 2, 3.0]);
      expect(await query.get(executor), [initialValue]);

      query = HasMapQuery();
      query.where.list.equals(['10', 20, 30.0]);
      expect(await query.get(executor), isEmpty);
    });

    test('property equals', () async {
      var query = HasMapQuery()..where.value['foo'].asString.equals('bar');
      expect(await query.get(executor), [initialValue]);

      query = HasMapQuery()..where.value['foo'].asString.equals('baz');
      expect(await query.get(executor), []);
    });

    test('index equals', () async {
      var query = HasMapQuery()..where.list[0].asString.equals('1');
      expect(await query.get(executor), [initialValue]);

      query = HasMapQuery()..where.list[1].asInt.equals(3);
      expect(await query.get(executor), []);
    });
  });
}
