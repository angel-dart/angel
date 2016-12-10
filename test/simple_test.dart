import 'package:angel_framework/angel_framework.dart' as server;
import 'package:angel_test/angel_test.dart';
import 'package:test/test.dart';

main() {
  server.Angel app;
  TestClient testClient;

  setUp(() async {
    app = new server.Angel()
      ..get('/hello', 'Hello')
      ..post('/hello', (req, res) async {
        return {'bar': req.body['foo']};
      });

    testClient = await connectTo(app);
  });

  tearDown(() async {
    await testClient.close();
    app = null;
  });

  group('isJson+hasStatus', () {
    test('get', () async {
      final response = await testClient.get('/hello');
      expect(response, isJson('Hello'));
    });

    test('post', () async {
      final response = await testClient.post('/hello', body: {'foo': 'baz'});
      expect(response, allOf(hasStatus(200), isJson({'bar': 'baz'})));
    });
  });

  group('session', () {
    test('initial session', () async {
      final TestClient client =
          await connectTo(app, initialSession: {'foo': 'bar'});
      expect(client.session['foo'], equals('bar'));
    });

    test('add to session', () async {
      final TestClient client = await connectTo(app);
      await client.addToSession({'michael': 'jackson'});
      expect(client.session['michael'], equals('jackson'));
    });

    test('remove from session', () async {
      final TestClient client = await connectTo(app, initialSession: {'angel': 'framework'});
      await client.removeFromSession(['angel']);
      expect(client.session.containsKey('angel'), isFalse);
    });

    test('disable session', () async {
      final client = await connectTo(app, saveSession: false);
      expect(client.session, isNull);
    });
  });
}
