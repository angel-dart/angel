import 'dart:async';
import 'dart:convert' show Encoding;
import 'dart:io' show ContentType, Cookie, HttpServer, HttpSession, WebSocket;
import 'package:dart2_constant/convert.dart';
import 'package:dart2_constant/io.dart' hide WebSocket;
import 'package:angel_client/base_angel_client.dart' as client;
import 'package:angel_client/io.dart' as client;
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_websocket/io.dart' as client;
import 'package:http/http.dart' as http hide StreamedResponse;
import 'package:http/src/streamed_response.dart';
import 'package:mock_request/mock_request.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
//import 'package:uuid/uuid.dart';

final RegExp _straySlashes = new RegExp(r"(^/)|(/+$)");
/*const Map<String, String> _readHeaders = const {'Accept': 'application/json'};
const Map<String, String> _writeHeaders = const {
  'Accept': 'application/json',
  'Content-Type': 'application/json'
};
final Uuid _uuid = new Uuid();*/

/// Shorthand for bootstrapping a [TestClient].
Future<TestClient> connectTo(Angel app,
    {Map initialSession,
    bool autoDecodeGzip: true,
    bool useZone: false}) async {
  if (!app.isProduction) app.configuration.putIfAbsent('testMode', () => true);

  for (var plugin in app.startupHooks) await plugin(app);
  return new TestClient(app,
      autoDecodeGzip: autoDecodeGzip != false, useZone: useZone)
    ..session.addAll(initialSession ?? {});
}

/// An `angel_client` that sends mock requests to a server, rather than actual HTTP transactions.
class TestClient extends client.BaseAngelClient {
  final Map<String, client.Service> _services = {};

  /// Session info to be sent to the server on every request.
  final HttpSession session = new MockHttpSession(id: 'angel-test-client');

  /// A list of cookies to be sent to and received from the server.
  final List<Cookie> cookies = [];

  /// If `true` (default), the client will automatically decode GZIP response bodies.
  final bool autoDecodeGzip;

  /// The server instance to mock.
  final Angel server;

  @override
  String authToken;

  AngelHttp _http;

  TestClient(this.server, {this.autoDecodeGzip: true, bool useZone: false})
      : super(new http.IOClient(), '/') {
    _http = new AngelHttp(server, useZone: useZone);
  }

  Future close() {
    this.client.close();
    return server.close();
  }

  /// Opens a WebSockets connection to the server. This will automatically bind the server
  /// over HTTP, if it is not already listening. Unfortunately, WebSockets cannot be mocked (yet!).
  Future<client.WebSockets> websocket({String path, Duration timeout}) async {
    HttpServer http = _http.httpServer;
    if (http == null) http = await _http.startServer();
    var url = 'ws://${http.address.address}:${http.port}';
    var cleanPath = (path ?? '/ws')?.replaceAll(_straySlashes, '');
    if (cleanPath?.isNotEmpty == true) url += '/$cleanPath';
    var ws = new _MockWebSockets(this, url);
    await ws.connect(timeout: timeout);
    return ws;
  }

  Future<http.Response> sendUnstreamed(
          String method, url, Map<String, String> headers,
          [body, Encoding encoding]) =>
      send(method, url, headers, body, encoding).then(http.Response.fromStream);

  Future<StreamedResponse> send(String method, url, Map<String, String> headers,
      [body, Encoding encoding]) async {
    var rq = new MockHttpRequest(
        method, url is Uri ? url : Uri.parse(url.toString()));
    headers?.forEach(rq.headers.add);

    if (authToken?.isNotEmpty == true)
      rq.headers.set('authorization', 'Bearer $authToken');

    rq..cookies.addAll(cookies)..session.addAll(session);

    if (body is Stream<List<int>>) {
      await rq.addStream(body);
    } else if (body is List<int>) {
      rq.add(body);
    } else if (body is Map) {
      if (rq.headers.contentType == null ||
          rq.headers.contentType.mimeType == 'application/json') {
        rq
          ..headers.contentType = new ContentType('application', 'json')
          ..write(json.encode(body.keys.fold<Map<String, dynamic>>(
              {}, (out, k) => out..[k.toString()] = body[k])));
      } else if (rq.headers.contentType?.mimeType ==
          'application/x-www-form-urlencoded') {
        rq.write(body.keys.fold<List<String>>(
            [],
            (out, k) => out
              ..add('$k=' + Uri.encodeComponent(body[k].toString()))).join());
      } else {
        throw new UnsupportedError(
            'Map bodies can only be sent for requests with the content type application/json or application/x-www-form-urlencoded.');
      }
    } else if (body != null) {
      rq.write(body);
    }

    await rq.close();

    await _http.handleRequest(rq);

    var rs = rq.response;
    session
      ..clear()
      ..addAll(rq.session);

    Map<String, String> extractedHeaders = {};

    rs.headers.forEach((k, v) {
      extractedHeaders[k] = v.join(',');
    });

    Stream<List<int>> stream = rs;

    if (autoDecodeGzip != false &&
        rs.headers['content-encoding']?.contains('gzip') == true) {
      stream = stream.transform(gzip.decoder);
    }

    return new StreamedResponse(stream, rs.statusCode,
        contentLength: rs.contentLength,
        isRedirect: rs.headers['location'] != null,
        headers: extractedHeaders,
        persistentConnection:
            rq.headers.value('connection')?.toLowerCase()?.trim() ==
                    'keep-alive' ||
                rq.headers.persistentConnection == true,
        reasonPhrase: rs.reasonPhrase);
  }

  Future<http.Response> delete(url, {Map<String, String> headers}) =>
      sendUnstreamed('DELETE', url, headers);

  Future<http.Response> get(url, {Map<String, String> headers}) =>
      sendUnstreamed('GET', url, headers);

  Future<http.Response> head(url, {Map<String, String> headers}) =>
      sendUnstreamed('HEAD', url, headers);

  Future<http.Response> patch(url, {body, Map<String, String> headers}) =>
      sendUnstreamed('PATCH', url, headers, body);

  Future<http.Response> post(url, {body, Map<String, String> headers}) =>
      sendUnstreamed('POST', url, headers, body);

  Future<http.Response> put(url, {body, Map<String, String> headers}) =>
      sendUnstreamed('PUT', url, headers, body);

  @override
  String basePath;

  @override
  Stream<String> authenticateViaPopup(String url, {String eventName: 'token'}) {
    throw new UnsupportedError(
        'MockClient does not support authentication via popup.');
  }

  @override
  Future configure(client.AngelConfigurer configurer) => configurer(this);

  @override
  client.Service service(String path,
      {Type type, client.AngelDeserializer deserializer}) {
    String uri = path.toString().replaceAll(_straySlashes, "");
    return _services.putIfAbsent(
        uri, () => new _MockService(this, uri, deserializer: deserializer));
  }
}

class _MockService extends client.BaseAngelService {
  final TestClient _app;

  _MockService(this._app, String basePath,
      {client.AngelDeserializer deserializer})
      : super(null, _app, basePath, deserializer: deserializer);

  @override
  Future<StreamedResponse> send(http.BaseRequest request) {
    if (app.authToken != null && app.authToken.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer ${app.authToken}';
    }

    return _app.send(
        request.method, request.url, request.headers, request.finalize());
  }
}

class _MockWebSockets extends client.WebSockets {
  final TestClient app;

  _MockWebSockets(this.app, String url) : super(url);

  @override
  Future<WebSocketChannel> getConnectedWebSocket() async {
    Map<String, String> headers = {};

    if (app.authToken?.isNotEmpty == true)
      headers['authorization'] = 'Bearer ${app.authToken}';

    var socket = await WebSocket.connect(basePath, headers: headers);
    return new IOWebSocketChannel(socket);
  }
}
