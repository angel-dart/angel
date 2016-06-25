import 'dart:io';
import 'package:angel_client/shared.dart' as clientLib;
import 'package:angel_client/cli.dart' as client;
import 'package:angel_framework/angel_framework.dart' as server;
import 'package:http/http.dart' as http;
import 'package:json_god/json_god.dart' as god;
import 'package:test/test.dart';
import 'shared.dart';

main() {
  group("rest", () {
    server.Angel serverApp = new server.Angel();
    server.HookedService serverPostcards;
    clientLib.Angel clientApp;
    clientLib.Service clientPostcards;
    clientLib.Service clientTypedPostcards;
    HttpServer httpServer;

    setUp(() async {
      httpServer =
      await serverApp.startServer(InternetAddress.LOOPBACK_IP_V4, 3000);
      serverApp.use("/postcards", new server.MemoryService<Postcard>());
      serverPostcards = serverApp.service("postcards");

      clientApp = new client.Rest("http://localhost:3000", new http.Client());
      clientPostcards = clientApp.service("postcards");
      clientTypedPostcards = clientApp.service("postcards", type: Postcard);
    });

    tearDown(() async {
      await httpServer.close(force: true);
    });

    test("index", () async {
      Postcard niagaraFalls = await serverPostcards.create(
          new Postcard(location: "Niagara Falls", message: "Missing you!"));
      List<Map> indexed = await clientPostcards.index();
      print(indexed);

      expect(indexed.length, equals(1));
      expect(indexed[0].keys.length, equals(3));
      expect(indexed[0]['id'], equals(niagaraFalls.id));
      expect(indexed[0]['location'], equals(niagaraFalls.location));
      expect(indexed[0]['message'], equals(niagaraFalls.message));

      Postcard louvre = await serverPostcards.create(new Postcard(
          location: "The Louvre", message: "The Mona Lisa was watching me!"));
      print(god.serialize(louvre));
      List<Postcard> typedIndexed = await clientTypedPostcards.index();
      expect(typedIndexed.length, equals(2));
      expect(typedIndexed[1], equals(louvre));
    });

    test("create/read", () async {
      Map opry = {"location": "Grand Ole Opry", "message": "Yeehaw!"};
      var created = await clientPostcards.create(opry);
      print(created);

      expect(created['id'] == null, equals(false));
      expect(created["location"], equals(opry["location"]));
      expect(created["message"], equals(opry["message"]));

      var read = await clientPostcards.read(created['id']);
      print(read);
      expect(read['id'], equals(created['id']));
      expect(read['location'], equals(created['location']));
      expect(read['message'], equals(created['message']));

      Postcard canyon = new Postcard(location: "Grand Canyon",
          message: "But did you REALLY experience it???");
      created = await clientTypedPostcards.create(canyon);
      print(god.serialize(created));

      expect(created.location, equals(canyon.location));
      expect(created.message, equals(canyon.message));

      read = await clientTypedPostcards.read(created.id);
      print(god.serialize(read));
      expect(read.id, equals(created.id));
      expect(read.location, equals(created.location));
      expect(read.message, equals(created.message));
    });

    test("modify/update", () async {
      server.MemoryService<Postcard> innerPostcards = serverPostcards.inner;
      print(innerPostcards.items);
      Postcard mecca = await clientTypedPostcards.create(
          new Postcard(location: "Mecca", message: "Pilgrimage"));
      print(god.serialize(mecca));

      // I'm too lazy to write the tests twice, because I know it works
      // So I'll modify using the type-based client, and update using the
      // map-based one

      print("Postcards on server: " +
          god.serialize(await serverPostcards.index()));
      print("Postcards on client: " +
          god.serialize(await clientPostcards.index()));

      Postcard modified = await clientTypedPostcards.modify(
          mecca.id, {"location": "Saudi Arabia"});
      print(god.serialize(modified));
      expect(modified.id, equals(mecca.id));
      expect(modified.location, equals("Saudi Arabia"));
      expect(modified.message, equals(mecca.message));

      Map updated = await clientPostcards.update(
          mecca.id, {"location": "Full", "message": "Overwrite"});
      print(updated);

      expect(updated.keys.length, equals(3));
      expect(updated['id'], equals(mecca.id));
      expect(updated['location'], equals("Full"));
      expect(updated['message'], equals("Overwrite"));
    });

    test("remove", () async {
      Postcard remove1 = await clientTypedPostcards.create(
          {"location": "remove", "message": "#1"});
      Postcard remove2 = await clientTypedPostcards.create(
          {"location": "remove", "message": "#2"});
      print(god.serialize([remove1, remove2]));

      Map removed1 = await clientPostcards.remove(remove1.id);
      expect(removed1.keys.length, equals(3));
      expect(removed1['id'], equals(remove1.id));
      expect(removed1['location'], equals(remove1.location));
      expect(removed1['message'], equals(remove1.message));

      Postcard removed2 = await clientTypedPostcards.remove(remove2.id);
      expect(removed2, equals(remove2));
    });
  });
}