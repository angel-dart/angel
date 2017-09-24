import 'dart:async';
import 'dart:convert';
import 'package:angel_http_exception/angel_http_exception.dart';
import 'package:collection/collection.dart';
import 'package:http/src/base_client.dart' as http;
import 'package:http/src/base_request.dart' as http;
import 'package:http/src/request.dart' as http;
import 'package:http/src/response.dart' as http;
import 'package:http/src/streamed_response.dart' as http;
import 'angel_client.dart';

final RegExp straySlashes = new RegExp(r"(^/)|(/+$)");
const Map<String, String> _readHeaders = const {'Accept': 'application/json'};
const Map<String, String> _writeHeaders = const {
  'Accept': 'application/json',
  'Content-Type': 'application/json'
};

_buildQuery(Map params) {
  if (params == null || params.isEmpty || params['query'] is! Map) return "";

  List<String> query = [];

  params['query'].forEach((k, v) {
    query.add('$k=${Uri.encodeQueryComponent(v.toString())}');
  });

  return '?' + query.join('&');
}

bool _invalid(http.Response response) =>
    response.statusCode == null ||
    response.statusCode < 200 ||
    response.statusCode >= 300;

AngelHttpException failure(http.Response response, {error, StackTrace stack}) {
  try {
    final json = JSON.decode(response.body);

    if (json is Map && json['isError'] == true) {
      return new AngelHttpException.fromMap(json);
    } else {
      return new AngelHttpException(error,
          message: 'Unhandled exception while connecting to Angel backend.',
          statusCode: response.statusCode,
          stackTrace: stack);
    }
  } catch (e, st) {
    return new AngelHttpException(error ?? e,
        message: 'Unhandled exception while connecting to Angel backend.',
        statusCode: response.statusCode,
        stackTrace: stack ?? st);
  }
}

abstract class BaseAngelClient extends Angel {
  final StreamController<AngelAuthResult> _onAuthenticated =
      new StreamController<AngelAuthResult>();
  final List<Service> _services = [];
  final http.BaseClient client;

  @override
  Stream<AngelAuthResult> get onAuthenticated => _onAuthenticated.stream;

  BaseAngelClient(this.client, String basePath) : super(basePath);

  @override
  Future<AngelAuthResult> authenticate(
      {String type,
      credentials,
      String authEndpoint: '/auth',
      String reviveEndpoint: '/auth/token'}) async {
    if (type == null) {
      final url = '$basePath$reviveEndpoint';
      String token;

      if (credentials is String)
        token = credentials;
      else if (credentials is Map && credentials.containsKey('token'))
        token = credentials['token'];

      if (token == null) {
        throw new ArgumentError(
            'If `type` is not set, a JWT is expected as the `credentials` argument.');
      }

      final response = await client.post(url, headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      });

      if (_invalid(response)) {
        throw failure(response);
      }

      try {
        final json = JSON.decode(response.body);

        if (json is! Map ||
            !json.containsKey('data') ||
            !json.containsKey('token')) {
          throw new AngelHttpException.notAuthenticated(
              message:
                  "Auth endpoint '$url' did not return a proper response.");
        }

        var r = new AngelAuthResult.fromMap(json);
        _onAuthenticated.add(r);
        return r;
      } on AngelHttpException {
        rethrow;
      } catch (e, st) {
        throw failure(response, error: e, stack: st);
      }
    } else {
      final url = '$basePath$authEndpoint/$type';
      http.Response response;

      if (credentials != null) {
        response = await client.post(url,
            body: JSON.encode(credentials), headers: _writeHeaders);
      } else {
        response = await client.post(url, headers: _writeHeaders);
      }

      if (_invalid(response)) {
        throw failure(response);
      }

      try {
        final json = JSON.decode(response.body);

        if (json is! Map ||
            !json.containsKey('data') ||
            !json.containsKey('token')) {
          throw new AngelHttpException.notAuthenticated(
              message:
                  "Auth endpoint '$url' did not return a proper response.");
        }

        var r = new AngelAuthResult.fromMap(json);
        _onAuthenticated.add(r);
        return r;
      } on AngelHttpException {
        rethrow;
      } catch (e, st) {
        throw failure(response, error: e, stack: st);
      }
    }
  }

  Future close() async {
    client.close();
    _onAuthenticated.close();
    Future.wait(_services.map((s) => s.close())).then((_) {
      _services.clear();
    });
  }

  Future logout() async {
    authToken = null;
  }

  /// Sends a non-streaming [Request] and returns a non-streaming [Response].
  Future<http.Response> sendUnstreamed(
      String method, url, Map<String, String> headers,
      [body, Encoding encoding]) async {
    if (url is String) url = Uri.parse(url);
    var request = new http.Request(method, url);

    if (headers != null) request.headers.addAll(headers);

    if (authToken?.isNotEmpty == true)
      request.headers['Authorization'] = 'Bearer $authToken';

    if (encoding != null) request.encoding = encoding;
    if (body != null) {
      if (body is String) {
        request.body = body;
      } else if (body is List) {
        request.bodyBytes = DelegatingList.typed(body);
      } else if (body is Map) {
        request.bodyFields = DelegatingMap.typed(body);
      } else {
        throw new ArgumentError('Invalid request body "$body".');
      }
    }

    return http.Response.fromStream(await client.send(request));
  }

  @override
  Service<T> service<T>(String path,
      {Type type, AngelDeserializer deserializer}) {
    String uri = path.toString().replaceAll(straySlashes, "");
    var s = new BaseAngelService<T>(client, this, '$basePath/$uri',
        deserializer: deserializer);
    _services.add(s);
    return s;
  }

  String _join(url) {
    final head = basePath.replaceAll(new RegExp(r'/+$'), '');
    final tail = url.replaceAll(straySlashes, '');
    return '$head/$tail';
  }

  @override
  Future<http.Response> delete(String url,
      {Map<String, String> headers}) async {
    return sendUnstreamed('DELETE', _join(url), headers);
  }

  @override
  Future<http.Response> get(String url, {Map<String, String> headers}) async {
    return sendUnstreamed('GET', _join(url), headers);
  }

  @override
  Future<http.Response> head(String url, {Map<String, String> headers}) async {
    return sendUnstreamed('HEAD', _join(url), headers);
  }

  @override
  Future<http.Response> patch(String url,
      {body, Map<String, String> headers}) async {
    return sendUnstreamed('PATCH', _join(url), headers, body);
  }

  @override
  Future<http.Response> post(String url,
      {body, Map<String, String> headers}) async {
    return sendUnstreamed('POST', _join(url), headers, body);
  }

  @override
  Future<http.Response> put(String url,
      {body, Map<String, String> headers}) async {
    return sendUnstreamed('PUT', _join(url), headers, body);
  }
}

class BaseAngelService<T> extends Service<T> {
  @override
  final BaseAngelClient app;
  final String basePath;
  final http.BaseClient client;
  final AngelDeserializer deserializer;

  final StreamController<T> _onIndexed = new StreamController<T>(),
      _onRead = new StreamController<T>(),
      _onCreated = new StreamController<T>(),
      _onModified = new StreamController<T>(),
      _onUpdated = new StreamController<T>(),
      _onRemoved = new StreamController<T>();

  @override
  Stream<T> get onIndexed => _onIndexed.stream;

  @override
  Stream<T> get onRead => _onRead.stream;

  @override
  Stream<T> get onCreated => _onCreated.stream;

  @override
  Stream<T> get onModified => _onModified.stream;

  @override
  Stream<T> get onUpdated => _onUpdated.stream;

  @override
  Stream<T> get onRemoved => _onRemoved.stream;

  @override
  Future close() async {
    _onIndexed.close();
    _onRead.close();
    _onCreated.close();
    _onModified.close();
    _onUpdated.close();
    _onRemoved.close();
  }

  BaseAngelService(this.client, this.app, this.basePath, {this.deserializer});

  deserialize(x) {
    return deserializer != null ? deserializer(x) : x;
  }

  makeBody(x) {
    return JSON.encode(x);
  }

  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (app.authToken != null && app.authToken.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer ${app.authToken}';
    }

    return client.send(request);
  }

  @override
  Future index([Map params]) async {
    final response = await app.sendUnstreamed(
        'GET', '$basePath${_buildQuery(params)}', _readHeaders);

    try {
      if (_invalid(response)) {
        throw failure(response);
      }

      final json = JSON.decode(response.body);

      if (json is! List) {
        _onIndexed.add(json);
        return json;
      }

      var r = json.map(deserialize).toList();
      _onIndexed.add(r);
      return r;
    } catch (e, st) {
      throw failure(response, error: e, stack: st);
    }
  }

  @override
  Future read(id, [Map params]) async {
    final response = await app.sendUnstreamed(
        'GET', '$basePath/$id${_buildQuery(params)}', _readHeaders);

    try {
      if (_invalid(response)) {
        throw failure(response);
      }

      var r = deserialize(JSON.decode(response.body));
      _onRead.add(r);
      return r;
    } catch (e, st) {
      throw failure(response, error: e, stack: st);
    }
  }

  @override
  Future create(data, [Map params]) async {
    final response = await app.sendUnstreamed('POST',
        '$basePath/${_buildQuery(params)}', _writeHeaders, makeBody(data));

    try {
      if (_invalid(response)) {
        throw failure(response);
      }

      var r = deserialize(JSON.decode(response.body));
      _onCreated.add(r);
      return r;
    } catch (e, st) {
      throw failure(response, error: e, stack: st);
    }
  }

  @override
  Future modify(id, data, [Map params]) async {
    final response = await app.sendUnstreamed('PATCH',
        '$basePath/$id${_buildQuery(params)}', _writeHeaders, makeBody(data));

    try {
      if (_invalid(response)) {
        throw failure(response);
      }

      var r = deserialize(JSON.decode(response.body));
      _onModified.add(r);
      return r;
    } catch (e, st) {
      throw failure(response, error: e, stack: st);
    }
  }

  @override
  Future update(id, data, [Map params]) async {
    final response = await app.sendUnstreamed('POST',
        '$basePath/$id${_buildQuery(params)}', _writeHeaders, makeBody(data));

    try {
      if (_invalid(response)) {
        throw failure(response);
      }

      var r = deserialize(JSON.decode(response.body));
      _onUpdated.add(r);
      return r;
    } catch (e, st) {
      throw failure(response, error: e, stack: st);
    }
  }

  @override
  Future remove(id, [Map params]) async {
    final response = await app.sendUnstreamed(
        'DELETE', '$basePath/$id${_buildQuery(params)}', _readHeaders);

    try {
      if (_invalid(response)) {
        throw failure(response);
      }

      var r = deserialize(JSON.decode(response.body));
      _onRemoved.add(r);
      return r;
    } catch (e, st) {
      throw failure(response, error: e, stack: st);
    }
  }
}
