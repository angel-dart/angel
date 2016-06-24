import 'dart:io';
import 'package:angel_client/angel_client.dart' as client;
import 'package:angel_framework/angel_framework.dart' as server;
import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'shared.dart';

main() {
  group("rest", () {
    server.Angel serverApp = new server.Angel();
    server.HookedService serverPostcards;
    client.Angel clientApp;
    client.Service clientPostcards;
    HttpServer httpServer;

    setUp(() async {
      httpServer =
          await serverApp.startServer(InternetAddress.LOOPBACK_IP_V4, 3000);
      serverApp.use("/postcards", new server.MemoryService<Postcard>());
      serverPostcards = serverApp.service("postcards");

      clientApp = new client.Rest("http://localhost:3000", new http.Client());
      clientPostcards = clientApp.service("postcards");
    });

    tearDown(() async {
      await httpServer.close(force: true);
    });

    test("index", () async {
      Postcard niagaraFalls = await serverPostcards.create(
          new Postcard(location: "Niagara Falls", message: "Missing you!"));
      List<Map> indexed = await clientPostcards.index();
      print(indexed);
    });
  });
}
