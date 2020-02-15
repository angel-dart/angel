import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/http.dart';
import 'package:angel_mongo/angel_mongo.dart';
import 'package:http/http.dart' as http;
import 'package:json_god/json_god.dart' as god;
import 'package:mongo_dart/mongo_dart.dart';
import 'package:test/test.dart';

final headers = {
  'accept': 'application/json',
  'content-type': 'application/json'
};

final Map testGreeting = {'to': 'world'};

wireHooked(HookedService hooked) {
  hooked.afterAll((HookedServiceEvent event) {
    print("Just ${event.eventName}: ${event.result}");
    print('Params: ${event.params}');
  });
}

main() {
  group('Generic Tests', () {
    Angel app;
    AngelHttp transport;
    http.Client client;
    Db db = new Db('mongodb://localhost:27017/angel_mongo');
    DbCollection testData;
    String url;
    HookedService<String, Map<String, dynamic>, MongoService> greetingService;

    setUp(() async {
      app = new Angel();
      transport = new AngelHttp(app);
      client = new http.Client();
      await db.open();
      testData = db.collection('test_data');
      // Delete anything before we start
      await testData.remove(<String, dynamic>{});

      var service = new MongoService(testData, debug: true);
      greetingService = new HookedService(service);
      wireHooked(greetingService);

      app.use('/api', greetingService);

      await transport.startServer('127.0.0.1', 0);
      url = transport.uri.toString();
    });

    tearDown(() async {
      // Delete anything left over
      await testData.remove(<String, dynamic>{});
      await db.close();
      await transport.close();
      client = null;
      url = null;
      greetingService = null;
    });

    test('query fields mapped to filters', () async {
      await greetingService.create({'foo': 'bar'});
      expect(
        await greetingService.index({
          'query': {'foo': 'not bar'}
        }),
        isEmpty,
      );
      expect(
        await greetingService.index(),
        isNotEmpty,
      );
    });

    test('insert items', () async {
      var response = await client.post("$url/api",
          body: god.serialize(testGreeting), headers: headers);
      expect(response.statusCode, isIn([200, 201]));

      response = await client.get("$url/api");
      expect(response.statusCode, isIn([200, 201]));
      var users = god.deserialize(response.body,
          outputType: <Map>[].runtimeType) as List<Map>;
      expect(users.length, equals(1));
    });

    test('read item', () async {
      var response = await client.post("$url/api",
          body: god.serialize(testGreeting), headers: headers);
      expect(response.statusCode, isIn([200, 201]));
      var created = god.deserialize(response.body) as Map;

      response = await client.get("$url/api/${created['id']}");
      expect(response.statusCode, isIn([200, 201]));
      var read = god.deserialize(response.body) as Map;
      expect(read['id'], equals(created['id']));
      expect(read['to'], equals('world'));
      //expect(read['createdAt'], isNot(null));
    });

    test('findOne', () async {
      var response = await client.post("$url/api",
          body: god.serialize(testGreeting), headers: headers);
      expect(response.statusCode, isIn([200, 201]));
      var created = god.deserialize(response.body) as Map;

      var id = new ObjectId.fromHexString(created['id'] as String);
      var read = await greetingService.findOne({'query': where.id(id)});
      expect(read['id'], equals(created['id']));
      expect(read['to'], equals('world'));
      //expect(read['createdAt'], isNot(null));
    });

    test('readMany', () async {
      var response = await client.post("$url/api",
          body: god.serialize(testGreeting), headers: headers);
      expect(response.statusCode, isIn([200, 201]));
      var created = god.deserialize(response.body) as Map;

      var id = new ObjectId.fromHexString(created['id'] as String);
      var read = await greetingService.readMany([id.toHexString()]);
      expect(read, [created]);
      //expect(read['createdAt'], isNot(null));
    });

    test('modify item', () async {
      var response = await client.post("$url/api",
          body: god.serialize(testGreeting), headers: headers);
      expect(response.statusCode, isIn([200, 201]));
      var created = god.deserialize(response.body) as Map;

      response = await client.patch("$url/api/${created['id']}",
          body: god.serialize({"to": "Mom"}), headers: headers);
      var modified = god.deserialize(response.body) as Map;
      expect(response.statusCode, isIn([200, 201]));
      expect(modified['id'], equals(created['id']));
      expect(modified['to'], equals('Mom'));
      //expect(modified['updatedAt'], isNot(null));
    });

    test('update item', () async {
      var response = await client.post("$url/api",
          body: god.serialize(testGreeting), headers: headers);
      expect(response.statusCode, isIn([200, 201]));
      var created = god.deserialize(response.body) as Map;

      response = await client.post("$url/api/${created['id']}",
          body: god.serialize({"to": "Updated"}), headers: headers);
      var modified = god.deserialize(response.body) as Map;
      expect(response.statusCode, isIn([200, 201]));
      expect(modified['id'], equals(created['id']));
      expect(modified['to'], equals('Updated'));
      //expect(modified['updatedAt'], isNot(null));
    });

    test('remove item', () async {
      var response = await client.post("$url/api",
          body: god.serialize(testGreeting), headers: headers);
      var created = god.deserialize(response.body) as Map;

      int lastCount = (await greetingService.index()).length;

      await client.delete("$url/api/${created['id']}");
      expect((await greetingService.index()).length, equals(lastCount - 1));
    });

    test('cannot remove all unless explicitly set', () async {
      var response = await client.delete('$url/api/null');
      expect(response.statusCode, 403);
    });

    test('\$sort and query parameters', () async {
      // Search by where.eq
      Map world = await greetingService.create({"to": "world"});
      await greetingService.create({"to": "Mom"});
      await greetingService.create({"to": "Updated"});

      var response = await client.get("$url/api?to=world");
      print(response.body);
      var queried = god.deserialize(response.body,
          outputType: <Map>[].runtimeType) as List<Map>;
      expect(queried.length, equals(1));
      expect(queried[0].keys.length, equals(2));
      expect(queried[0]["id"], equals(world["id"]));
      expect(queried[0]["to"], equals(world["to"]));
      //expect(queried[0]["createdAt"], equals(world["createdAt"]));

      /*response = await client.get("$url/api?\$sort.createdAt=-1");
      print(response.body);
      queried = god.deserialize(response.body);
      expect(queried[0]["id"], equals(Updated["id"]));
      expect(queried[1]["id"], equals(Mom["id"]));
      expect(queried[2]["id"], equals(world["id"]));*/

      queried = await greetingService.index({
        "\$query": {
          "_id": where.id(new ObjectId.fromHexString(world["id"] as String))
        }
      });
      print(queried);
      expect(queried.length, equals(1));
      expect(queried[0], equals(world));
    });
  });
}
