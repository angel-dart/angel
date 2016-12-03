/// Browser library for the Angel framework.
library angel_client.browser;

import 'dart:async' show Completer, Future;
import 'dart:convert' show JSON;
import 'dart:html' show HttpRequest, window;
import 'angel_client.dart';
import 'auth_types.dart' as auth_types;
export 'angel_client.dart';

_buildQuery(Map params) {
  if (params == null || params == {}) return "";

  String result = "";
  return result;
}

_send(HttpRequest request, [data]) {
  final completer = new Completer<HttpRequest>();

  request
    ..onLoadEnd.listen((_) {
      completer.complete(request.response);
    })
    ..onError.listen((_) {
      try {
        throw new Exception(
            'Request failed with status code ${request.status}.');
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });

  if (data == null)
    request.send();
  else if (data is String)
    request.send(data);
  else
    request.send(JSON.encode(data));
  return completer.future;
}

/// Queries an Angel server via REST.
class Rest extends Angel {
  String _authToken;

  Rest(String basePath) : super(basePath);

  @override
  Future authenticate(
      {String type,
      credentials,
      String authEndpoint: '/auth',
      String reviveEndpoint: '/auth/token'}) async {
    if (type == null) {
      if (!window.localStorage.containsKey('token')) {
        throw new Exception(
            'Cannot revive token from localStorage - there is none.');
      }

      final result = new _AngelAuthResultImpl(
          token: JSON.decode(window.localStorage['token']),
          data: JSON.decode(window.localStorage['user']));
      final completer = new Completer();
      final request = new HttpRequest()..responseType = 'json';
      request.open('POST', '$basePath$reviveEndpoint');
      request.setRequestHeader('Accept', 'application/json');
      request.setRequestHeader('Content-Type', 'application/json');
      request.setRequestHeader('Authorization', 'Bearer ${result.token}');

      request
        ..onLoadEnd.listen((_) {
          final result = new _AngelAuthResultImpl.fromMap(request.response);
          _authToken = result.token;
          window.localStorage['token'] = JSON.encode(result.token);
          window.localStorage['user'] = JSON.encode(result.data);
          completer.complete(result);
        })
        ..onError.listen((_) {
          try {
            throw new Exception(
                'Request failed with status code ${request.status}.');
          } catch (e, st) {
            completer.completeError(e, st);
          }
        });

      request.send(JSON.encode(result));
      return completer.future;
    }

    final url = '$basePath$authEndpoint/$type';

    if (type == auth_types.LOCAL) {
      final completer = new Completer();
      final request = new HttpRequest();
      request.open('POST', url);
      request.responseType = 'json';
      request.setRequestHeader("Accept", "application/json");
      request.setRequestHeader("Content-Type", "application/json");

      request
        ..onLoadEnd.listen((_) {
          final result = new _AngelAuthResultImpl.fromMap(request.response);
          _authToken = result.token;
          window.localStorage['token'] = JSON.encode(result.token);
          window.localStorage['user'] = JSON.encode(result.data);
          completer.complete(result);
        })
        ..onError.listen((_) {
          try {
            throw new Exception(
                'Request failed with status code ${request.status}.');
          } catch (e, st) {
            completer.completeError(e, st);
          }
        });

      if (credentials == null)
        request.send();
      else
        request.send(JSON.encode(credentials));

      return completer.future;
    } else {
      throw new Exception('angel_client cannot authenticate as "$type" yet.');
    }
  }

  @override
  RestService service(String path, {Type type}) {
    String uri = path.replaceAll(new RegExp(r"(^\/)|(\/+$)"), "");
    return new _RestServiceImpl(this, "$basePath/$uri");
  }
}

abstract class RestService extends Service {
  RestService._(String basePath);
}

class _AngelAuthResultImpl implements AngelAuthResult {
  String _token;
  final Map<String, dynamic> data = {};
  String get token => _token;

  _AngelAuthResultImpl({token, Map<String, dynamic> data: const {}}) {
    if (token is String) _token = token;

    this.data.addAll(data ?? {});
  }

  factory _AngelAuthResultImpl.fromMap(Map data) {
    final result = new _AngelAuthResultImpl();

    if (data is Map && data.containsKey('token') && data['token'] is String)
      result._token = data['token'];

    if (data is Map) result.data.addAll(data['data'] ?? {});

    return result;
  }

  @override
  Map<String, dynamic> toJson() {
    return {'token': token, 'data': data};
  }
}

/// Queries an Angel service via REST.
class _RestServiceImpl extends RestService {
  final Rest app;
  String _basePath;
  String get basePath => _basePath;

  _RestServiceImpl(this.app, String basePath) : super._(basePath) {
    _basePath = basePath;
  }

  _makeBody(data) {
    return JSON.encode(data);
  }

  Future<HttpRequest> buildRequest(String url,
      {String method: "POST", bool write: true}) async {
    HttpRequest request = new HttpRequest();
    request.open(method, url);
    request.responseType = "json";
    request.setRequestHeader("Accept", "application/json");
    if (write) request.setRequestHeader("Content-Type", "application/json");
    if (app._authToken != null)
      request.setRequestHeader("Authorization", "Bearer ${app._authToken}");
    return request;
  }

  @override
  Future<List> index([Map params]) async {
    final request = await buildRequest('$basePath/${_buildQuery(params)}',
        method: 'GET', write: false);
    return await _send(request);
  }

  @override
  Future read(id, [Map params]) async {
    final request = await buildRequest('$basePath/$id${_buildQuery(params)}',
        method: 'GET', write: false);
    return await _send(request);
  }

  @override
  Future create(data, [Map params]) async {
    final request = await buildRequest("$basePath/${_buildQuery(params)}");
    return await _send(request, _makeBody(data));
  }

  @override
  Future modify(id, data, [Map params]) async {
    final request = await buildRequest("$basePath/$id${_buildQuery(params)}",
        method: "PATCH");
    return await _send(request, _makeBody(data));
  }

  @override
  Future update(id, data, [Map params]) async {
    final request = await buildRequest("$basePath/$id${_buildQuery(params)}");
    return await _send(request, _makeBody(data));
  }

  @override
  Future remove(id, [Map params]) async {
    final request = await buildRequest("$basePath/$id${_buildQuery(params)}",
        method: "DELETE");
    return await _send(request);
  }
}
