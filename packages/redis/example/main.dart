import 'package:angel_redis/angel_redis.dart';
import 'package:resp_client/resp_client.dart';
import 'package:resp_client/resp_commands.dart';

main() async {
  var connection = await connectSocket('localhost');
  var client = new RespClient(connection);
  var service = new RedisService(new RespCommands(client), prefix: 'example');

  // Create an object
  await service.create({'id': 'a', 'hello': 'world'});

  // Read it...
  var read = await service.read('a');
  print(read['hello']);

  // Delete it.
  await service.remove('a');

  // Close the connection.
  await connection.close();
}
