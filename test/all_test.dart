import 'package:angel_http_exception/angel_http_exception.dart';
import 'package:angel_redis/angel_redis.dart';
import 'package:resp_client/resp_client.dart';
import 'package:resp_client/resp_commands.dart';
import 'package:test/test.dart';

main() async {
  RespServerConnection connection;
  RedisService service;

  setUp(() async {
    connection = await connectSocket('localhost');
    service = new RedisService(new RespCommands(new RespClient(connection)),
        prefix: 'angel_redis_test');
  });

  tearDown(() => connection.close());

  test('index', () async {
    // Wipe
    await service.respCommands.flushDb();
    await service.create({'id': '0', 'name': 'Tobe'});
    await service.create({'id': '1', 'name': 'Osakwe'});

    var output = await service.index();
    expect(output, hasLength(2));
    expect(output[1], <String, dynamic>{'id': '0', 'name': 'Tobe'});
    expect(output[0], <String, dynamic>{'id': '1', 'name': 'Osakwe'});
  });

  test('create with id', () async {
    var input = {'id': 'foo', 'bar': 'baz'};
    var output = await service.create(input);
    expect(input, output);
  });

  test('create without id', () async {
    var input = {'bar': 'baz'};
    var output = await service.create(input);
    print(output);
    expect(output.keys, contains('id'));
    expect(output, containsPair('bar', 'baz'));
  });

  test('read', () async {
    var id = 'poobah${new DateTime.now().millisecondsSinceEpoch}';
    var input = await service.create({'id': id, 'bar': 'baz'});
    expect(await service.read(id), input);
  });

  test('modify', () async {
    var id = 'jamboree${new DateTime.now().millisecondsSinceEpoch}';
    await service.create({'id': id, 'bar': 'baz', 'yes': 'no'});
    var output = await service.modify(id, {'bar': 'quux'});
    expect(output, {'id': id, 'bar': 'quux', 'yes': 'no'});
    expect(await service.read(id), output);
  });

  test('update', () async {
    var id = 'hoopla${new DateTime.now().millisecondsSinceEpoch}';
    await service.create({'id': id, 'bar': 'baz'});
    var output = await service.update(id, {'yes': 'no'});
    expect(output, {'id': id, 'yes': 'no'});
    expect(await service.read(id), output);
  });

  test('remove', () async {
    var id = 'gelatin${new DateTime.now().millisecondsSinceEpoch}';
    var input = await service.create({'id': id, 'bar': 'baz'});
    expect(await service.remove(id), input);
    expect(await service.respCommands.exists([id]), 0);
  });

  test('remove nonexistent', () async {
    expect(() => service.remove('definitely_does_not_exist'),
        throwsA(const TypeMatcher<AngelHttpException>()));
  });
}
