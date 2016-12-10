import 'dart:async';
import 'dart:io';
import 'package:angel_client/io.dart' as client;
import 'package:angel_framework/angel_framework.dart' as server;

Future<client.Angel> connectTo(server.Angel app) async {
  final server = await app.startServer();
  return new _TestClient(
      server, 'http://${server.address.address}:${server.port}');
}

class _TestClient extends client.Rest {
  final HttpServer server;

  _TestClient(this.server, String path) : super(path);

  @override
  Future close() async {
    if (server != null) {
      await server.close(force: true);
    }
  }
}
