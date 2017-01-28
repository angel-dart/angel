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

    app
        .chain(throttleRequests(3, new Duration(minutes: 1)))
        .get('/thrice-per-minute', 'OK');

    client = await connectTo(app);
  });

  tearDown(() => client.close());

  test('once per hour', () async {
    // First request within the hour is fine
    var response = await client.get('/once-per-hour');
    print(response.body);
    expect(response.body, contains('OK'));

    // Second request within an hour? No no no!
    response = await client.get('/once-per-hour');
    print(response.body);
    expect(response, hasStatus(429));
  });

  test('thrice per minute', () async {
    // First request within the minute is fine
    var response = await client.get('/thrice-per-minute');
    print(response.body);
    expect(response.body, contains('OK'));


    // Second request within the minute is fine
    response = await client.get('/thrice-per-minute');
    print(response.body);
    expect(response.body, contains('OK'));


    // Third request within the minute is fine
    response = await client.get('/thrice-per-minute');
    print(response.body);
    expect(response.body, contains('OK'));

    // Fourth request within a minute? No no no!
    response = await client.get('/thrice-per-minute');
    print(response.body);
    expect(response, hasStatus(429));
  });
}
