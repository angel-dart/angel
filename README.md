# redis
[![Pub](https://img.shields.io/pub/v/angel_redis.svg)](https://pub.dartlang.org/packages/angel_redis)
[![build status](https://travis-ci.org/angel-dart/redis.svg)](https://travis-ci.org/angel-dart/redis)

Redis-enabled services for the Angel framework.
`RedisService` can be used alone, *or* as the backend of a
[`CacheService`](https://github.com/angel-dart/cache),
and thereby cache the results of calling an upstream database.

## Installation
`package:angel_redis` requires Angel 2.

In your `pubspec.yaml`:

```yaml
dependencies:
    angel_framework: ^2.0.0-alpha
    angel_redis: ^1.0.0
```

## Usage
Pass an instance of `RespCommands` (from `package:resp_client`) to the `RedisService` constructor.
You can also pass an optional prefix, which is recommended if you are using `angel_redis` for multiple
logically-separate collections. Redis is a flat key-value store; by prefixing the keys used,
`angel_redis` can provide the experience of using separate stores, rather than a single node.

Without a prefix, there's a chance that different collections can overwrite one another's data.

## Notes
* Neither `index`, nor `modify` is atomic; each performs two separate queries.`angel_redis` stores data as JSON strings, rather than as Redis hashes, so an update-in-place is impossible.
* `index` uses Redis' `KEYS` functionality, so use it sparingly in production, if at all. In a larger database, it can quickly
become a bottleneck.
* `remove` uses `MULTI`+`EXEC` in a transaction.
* Prefer using `update`, rather than `modify`. The former only performs one query, though it does overwrite the current
contents for a given key.
* When calling `create`, it's possible that you may already have an `id` in mind to insert into the store. For example,
when caching another database, you'll preserve the ID or primary key of an item. `angel_redis` heeds this. If no
`id` is present, then an ID will be created via an `INCR` call.

## Example
Also present at `example/main.dart`:

```dart
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
```