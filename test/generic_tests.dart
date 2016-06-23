import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_mongo/angel_mongo.dart';
import 'package:http/http.dart' as http;
import 'package:json_god/json_god.dart' as god;
import 'package:mongo_dart/mongo_dart.dart';
import 'package:test/test.dart';

final headers = {
  HttpHeaders.ACCEPT: ContentType.JSON.mimeType,
  HttpHeaders.CONTENT_TYPE: ContentType.JSON.mimeType
};

final Map testGreeting = {'to': 'world'};

wireHooked(HookedService hooked) {
  hooked
    ..afterCreated.listen((HookedServiceEvent event) {
      print("Just created: ${event.result}");
    })
    ..afterModified.listen((HookedServiceEvent event) {
      print("Just modified: ${event.result}");
    })
    ..afterUpdated.listen((HookedServiceEvent event) {
      print("Just updated: ${event.result}");
    })
    ..afterRemoved.listen((HookedServiceEvent event) {
      print("Just removed: ${event.result}");
    });
}

main() {
  group('angel_mongo', () {
    Angel app = new Angel();
    http.Client client;
    Db db = new Db('mongodb://localhost:27017/angel_mongo');
    DbCollection testData;
    String url;
    HookedService Greetings;

    setUp(() async {
      client = new http.Client();
      await db.open();
      testData = db.collection('test_data');
      // Delete anything before we start
      await testData.remove();

      var service = new MongoService(testData);
      Greetings = new HookedService(service);
      wireHooked(Greetings);

      app.use('/api', Greetings);
      HttpServer server =
          await app.startServer(InternetAddress.LOOPBACK_IP_V4, 0);
      url = "http://${server.address.host}:${server.port}";
    });

    tearDown(() async {
      // Delete anything left over
      await testData.remove();
      await db.close();
      await app.httpServer.close(force: true);
      client = null;
      url = null;
      Greetings = null;
    });

    test('insert items', () async {
      var response = await client.post("$url/api",
          body: god.serialize(testGreeting), headers: headers);
      expect(response.statusCode, equals(HttpStatus.OK));

      response = await client.get("$url/api");
      expect(response.statusCode, 200);
      List<Map> users = god.deserialize(response.body);
      expect(users.length, equals(1));
    });

    test('read item', () async {
      var response = await client.post("$url/api",
          body: god.serialize(testGreeting), headers: headers);
      expect(response.statusCode, equals(HttpStatus.OK));
      Map created = god.deserialize(response.body);

      response = await client.get("$url/api/${created['id']}");
      expect(response.statusCode, equals(HttpStatus.OK));
      Map read = god.deserialize(response.body);
      expect(read['id'], equals(created['id']));
      expect(read['to'], equals('world'));
      expect(read['createdAt'], isNot(null));
    });

    test('modify item', () async {
      var response = await client.post("$url/api",
          body: god.serialize(testGreeting), headers: headers);
      expect(response.statusCode, equals(HttpStatus.OK));
      Map created = god.deserialize(response.body);

      response = await client.patch("$url/api/${created['id']}",
          body: god.serialize({"to": "Mom"}), headers: headers);
      Map modified = god.deserialize(response.body);
      expect(response.statusCode, equals(HttpStatus.OK));
      expect(modified['id'], equals(created['id']));
      expect(modified['to'], equals('Mom'));
      expect(modified['updatedAt'], isNot(null));
    });

    test('update item', () async {
      var response = await client.post("$url/api",
          body: god.serialize(testGreeting), headers: headers);
      expect(response.statusCode, equals(HttpStatus.OK));
      Map created = god.deserialize(response.body);

      response = await client.post("$url/api/${created['id']}",
          body: god.serialize({"to": "Updated"}), headers: headers);
      Map modified = god.deserialize(response.body);
      expect(response.statusCode, equals(HttpStatus.OK));
      expect(modified['id'], equals(created['id']));
      expect(modified['to'], equals('Updated'));
      expect(modified['updatedAt'], isNot(null));
    });

    test('remove item', () async {
      var response = await client.post("$url/api",
          body: god.serialize(testGreeting), headers: headers);
      Map created = god.deserialize(response.body);

      int lastCount = (await Greetings.index()).length;

      await client.delete("$url/api/${created['id']}");
      expect((await Greetings.index()).length, equals(lastCount - 1));
    });

    test(r'$sort', () async {});

    test('query parameters', () async {});
  });
}
