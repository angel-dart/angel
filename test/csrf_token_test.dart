import 'package:angel_framework/angel_framework.dart';
import 'package:angel_security/angel_security.dart';
import 'package:angel_test/angel_test.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

final RegExp _sessId = RegExp(r'DARTSESSID=([^;]+);');

main() async {
  Angel app;
  TestClient client;

  setUp(() async {
    app = Angel();

    app
      ..chain([verifyCsrfToken()]).get('/valid', (req, res) => 'Valid!')
      ..fallback(setCsrfToken());

    client = await connectTo(app);
  });

  tearDown(() => client.close());

  test('need pre-existing token', () async {
    var response = await client.get('/valid?csrf_token=evil');
    print(response.body);
    expect(response, hasStatus(403));
  });

  test('fake token', () async {
    // Get a valid CSRF, but ignore it.
    var response = await client.get('/');
    var sessionId = getCookie(response);
    response = await client.get(
        Uri(path: '/valid', queryParameters: {'csrf_token': 'evil'}),
        headers: {'cookie': 'DARTSESSID=$sessionId'});
    print(response.body);
    expect(response, hasStatus(400));
    expect(response.body.contains('Valid'), isFalse);
    expect(response.body, contains('Invalid CSRF token'));
  });
}

String getCookie(http.Response response) {
  if (response.headers.containsKey('set-cookie')) {
    var header = response.headers['set-cookie'];
    var match = _sessId.firstMatch(header);
    return match?.group(1);
  } else
    return null;
}
