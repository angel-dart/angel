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

  test('update', () async {
    var id = 'hoopla${new DateTime.now().millisecondsSinceEpoch}';
    await service.create({'id': id, 'bar': 'baz'});
    var output = await service.update(id, {'bar': 'quux'});
    expect(output, {'id': id, 'bar': 'quux'});
    expect(await service.read(id), output);
  });

  test('remove', () async {
    var id = 'gelatin${new DateTime.now().millisecondsSinceEpoch}';
    var input = await service.create({'id': id, 'bar': 'baz'});
    expect(await service.remove(id), input);
  });
}
