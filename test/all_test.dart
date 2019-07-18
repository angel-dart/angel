import 'dart:collection';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_http_exception/angel_http_exception.dart';
import 'package:angel_sembast/angel_sembast.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:test/test.dart';

main() async {
  Database database;
  SembastService service;

  setUp(() async {
    database = await memoryDatabaseFactory.openDatabase('test.db');
    service = SembastService(database);
  });

  tearDown(() => database.close());

  test('index', () async {
    await service.create({'id': '0', 'name': 'Tobe'});
    await service.create({'id': '1', 'name': 'Osakwe'});

    var output = await service.index();
    print(output);
    expect(output, hasLength(2));
    expect(output[0], <String, dynamic>{'id': '1', 'name': 'Tobe'});
    expect(output[1], <String, dynamic>{'id': '2', 'name': 'Osakwe'});
  });

  test('create', () async {
    var input = {'bar': 'baz'};
    var output = await service.create(input);
    print(output);
    expect(output.keys, contains('id'));
    expect(output, containsPair('bar', 'baz'));
  });

  test('read', () async {
    var name = 'poobah${DateTime.now().millisecondsSinceEpoch}';
    var input = await service.create({'name': name, 'bar': 'baz'});
    print(input);
    expect(await service.read(input['id'] as String), input);
  });

  test('modify', () async {
    var input = await service.create({'bar': 'baz', 'yes': 'no'});
    var id = input['id'] as String;
    var output = await service.modify(id, {'bar': 'quux'});
    expect(SplayTreeMap.from(output),
        SplayTreeMap.from({'id': id, 'bar': 'quux', 'yes': 'no'}));
    expect(await service.read(id), output);
  });

  test('update', () async {
    var input = await service.create({'bar': 'baz'});
    var id = input['id'] as String;
    var output = await service.update(id, {'yes': 'no'});
    expect(output, {'id': id, 'yes': 'no'});
    expect(await service.read(id), output);
  });

  test('remove', () async {
    var input = await service.create({'bar': 'baz'});
    var id = input['id'] as String;
    expect(await service.remove(id), input);
    expect(await StoreRef.main().record(id).get(database), isNull);
  });

  test('remove', () async {
    await service.create({'bar': 'baz'});
    await service.create({'bar': 'baz'});
    await service.create({'bar': 'baz'});

    expect(await service.index(), isNotEmpty);
    await service.remove(null);
    expect(await service.index(), isEmpty);
  });

  test('cannot remove all unless explicitly set', () async {
    expect(() => service.remove(null, {'provider': Providers.rest}),
        throwsA(const TypeMatcher<AngelHttpException>()));
    expect(
        () => service.remove(null, {'provider': Providers.rest}),
        throwsA(predicate((x) => x is AngelHttpException && x.statusCode == 403,
            'throws forbidden')));
    expect(() => service.remove('null', {'provider': Providers.rest}),
        throwsA(const TypeMatcher<AngelHttpException>()));
    expect(
        () => service.remove('null', {'provider': Providers.rest}),
        throwsA(predicate((x) => x is AngelHttpException && x.statusCode == 403,
            'throws forbidden')));
  });

  test('can remove all on server side', () async {
    await service.create({'bar': 'baz'});
    await service.create({'bar': 'baz'});
    await service.create({'bar': 'baz'});
    await service.remove(null);
    expect(await service.index(), isEmpty);

    await service.create({'bar': 'baz'});
    await service.create({'bar': 'baz'});
    await service.create({'bar': 'baz'});
    await service.remove('null');
    expect(await service.index(), isEmpty);
  });

  test('remove nonexistent', () async {
    expect(() => service.remove('440'),
        throwsA(const TypeMatcher<AngelHttpException>()));
  });
}
