import 'dart:io';
import 'package:angel/angel.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_test/angel_test.dart';
import 'package:test/test.dart';

main() async {
  Angel app;
  TestClient client;

  setUp(() async {
    app = await createServer();
    client = await connectTo(app, saveSession: false);
  });

  tearDown(() async {
    await client.close();
    app = null;
  });

  test('index users', () async {
    final response = await client.get('/api/users');

    // By default, we locked this away from the Internet...
    expect(response, hasStatus(HttpStatus.FORBIDDEN));
  });
}
