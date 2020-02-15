import 'dart:isolate';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/http.dart';
import 'package:angel_sync/angel_sync.dart';
import 'package:angel_test/angel_test.dart';
import 'package:angel_websocket/io.dart' as client;
import 'package:angel_websocket/server.dart';
import 'package:pub_sub/isolate.dart' as pub_sub;
import 'package:pub_sub/pub_sub.dart' as pub_sub;
import 'package:test/test.dart';

main() {
  Angel app1, app2;
  TestClient app1Client;
  client.WebSockets app2Client;
  pub_sub.Server server;
  ReceivePort app1Port, app2Port;

  setUp(() async {
    var adapter = new pub_sub.IsolateAdapter();

    server = new pub_sub.Server([
      adapter,
    ])
      ..registerClient(const pub_sub.ClientInfo('angel_sync1'))
      ..registerClient(const pub_sub.ClientInfo('angel_sync2'))
      ..start();

    app1 = new Angel();
    app2 = new Angel();

    app1.post('/message', (req, res) async {
      // Manually broadcast. Even though app1 has no clients, it *should*
      // propagate to app2.
      var ws = req.container.make<AngelWebSocket>();
      var body = await req.parseBody();
      ws.batchEvent(new WebSocketEvent(
        eventName: 'message',
        data: body['message'],
      ));
      return 'Sent: ${body['message']}';
    });

    app1Port = new ReceivePort();
    var ws1 = new AngelWebSocket(
      app1,
      synchronizationChannel: new PubSubSynchronizationChannel(
        new pub_sub.IsolateClient('angel_sync1', adapter.receivePort.sendPort),
      ),
    );
    await app1.configure(ws1.configureServer);
    app1.get('/ws', ws1.handleRequest);
    app1Client = await connectTo(app1);

    app2Port = new ReceivePort();
    var ws2 = new AngelWebSocket(
      app2,
      synchronizationChannel: new PubSubSynchronizationChannel(
        new pub_sub.IsolateClient('angel_sync2', adapter.receivePort.sendPort),
      ),
    );
    await app2.configure(ws2.configureServer);
    app2.get('/ws', ws2.handleRequest);

    var http = new AngelHttp(app2);
    await http.startServer();
    var wsPath =
        http.uri.replace(scheme: 'ws', path: '/ws').removeFragment().toString();
    print(wsPath);
    app2Client = new client.WebSockets(wsPath);
    await app2Client.connect();
  });

  tearDown(() {
    server.close();
    app1Port.close();
    app2Port.close();
    app1.close();
    app2.close();
    app1Client.close();
    app2Client.close();
  });

  test('events propagate', () async {
    // The point of this test is that neither app1 nor app2
    // is aware that the other even exists.
    //
    // Regardless, a WebSocket event broadcast in app1 will be
    // broadcast by app2 as well.

    var stream = app2Client.on['message'];
    var response =
        await app1Client.post('/message', body: {'message': 'Hello, world!'});
    print('app1 response: ${response.body}');

    var msg = await stream.first.timeout(const Duration(seconds: 5));
    print('app2 got message: ${msg.data}');
  });
}
