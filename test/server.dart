import 'dart:async';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart' as server;
import 'package:angel_websocket/cli.dart' as client;
import 'package:angel_websocket/server.dart';
import 'package:json_god/json_god.dart' as god;
import 'package:test/test.dart';
import 'common.dart';

main() {
  server.Angel app;
  client.WebSocketClient clientApp;
  client.WebSocketService clientTodos;
  Stream<Map> customEventStream;
  WebSocket socket;
  AngelWebSocket webSocket = new AngelWebSocket("/ws");

  setUp(() async {
    app = new server.Angel();

    app.use("/real", new FakeService(), hooked: false);
    app.use("/api/todos", new server.MemoryService<Todo>());
    await app
        .service("api/todos")
        .create(new Todo(text: "Clean your room", when: "now"));

    await app.configure(webSocket);
    await app.configure((server.Angel app) async {
      AngelWebSocket ws = app.container.make(AngelWebSocket);

      ws.onConnection.listen((WebSocketContext socket) {
        socket.onData.listen((data) {
          print("Data: $data");
        });

        customEventStream = socket.on["custom"];
      });
    });
    await app.configure(startTestServer);

    socket = await WebSocket.connect(app.properties["ws_url"]);
    clientApp = new client.WebSocketClient(app.properties["ws_url"]);
    await clientApp.connect();

    clientTodos = clientApp.service("api/todos", type: Todo);
  });

  tearDown(() async {
    await app.httpServer.close(force: true);
  });

  test("find all real-time services", () {
    print(webSocket.servicesAlreadyWired);
    expect(webSocket.servicesAlreadyWired, equals(["api/todos"]));
  });

  test("index", () async {
    var action = new WebSocketAction(eventName: "api/todos::index");
    socket.add(god.serialize(action));

    String json = await socket.first;
    print(json);

    WebSocketEvent e =
    god.deserialize(json, outputType: WebSocketEvent);
    expect(e.eventName, equals("api/todos::indexed"));
    expect(e.data[0]["when"], equals("now"));
  });

  test("create", () async {
    var todo = new Todo(text: "Finish the Angel framework", when: "2016");
    clientTodos.create(todo);

    var all = await clientTodos.onAllEvents.first;
    var e = await clientTodos.onCreated.first;
    print(god.serialize(e));

    expect(all, equals(e));
    expect(e.eventName, equals("created"));
    expect(e.data is Todo, equals(true));
    expect(e.data.text, equals(todo.text));
    expect(e.data.when, equals(todo.when));
  });

  test("custom event via controller", () async {
    clientApp.send("custom", {"hello": "world"});

    var data = await customEventStream.first;

    expect(data["eventName"], equals("custom"));
    expect(data["data"]["hello"], equals("world"));
  });
}

@Realtime()
class FakeService extends server.Service {}
