import 'dart:io';
import 'package:angel_container/mirrors.dart';
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
    app = new srv.Angel(reflector: const MirrorsReflector());
    http = new srv.AngelHttp(app, useZone: false);

    websockets = new srv.AngelWebSocket(app)
      ..onData.listen((data) {
        print('Received by server: $data');
      });

    await app.configure(websockets.configureServer);
    app.all('/ws', websockets.handleRequest);
    await app.configure(new GameController(websockets).configureServer);
    app.logger = new Logger('angel_auth')..onRecord.listen(print);

    server = await http.startServer();
    url = 'ws://${server.address.address}:${server.port}/ws';

    client = new ws.WebSockets(url);
    await client.connect(timeout: new Duration(seconds: 3));

    print('Connected');

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

  group('controller.io', () {
    test('search', () async {
      client.sendAction(new ws.WebSocketAction(eventName: 'search'));
      var search = await client.on['searched'].first;
      print('Searched: ${search.data}');
      expect(new Game.fromJson(search.data as Map), equals(johnVsBob));
    });
  });
}
