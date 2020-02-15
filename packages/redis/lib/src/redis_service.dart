import 'dart:async';
import 'dart:convert';
import 'package:angel_framework/angel_framework.dart';
import 'package:resp_client/resp_client.dart';
import 'package:resp_client/resp_commands.dart';

/// An Angel service that reads and writes JSON within a Redis store.
class RedisService extends Service<String, Map<String, dynamic>> {
  final RespCommands respCommands;

  /// An optional string prefixed to keys before they are inserted into Redis.
  ///
  /// Consider using this if you are using several different Redis collections
  /// within a single application.
  final String prefix;

  RedisService(this.respCommands, {this.prefix});

  String _applyPrefix(String id) => prefix == null ? id : '$prefix:$id';

  @override
  Future<List<Map<String, dynamic>>> index(
      [Map<String, dynamic> params]) async {
    var result =
        await respCommands.client.writeArrayOfBulk(['KEYS', _applyPrefix('*')]);
    var keys = result.payload.map((RespType s) => s.payload) as Iterable;
    if (keys.isEmpty) return [];
    result = await respCommands.client.writeArrayOfBulk(['MGET']..addAll(keys));
    return result.payload
        .map<Map<String, dynamic>>(
            (RespType s) => json.decode(s.payload) as Map<String, dynamic>)
        .toList();
  }

  @override
  Future<Map<String, dynamic>> read(String id,
      [Map<String, dynamic> params]) async {
    var value = await respCommands.get(_applyPrefix(id));

    if (value == null) {
      throw new AngelHttpException.notFound(
          message: 'No record found for ID $id');
    } else {
      return json.decode(value);
    }
  }

  @override
  Future<Map<String, dynamic>> create(Map<String, dynamic> data,
      [Map<String, dynamic> params]) async {
    String id;
    if (data['id'] != null)
      id = data['id'] as String;
    else {
      var keyVar = await respCommands.client
          .writeArrayOfBulk(['INCR', _applyPrefix('angel_redis:id')]);
      id = keyVar.payload.toString();
      data = new Map<String, dynamic>.from(data)..['id'] = id;
    }

    await respCommands.set(_applyPrefix(id), json.encode(data));
    return data;
  }

  @override
  Future<Map<String, dynamic>> modify(String id, Map<String, dynamic> data,
      [Map<String, dynamic> params]) async {
    var input = await read(id);
    input.addAll(data);
    return await update(id, input, params);
  }

  @override
  Future<Map<String, dynamic>> update(String id, Map<String, dynamic> data,
      [Map<String, dynamic> params]) async {
    data = new Map<String, dynamic>.from(data)..['id'] = id;
    await respCommands.set(_applyPrefix(id), json.encode(data));
    return data;
  }

  @override
  Future<Map<String, dynamic>> remove(String id,
      [Map<String, dynamic> params]) async {
    var client = respCommands.client;
    await client.writeArrayOfBulk(['MULTI']);
    await client.writeArrayOfBulk(['GET', _applyPrefix(id)]);
    await client.writeArrayOfBulk(['DEL', _applyPrefix(id)]);
    var result = await client.writeArrayOfBulk(['EXEC']);
    var str = result.payload[0] as RespBulkString;

    if (str.payload == null)
      throw new AngelHttpException.notFound(
          message: 'No record found for ID $id');
    else
      return json.decode(str.payload);
  }
}
