import 'dart:io';
import 'package:angel_diagnostics/angel_diagnostics.dart' as srv;
import 'package:angel_framework/angel_framework.dart' as srv;
import 'package:angel_websocket/io.dart' as ws;
import 'package:angel_websocket/server.dart' as srv;
import 'package:test/test.dart';
import 'common.dart';

main() {
  srv.Angel app;
  ws.WebSockets client;
  srv.AngelWebSocket websockets;
  HttpServer server;
  String url;

  setUp(() async {
    app = new srv.Angel();

    websockets = new srv.AngelWebSocket(debug: true)
      ..onData.listen((data) {
        print('Received by server: $data');
      });

    await app.configure(websockets);
    await app.configure(new GameController());

    server =
        await new srv.DiagnosticsServer(app, new File('log.txt')).startServer();
    url = 'ws://${server.address.address}:${server.port}/ws';

    client = new ws.WebSockets(url);
    await client.connect();

    client
      ..onData.listen((data) {
        print('Received by client: $data');
      })
      ..onError.listen((error) {
        // Auto-fail tests on errors ;)
        stderr.writeln(error);
        error.errors.forEach(stderr.writeln);
        throw error;
      });
  });

  tearDown(() async {
    await client.close();
    await server.close(force: true);
    app = null;
    client = null;
    server = null;
    url = null;
  });

  group('controller.io', () {
    test('search', () async {
      client.send('search', new ws.WebSocketAction());
      var search = await client.onData.first;
      print('First: $search');
    });
  });
}
