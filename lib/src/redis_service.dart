import 'dart:async';
import 'dart:convert';
import 'package:angel_framework/angel_framework.dart';
import 'package:resp_client/resp_commands.dart';

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
    throw await client.writeArrayOfBulk(['MULTI']);
  }
}
