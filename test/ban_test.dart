import 'package:angel_framework/angel_framework.dart';
import 'package:angel_security/angel_security.dart';
import 'package:angel_test/angel_test.dart';
import 'package:test/test.dart';

main() {
  Angel app;
  TestClient client;

  setUp(() async {
    app = new Angel()
      ..chain(banIp('*.*.*.*')).get('/ban', 'WTF')
      ..chain(banOrigin('*')).get('/ban-origin', 'WTF')
      ..chain(banOrigin('*.foo.bar')).get('/allow-origin', 'YAY');

    client = await connectTo(app);
  });

  tearDown(() => client.close());

  test('ban everyone', () async {
    var response = await client.get('/ban');
    print(response.body);
    expect(response, hasStatus(403));
    expect(response.body.contains('WTF'), isFalse);
  });

  group('origin', () {
    test('ban everyone', () async {
      var response = await client
          .get('/ban-origin', headers: {'Origin': 'www.example.com'});
      print(response.body);
      expect(response, hasStatus(403));
      expect(response.body.contains('WTF'), isFalse);
    });

    test('ban specific', () async {
      var response =
          await client.get('/allow-origin', headers: {'Origin': 'www.foo.bar'});
      print(response.body);
      expect(response, hasStatus(403));
      expect(response.body.contains('YAY'), isFalse);

      response = await client
          .get('/allow-origin', headers: {'Origin': 'www.example.com'});
      print(response.body);
      expect(response, hasStatus(200));
      expect(response.body, contains('YAY'));
    });
  });
}
