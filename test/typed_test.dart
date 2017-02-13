import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/common.dart' show Model;
import 'package:angel_mongo/angel_mongo.dart';
import 'package:http/http.dart' as http;
import 'package:json_god/json_god.dart' as god;
import 'package:mongo_dart/mongo_dart.dart';
import 'package:test/test.dart';

class Greeting extends Model {
  String to;

  Greeting({String id, this.to, DateTime createdAt, DateTime updatedAt})
      : super(id: id, createdAt: createdAt, updatedAt: updatedAt);
}

final headers = {
  HttpHeaders.ACCEPT: ContentType.JSON.mimeType,
  HttpHeaders.CONTENT_TYPE: ContentType.JSON.mimeType
};

final Map testGreeting = {'to': 'world'};

wireHooked(HookedService hooked) {
  hooked
    ..afterCreated.listen((HookedServiceEvent event) {
      print("Just created: ${god.serialize(event.result)}");
    })
    ..afterModified.listen((HookedServiceEvent event) {
      print("Just modified: ${god.serialize(event.result)}");
    })
    ..afterUpdated.listen((HookedServiceEvent event) {
      print("Just updated: ${event.result}");
    });
}

main() {
  group('Typed Tests', () {
    Angel app = new Angel();
    http.Client client;
    Db db = new Db('mongodb://localhost:27017/angel_mongo');
    DbCollection testData;
    String url;
    Service greetingService;

    setUp(() async {
      client = new http.Client();
      await db.open();
      testData = db.collection('test_greetings');
      // Delete anything before we start
      await testData.remove();

      var service = new MongoTypedService<Greeting>(testData);
      greetingService = new HookedService(service);
      wireHooked(greetingService);

      app.use('/api', greetingService);

      app.fatalErrorStream.listen((AngelFatalError e) {
        print('Fatal error: ${e.error}');
        print(e.stack);
      });

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
      greetingService = null;
    });

    test('insert items', () async {
      var response = await client.post("$url/api",
          body: god.serialize(testGreeting), headers: headers);
      expect(response.statusCode, equals(HttpStatus.OK));

      response = await client.get("$url/api");
      expect(response.statusCode, 200);
      List<Map> greetings = god.deserialize(response.body);
      expect(greetings.length, equals(1));

      Greeting greeting = new Greeting(to: "Mom");
      await greetingService.create(greeting);
      greetings = await (await testData.find()).toList();
      expect(greetings.length, equals(2));
    });

    test('read item', () async {
      var response = await client.post("$url/api",
          body: god.serialize(testGreeting), headers: headers);
      expect(response.statusCode, equals(HttpStatus.OK));
      Map created = god.deserialize(response.body);

      response = await client.get("$url/api/${created['id']}");
      expect(response.statusCode, equals(HttpStatus.OK));
      Map read = god.deserialize(response.body);
      print('Read: $read');
      expect(read['id'], equals(created['id']));
      expect(read['to'], equals('world'));
      expect(read['createdAt'], isNotNull);

      Greeting greeting = await greetingService.read(created['id']);
      expect(greeting.id, equals(created['id']));
      expect(greeting.to, equals('world'));
      expect(greeting.createdAt, isNotNull);
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
      expect(modified['updatedAt'], isNotNull);

      await greetingService.modify(created['id'], {"to": "Batman"});
      Greeting greeting = await greetingService.read(created['id']);
      expect(greeting.to, equals("Batman"));
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
      expect(modified['updatedAt'], isNotNull);
    });

    test('remove item', () async {
      var response = await client.post("$url/api",
          body: god.serialize(testGreeting), headers: headers);
      Map created = god.deserialize(response.body);

      int lastCount = (await greetingService.index()).length;

      await client.delete("$url/api/${created['id']}");
      expect((await greetingService.index()).length, equals(lastCount - 1));

      Greeting bernie =
          await greetingService.create(new Greeting(to: "Bernie Sanders"));
      lastCount = (await greetingService.index()).length;

      print('b');
      await greetingService.remove(bernie.id);
      expect((await greetingService.index()).length, equals(lastCount - 1));
      print('c');
    });

    test('query parameters', () async {
      // Search by where.eq
      Greeting world = await greetingService.create(new Greeting(to: "world"));
      await greetingService.create(new Greeting(to: "Mom"));
      await greetingService.create(new Greeting(to: "Updated"));

      var response = await client.get("$url/api?to=world");
      print(response.body);
      List queried = god.deserialize(response.body);
      expect(queried.length, equals(1));
      expect(queried[0].keys.length, equals(4));
      expect(queried[0]["id"], equals(world.id));
      expect(queried[0]["to"], equals(world.to));
      expect(
          queried[0]["createdAt"], equals(world.createdAt?.toIso8601String()));

      /*response = await client.get("$url/api?\$sort.createdAt=-1");
      print(response.body);
      queried = god.deserialize(response.body);
      expect(queried[0]["id"], equals(Updated.id));
      expect(queried[1]["id"], equals(Mom.id));
      expect(queried[2]["id"], equals(world.id));*/

      queried = await greetingService.index({
        "\$query": {"_id": where.id(new ObjectId.fromHexString(world.id))}
      });
      print(queried.map(god.serialize).toList());
      expect(queried.length, equals(1));
      expect(queried[0].id, equals(world.id));
      expect(queried[0].to, equals(world.to));
      expect(queried[0].createdAt, equals(world.createdAt));
    });
  });
}
