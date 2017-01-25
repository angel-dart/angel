/// Command-line client library for the Angel framework.
library angel_client.cli;

import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:json_god/json_god.dart' as god;
import 'angel_client.dart';
import 'base_angel_client.dart';
export 'angel_client.dart';

/// Queries an Angel server via REST.
class Rest extends BaseAngelClient {
  Rest(String path) : super(new http.Client(), path);

  @override
  Service service<T>(String path, {Type type, AngelDeserializer deserializer}) {
    String uri = path.replaceAll(straySlashes, "");
    return new RestService(
        client, this, "$basePath/$uri", T != dynamic ? T : type);
  }
}

/// Queries an Angel service via REST.
class RestService extends BaseAngelService {
  final Type type;

  RestService(http.BaseClient client, Angel app, String url, this.type)
      : super(client, app, url);

  deserialize(x) {
    if (type != null) {
      return x.runtimeType == type
          ? x
          : god.deserializeDatum(x, outputType: type);
    }

    return x;
  }

  @override
  makeBody(x) {
    if (type != null) {
      return super.makeBody(god.serializeObject(x));
    }

    return super.makeBody(x);
  }

  @override
  Future<List> index([Map params]) async {
    final items = await super.index(params);
    return items.map(deserialize).toList();
  }

  @override
  Future read(id, [Map params]) => super.read(id, params).then(deserialize);

  @override
  Future create(data, [Map params]) =>
      super.create(data, params).then(deserialize);

  @override
  Future modify(id, data, [Map params]) =>
      super.modify(id, data, params).then(deserialize);

  @override
  Future update(id, data, [Map params]) =>
      super.update(id, data, params).then(deserialize);

  @override
  Future remove(id, [Map params]) => super.remove(id, params).then(deserialize);
}
