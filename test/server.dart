import 'dart:async';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_websocket/angel_websocket.dart';
import 'package:angel_websocket/server.dart';
import 'package:json_god/json_god.dart' as god;
import 'package:test/test.dart';
import 'common.dart';

main() {
  Angel app;
  WebSocket socket;

  setUp(() async {
    app = new Angel();

    app.use("/real", new FakeService(), hooked: false);
    app.use("/api/todos", new MemoryService<Todo>());

    await app.configure(websocket);
    await app.configure(startTestServer);

    socket = await WebSocket.connect(app.properties["ws_url"]);
  });

  tearDown(() async {
    await app.httpServer.close(force: true);
  });

  test("find all real-time services", () {
    print(websocket.servicesAlreadyWired);
    expect(websocket.servicesAlreadyWired, equals(["api/todos"]));
  });

  test("index", () async {
    var action = new WebSocketAction(eventName: "api/todos::index");
    socket.add(god.serialize(action));

    print(await socket.first);
  });
}

@Realtime()
class FakeService extends Service {}