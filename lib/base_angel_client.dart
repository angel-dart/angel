import 'dart:async';
import 'dart:convert' show Encoding;
import 'package:angel_http_exception/angel_http_exception.dart';
import 'dart:convert';
import 'package:http/src/base_client.dart' as http;
import 'package:http/src/base_request.dart' as http;
import 'package:http/src/request.dart' as http;
import 'package:http/src/response.dart' as http;
import 'package:http/src/streamed_response.dart' as http;
import 'package:path/path.dart' as p;
import 'angel_client.dart';

const Map<String, String> _readHeaders = const {'Accept': 'application/json'};
const Map<String, String> _writeHeaders = const {
  'Accept': 'application/json',
  'Content-Type': 'application/json'
};

Map<String, String> _buildQuery(Map<String, dynamic> params) {
  return params?.map((k, v) => new MapEntry(k, v.toString()));
}

bool _invalid(http.Response response) =>
    response.statusCode == null ||
    response.statusCode < 200 ||
    response.statusCode >= 300;

AngelHttpException failure(http.Response response,
    {error, String message, StackTrace stack}) {
  try {
    var v = json.decode(response.body);

    if (v is Map && (v['is_error'] == true) || v['isError'] == true) {
      return new AngelHttpException.fromMap(v as Map);
    } else {
      return new AngelHttpException(error,
          message: message ??
              'Unhandled exception while connecting to Angel backend.',
          statusCode: response.statusCode,
          stackTrace: stack);
    }
  } catch (e, st) {
    return new AngelHttpException(error ?? e,
        message: message ??
            'Angel backend did not return JSON - an error likely occurred.',
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

  BaseAngelClient(this.client, baseUrl) : super(baseUrl);

  @override
  Future<AngelAuthResult> authenticate(
      {String type,
      credentials,
      String authEndpoint = '/auth',
      @deprecated String reviveEndpoint = '/auth/token'}) async {
    type ??= 'token';

    var segments = baseUrl.pathSegments
        .followedBy(p.split(authEndpoint))
        .followedBy([type]);
    var url = baseUrl.replace(path: p.joinAll(segments));
    http.Response response;

    if (credentials != null) {
      response = await post(url,
          body: json.encode(credentials), headers: _writeHeaders);
    } else {
      response = await post(url, headers: _writeHeaders);
    }

    if (_invalid(response)) {
      throw failure(response);
    }

    try {
      var v = json.decode(response.body);

      if (v is! Map ||
          !(v as Map).containsKey('data') ||
          !(v as Map).containsKey('token')) {
        throw new AngelHttpException.notAuthenticated(
            message: "Auth endpoint '$url' did not return a proper response.");
      }

      var r = new AngelAuthResult.fromMap(v as Map);
      _onAuthenticated.add(r);
      return r;
    } on AngelHttpException {
      rethrow;
    } catch (e, st) {
      throw failure(response, error: e, stack: st);
    }
  }

  Future<void> close() async {
    client.close();
    await _onAuthenticated.close();
    await Future.wait(_services.map((s) => s.close())).then((_) {
      _services.clear();
    });
  }

  Future<void> logout() async {
    authToken = null;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (authToken?.isNotEmpty == true)
      request.headers['authorization'] ??= 'Bearer $authToken';
    return client.send(request);
  }

  /// Sends a non-streaming [Request] and returns a non-streaming [Response].
  Future<http.Response> sendUnstreamed(
      String method, url, Map<String, String> headers,
      [body, Encoding encoding]) async {
    var request =
        new http.Request(method, url is Uri ? url : Uri.parse(url.toString()));

    if (headers != null) request.headers.addAll(headers);

    if (encoding != null) request.encoding = encoding;
    if (body != null) {
      if (body is String) {
        request.body = body;
      } else if (body is List<int>) {
        request.bodyBytes = new List<int>.from(body);
      } else if (body is Map<String, dynamic>) {
        request.bodyFields =
            body.map((k, v) => MapEntry(k, v is String ? v : v.toString()));
      } else {
        throw new ArgumentError.value(body, 'body',
            'must be a String, List<int>, or Map<String, String>.');
      }
    }

    return http.Response.fromStream(await send(request));
  }

  @override
  Service<Id, Data> service<Id, Data>(String path,
      {Type type, AngelDeserializer<Data> deserializer}) {
    var url = baseUrl.replace(path: p.join(baseUrl.path, path));
    var s = new BaseAngelService<Id, Data>(client, this, url,
        deserializer: deserializer);
    _services.add(s);
    return s;
  }

  Uri _join(url) {
    var u = url is Uri ? url : Uri.parse(url.toString());
    if (u.hasScheme || u.hasAuthority) return u;
    return u.replace(path: p.join(baseUrl.path, u.path));
  }

  @override
  Future<http.Response> delete(url, {Map<String, String> headers}) async {
    return sendUnstreamed('DELETE', _join(url), headers);
  }

  @override
  Future<http.Response> get(url, {Map<String, String> headers}) async {
    return sendUnstreamed('GET', _join(url), headers);
  }

  @override
  Future<http.Response> head(url, {Map<String, String> headers}) async {
    return sendUnstreamed('HEAD', _join(url), headers);
  }

  @override
  Future<http.Response> patch(url,
      {body, Map<String, String> headers, Encoding encoding}) async {
    return sendUnstreamed('PATCH', _join(url), headers, body, encoding);
  }

  @override
  Future<http.Response> post(url,
      {body, Map<String, String> headers, Encoding encoding}) async {
    return sendUnstreamed('POST', _join(url), headers, body, encoding);
  }

  @override
  Future<http.Response> put(url,
      {body, Map<String, String> headers, Encoding encoding}) async {
    return sendUnstreamed('PUT', _join(url), headers, body, encoding);
  }
}

class BaseAngelService<Id, Data> extends Service<Id, Data> {
  @override
  final BaseAngelClient app;
  final Uri baseUrl;
  final http.BaseClient client;
  final AngelDeserializer<Data> deserializer;

  final StreamController<List<Data>> _onIndexed = new StreamController();
  final StreamController<Data> _onRead = new StreamController(),
      _onCreated = new StreamController(),
      _onModified = new StreamController(),
      _onUpdated = new StreamController(),
      _onRemoved = new StreamController();

  @override
  Stream<List<Data>> get onIndexed => _onIndexed.stream;

  @override
  Stream<Data> get onRead => _onRead.stream;

  @override
  Stream<Data> get onCreated => _onCreated.stream;

  @override
  Stream<Data> get onModified => _onModified.stream;

  @override
  Stream<Data> get onUpdated => _onUpdated.stream;

  @override
  Stream<Data> get onRemoved => _onRemoved.stream;

  @override
  Future close() async {
    await _onIndexed.close();
    await _onRead.close();
    await _onCreated.close();
    await _onModified.close();
    await _onUpdated.close();
    await _onRemoved.close();
  }

  BaseAngelService(this.client, this.app, baseUrl, {this.deserializer})
      : this.baseUrl = baseUrl is Uri ? baseUrl : Uri.parse(baseUrl.toString());

  /// Use [baseUrl] instead.
  @deprecated
  String get basePath => baseUrl.toString();

  Data deserialize(x) {
    return deserializer != null ? deserializer(x) : x as Data;
  }

  makeBody(x) {
    return json.encode(x);
  }

  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (app.authToken != null && app.authToken.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer ${app.authToken}';
    }

    return client.send(request);
  }

  @override
  Future<List<Data>> index([Map<String, dynamic> params]) async {
    var url = baseUrl.replace(queryParameters: _buildQuery(params));
    var response = await app.sendUnstreamed('GET', url, _readHeaders);

    try {
      if (_invalid(response)) {
        if (_onIndexed.hasListener)
          _onIndexed.addError(failure(response));
        else
          throw failure(response);
      }

      var v = json.decode(response.body) as List;
      var r = v.map(deserialize).toList();
      _onIndexed.add(r);
      return r;
    } catch (e, st) {
      if (_onIndexed.hasListener)
        _onIndexed.addError(e, st);
      else
        throw failure(response, error: e, stack: st);
    }

    return null;
  }

  @override
  Future<Data> read(id, [Map<String, dynamic> params]) async {
    var url = baseUrl.replace(
        path: p.join(baseUrl.path, id.toString()),
        queryParameters: _buildQuery(params));

    var response = await app.sendUnstreamed('GET', url, _readHeaders);

    try {
      if (_invalid(response)) {
        if (_onRead.hasListener)
          _onRead.addError(failure(response));
        else
          throw failure(response);
      }

      var r = deserialize(json.decode(response.body));
      _onRead.add(r);
      return r;
    } catch (e, st) {
      if (_onRead.hasListener)
        _onRead.addError(e, st);
      else
        throw failure(response, error: e, stack: st);
    }

    return null;
  }

  @override
  Future<Data> create(data, [Map<String, dynamic> params]) async {
    var url = baseUrl.replace(queryParameters: _buildQuery(params));
    var response =
        await app.sendUnstreamed('POST', url, _writeHeaders, makeBody(data));

    try {
      if (_invalid(response)) {
        if (_onCreated.hasListener)
          _onCreated.addError(failure(response));
        else
          throw failure(response);
      }

      var r = deserialize(json.decode(response.body));
      _onCreated.add(r);
      return r;
    } catch (e, st) {
      if (_onCreated.hasListener)
        _onCreated.addError(e, st);
      else
        throw failure(response, error: e, stack: st);
    }

    return null;
  }

  @override
  Future<Data> modify(id, data, [Map<String, dynamic> params]) async {
    var url = baseUrl.replace(
        path: p.join(baseUrl.path, id.toString()),
        queryParameters: _buildQuery(params));

    var response =
        await app.sendUnstreamed('PATCH', url, _writeHeaders, makeBody(data));

    try {
      if (_invalid(response)) {
        if (_onModified.hasListener)
          _onModified.addError(failure(response));
        else
          throw failure(response);
      }

      var r = deserialize(json.decode(response.body));
      _onModified.add(r);
      return r;
    } catch (e, st) {
      if (_onModified.hasListener)
        _onModified.addError(e, st);
      else
        throw failure(response, error: e, stack: st);
    }

    return null;
  }

  @override
  Future<Data> update(id, data, [Map<String, dynamic> params]) async {
    var url = baseUrl.replace(
        path: p.join(baseUrl.path, id.toString()),
        queryParameters: _buildQuery(params));

    var response =
        await app.sendUnstreamed('POST', url, _writeHeaders, makeBody(data));

    try {
      if (_invalid(response)) {
        if (_onUpdated.hasListener)
          _onUpdated.addError(failure(response));
        else
          throw failure(response);
      }

      var r = deserialize(json.decode(response.body));
      _onUpdated.add(r);
      return r;
    } catch (e, st) {
      if (_onUpdated.hasListener)
        _onUpdated.addError(e, st);
      else
        throw failure(response, error: e, stack: st);
    }

    return null;
  }

  @override
  Future<Data> remove(id, [Map<String, dynamic> params]) async {
    var url = baseUrl.replace(
        path: p.join(baseUrl.path, id.toString()),
        queryParameters: _buildQuery(params));

    var response = await app.sendUnstreamed('DELETE', url, _readHeaders);

    try {
      if (_invalid(response)) {
        if (_onRemoved.hasListener)
          _onRemoved.addError(failure(response));
        else
          throw failure(response);
      }

      var r = deserialize(json.decode(response.body));
      _onRemoved.add(r);
      return r;
    } catch (e, st) {
      if (_onRemoved.hasListener)
        _onRemoved.addError(e, st);
      else
        throw failure(response, error: e, stack: st);
    }

    return null;
  }
}
