/// Browser library for the Angel framework.
library angel_client.browser;

import 'dart:async';
import 'dart:convert' show JSON;
import 'dart:html';
import 'angel_client.dart';
export 'angel_client.dart';

_buildQuery(Map params) {
  if (params == null || params == {})
    return "";

  String result = "";
  return result;
}

/// Queries an Angel server via REST.
class Rest extends Angel {
  Rest(String basePath) :super(basePath);

  @override
  RestService service(String path, {Type type}) {
    String uri = path.replaceAll(new RegExp(r"(^\/)|(\/+$)"), "");
    return new RestService("$basePath/$uri")
      ..app = this;
  }
}

/// Queries an Angel service via REST.
class RestService extends Service {
  String basePath;

  RestService(Pattern path) {
    this.basePath = (path is RegExp) ? path.pattern : path;
  }

  _makeBody(data) {
    return JSON.encode(data);
  }

  HttpRequest buildRequest(String url,
      {String method: "POST", bool write: true}) {
    HttpRequest request = new HttpRequest();
    request.open(method, url, async: false);
    request.responseType = "json";
    request.setRequestHeader("Accept", "application/json");
    if (write)
      request.setRequestHeader("Content-Type", "application/json");
    return request;
  }

  @override
  Future<List> index([Map params]) async {
    return JSON.decode(
        await HttpRequest.getString("$basePath/${_buildQuery(params)}"));
  }

  @override
  Future read(id, [Map params]) async {
    return JSON.decode(
        await HttpRequest.getString("$basePath/$id${_buildQuery(params)}"));
  }

  @override
  Future create(data, [Map params]) async {
    var request = buildRequest("$basePath/${_buildQuery(params)}");
    request.send(_makeBody(data));
    return request.response;
  }

  @override
  Future modify(id, data, [Map params]) async {
    var request = buildRequest("$basePath/$id${_buildQuery(params)}", method: "PATCH");
    request.send(_makeBody(data));
    return request.response;
  }

  @override
  Future update(id, data, [Map params]) async {
    var request = buildRequest("$basePath/$id${_buildQuery(params)}");
    request.send(_makeBody(data));
    return request.response;
  }

  @override
  Future remove(id, [Map params]) async {
    var request = buildRequest("$basePath/$id${_buildQuery(params)}", method: "DELETE");
    request.send();
    return request.response;
  }
}
