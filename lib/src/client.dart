import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:angel_client/io.dart' as client;
import 'package:angel_framework/angel_framework.dart';
import 'package:mock_request/mock_request.dart';
import 'package:uuid/uuid.dart';

final Uuid _uuid = new Uuid();

Future<TestClient> connectTo(Angel app,
    {Map initialSession, bool saveSession: false}) async {
  TestClient client;
  var path = '/${_uuid.v1()}/${_uuid.v1()}/${_uuid.v1()}';

  if (saveSession) {
    app
      ..get(path, (RequestContext req, res) async {
        client._session = req.session;

        if (initialSession != null) {
          req.session.addAll(initialSession);
        }
      })
      ..post(path, (RequestContext req, res) async {
        client._session = req.session..addAll(req.body);
      })
      ..patch(path, (RequestContext req, res) async {
        req.body['keys'].forEach(req.session.remove);
        client._session = req.session;
      });
  }

  final server = await app.startServer();
  final url = 'http://${server.address.address}:${server.port}';
  client = new TestClient(server, url);

  if (saveSession) {
    await client.client.get('$url$path');
    client._sessionPath = path;
  }

  return client;
}

Future<MockHttpResponse> mock(Angel app, String method, Uri uri,
    {Iterable<Cookie> cookies: const [],
    Map<String, dynamic> headers: const {}}) async {
  var rq = new MockHttpRequest(method, uri);
  rq.cookies.addAll(cookies ?? []);
  headers.forEach(rq.headers.add);
  await rq.close();
  await app.handleRequest(rq);
  return rq.response;
}

/// Interacts with an Angel server.
class TestClient extends client.Rest {
  final HttpServer server;
  HttpSession _session;
  String _sessionPath;

  /// Returns a pointer to the current session.
  HttpSession get session => _session;

  TestClient(this.server, String path) : super(path);

  /// Adds data to the [session].
  Future addToSession(Map data) => post(_sessionPath, body: data);

  /// Removes data from the [session].
  Future removeFromSession(List<String> keys) => patch(_sessionPath,
      body: JSON.encode({'keys': keys}),
      headers: {HttpHeaders.CONTENT_TYPE: ContentType.JSON.mimeType});

  @override
  Future close() async {
    if (server != null) {
      await server.close(force: true);
    }
  }
}
