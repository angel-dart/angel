import 'package:angel_framework/angel_framework.dart';
import 'package:angel_security/angel_security.dart';
import 'package:angel_test/angel_test.dart';
import 'package:test/test.dart';

main() {
  Angel app;
  TestClient client;

  setUp(() async {
    app = new Angel();

    app
        .chain(throttleRequests(1, new Duration(hours: 1)))
        .get('/once-per-hour', 'OK');

    client = await connectTo(app);
  });

  tearDown(() => client.close());

  test('enforce limit', () async {
    // First request within the hour is fine
    var response = await client.get('/once-per-hour');
    print(response.body);
    expect(response.body, contains('OK'));

    // Second request within an hour? No no no!
    response = await client.get('/once-per-hour');
    print(response.body);
    expect(response, hasStatus(429));
  });
}
