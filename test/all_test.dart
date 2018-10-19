import 'package:angel_file_service/angel_file_service.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:test/test.dart';

main() {
  MemoryFileSystem fs;
  File dbFile;
  JsonFileService service;

  setUp(() async {
    fs = new MemoryFileSystem();
    dbFile = fs.file('db.json');
    service = new JsonFileService(dbFile);

    await dbFile.writeAsString('''
    [
      {"id": "0", "foo": "bar"},
      {"id": "1", "foo": "baz"},
      {"id": "2", "foo": "quux"}
    ]
    ''');
  });

  tearDown(() => service.close());

  test('index no params', () async {
    expect(await service.index(), [
      {"id": "0", "foo": "bar"},
      {"id": "1", "foo": "baz"},
      {"id": "2", "foo": "quux"}
    ]);
  });

  test('index with query', () async {
    expect(
      await service.index({
        'query': {'foo': 'bar'}
      }),
      [
        {"id": "0", "foo": "bar"}
      ],
    );
  });

  test('read', () async {
    expect(
      await service.read('2'),
      {"id": "2", "foo": "quux"},
    );
  });

  test('modify', () async {
    await service.modify('2', {'baz': 'quux'});
    expect(await service.read('2'), containsPair('baz', 'quux'));
  });

  test('update', () async {
    await service.update('2', {'baz': 'quux'});
    expect(await service.read('2'), containsPair('baz', 'quux'));
    expect(await service.read('2'), isNot(containsPair('foo', 'quux')));
  });

  test('delete', () async {
    await service.remove('2');
    expect(await service.index(), [
      {"id": "0", "foo": "bar"},
      {"id": "1", "foo": "baz"}
    ]);
  });
}
