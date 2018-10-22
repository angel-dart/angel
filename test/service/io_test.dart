import 'dart:io';
import 'package:angel_framework/angel_framework.dart' as srv;
import "package:angel_framework/http.dart" as srv;
import 'package:angel_websocket/io.dart' as ws;
import 'package:angel_websocket/server.dart' as srv;
import 'package:logging/logging.dart';
import 'package:test/test.dart';
import 'common.dart';

main() {
  srv.Angel app;
  srv.AngelHttp http;
  ws.WebSockets client;
  srv.AngelWebSocket websockets;
  HttpServer server;
  String url;

  setUp(() async {
    app = new srv.Angel()..use('/api/todos', new TodoService());
    http = new srv.AngelHttp(app, useZone: false);

    websockets = new srv.AngelWebSocket(app)
      ..onData.listen((data) {
        print('Received by server: $data');
      });

    await app.configure(websockets.configureServer);
    app.all('/ws', websockets.handleRequest);
    app.logger = new Logger('angel_auth')..onRecord.listen(print);
    server = await http.startServer();
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
    await http.close();
    app = null;
    client = null;
    server = null;
    url = null;
  });

  group('service.io', () {
    test('index', () => testIndex(client));
  });
}
