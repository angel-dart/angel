import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_mongo/angel_mongo.dart';
import 'package:http/http.dart' as http;
import 'package:json_god/json_god.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:test/test.dart';

final headers = {
  HttpHeaders.ACCEPT: ContentType.JSON.mimeType,
  HttpHeaders.CONTENT_TYPE: ContentType.JSON.mimeType
};

wireHooked(HookedService hooked) {
  hooked.onCreated.listen((item) {
    print("Just created: $item");
  });
}

main() {
  group('angel_mongo', () {
    Angel app = new Angel();
    http.Client client;
    God god = new God();
    Db db = new Db('mongodb://localhost:27017/angel_mongo');
    DbCollection testData;
    String url;

    setUp(() async {
      client = new http.Client();
      await db.open();
      testData = db.collection('test_data');
      // Delete anything before we start
      await testData.remove();
      var service = new MongoService(testData);
      var hooked = new HookedService(service);
      wireHooked(hooked);

      app.use('/api', hooked);
      HttpServer server = await app.startServer(
          InternetAddress.LOOPBACK_IP_V4, 0);
      url = "http://${server.address.host}:${server.port}";
    });

    tearDown(() async {
      // Delete anything left over
      await testData.remove();
      await db.close();
      await app.httpServer.close(force: true);
      client = null;
      url = null;
    });

    test('insert items', () async {
      Map testUser = {'hello': 'world'};

      var response = await client.post(
          "$url/api", body: god.serialize(testUser), headers: headers);
      expect(response.statusCode, equals(HttpStatus.OK));

      response = await client.get("$url/api");
      expect(response.statusCode, 200);
      List<Map> users = god.deserialize(response.body);
      expect(users.length, equals(1));
    });

    test('read item', () async {
      Map testUser = {'hello': 'world'};
      var response = await client.post(
          "$url/api", body: god.serialize(testUser), headers: headers);
      expect(response.statusCode, equals(HttpStatus.OK));
      Map created = god.deserialize(response.body);

      response = await client.get("$url/api/${created['_id']}");
      expect(response.statusCode, equals(HttpStatus.OK));
      Map read = god.deserialize(response.body);
      expect(read['_id'], equals(created['_id']));
      expect(read['hello'], equals('world'));
      expect(read['createdAt'], isNot(null));
    });

    test('modify item', () async {

    });

    test('update item', () async {

    });

    test('remove item', () async {

    });

    test('sort by string', () async {

    });

    test('sort by map', () async {

    });

    test('query parameters', () async {

    });
  });
}