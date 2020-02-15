import 'dart:async';
import 'package:angel_auth/angel_auth.dart';
import 'package:angel_client/io.dart' as c;
import 'package:angel_framework/angel_framework.dart';
import "package:angel_framework/http.dart";
import 'package:angel_websocket/io.dart' as c;
import 'package:angel_websocket/server.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

const Map<String, String> USER = const {'username': 'foo', 'password': 'bar'};

main() {
  Angel app;
  AngelHttp http;
  c.Angel client;
  c.WebSockets ws;

  setUp(() async {
    app = new Angel();
    http = new AngelHttp(app, useZone: false);
    var auth = new AngelAuth();

    auth.serializer = (_) async => 'baz';
    auth.deserializer = (_) async => USER;

    auth.strategies['local'] = new LocalAuthStrategy(
      (username, password) async {
        if (username == 'foo' && password == 'bar') return USER;
      },
    );

    app.post('/auth/local', auth.authenticate('local'));

    await app.configure(auth.configureServer);
    var sock = new AngelWebSocket(app);
    await app.configure(sock.configureServer);
    app.all('/ws', sock.handleRequest);
    app.logger = new Logger('angel_auth')..onRecord.listen(print);

    var server = await http.startServer();
    client = new c.Rest('http://${server.address.address}:${server.port}');
    ws = new c.WebSockets('ws://${server.address.address}:${server.port}/ws');
    await ws.connect();
  });

  tearDown(() {
    return Future.wait([
      http.close(),
      client.close(),
      ws.close(),
    ]);
  });

  test('auth event fires', () async {
    var localAuth = await client.authenticate(type: 'local', credentials: USER);
    print('JWT: ${localAuth.token}');

    ws.authenticateViaJwt(localAuth.token);
    var auth = await ws.onAuthenticated.first;
    expect(auth.token, localAuth.token);
  });
}
