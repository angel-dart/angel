library angel_client.rest;

import 'dart:async';
import 'dart:convert' show JSON;
import 'package:http/http.dart';
import '../angel_client.dart';

_buildQuery(Map params) {
  if (params == null || params == {})
    return "";

  String result = "";
  return result;
}

const Map _readHeaders = const {
  "Accept": "application/json"
};

const Map _writeHeaders = const {
  "Accept": "application/json",
  "Content-Type": "application/json"
};

/// Queries an Angel service via REST.
class RestService extends Service {
  String basePath;
  BaseClient client;

  RestService(Pattern path, BaseClient this.client) {
    this.basePath = (path is RegExp) ? path.pattern : path;
  }

  @override
  Future<List> index([Map params]) async {
    var response = await client.get(
        "$basePath/${_buildQuery(params)}", headers: _readHeaders);
    return JSON.decode(response.body);
  }

  @override
  Future read(id, [Map params]) async {
    var response = await client.get(
        "$basePath/$id${_buildQuery(params)}", headers: _readHeaders);
    return JSON.decode(response.body);
  }

  @override
  Future create(data, [Map params]) async {
    var response = await client.post(
        "$basePath/${_buildQuery(params)}", body: JSON.encode(data),
        headers: _writeHeaders);
    return JSON.decode(response.body);
  }

  @override
  Future modify(id, data, [Map params]) async {
    var response = await client.patch(
        "$basePath/$id${_buildQuery(params)}", body: JSON.encode(data),
        headers: _writeHeaders);
    return JSON.decode(response.body);
  }

  @override
  Future update(id, data, [Map params]) async {
    var response = await client.patch(
        "$basePath/$id${_buildQuery(params)}", body: JSON.encode(data),
        headers: _writeHeaders);
    return JSON.decode(response.body);
  }

  @override
  Future remove(id, [Map params]) async {
    var response = await client.delete(
        "$basePath/$id${_buildQuery(params)}", headers: _readHeaders);
    return JSON.decode(response.body);
  }


}
