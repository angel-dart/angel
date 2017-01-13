import 'package:angel_framework/angel_framework.dart';
import 'package:angel_security/angel_security.dart';
import 'package:angel_test/angel_test.dart';
import 'package:test/test.dart';

main() {
  Angel app;
  TestClient client;

  setUp(() async {
    app = new Angel()..chain(banIp('*.*.*.*')).get('/ban', 'WTF');

    client = await connectTo(app);
  });

  tearDown(() => client.close());

  test('ban everyone', () async {
    var response = await client.get('/ban');
    print(response.body);
    expect(response, hasStatus(403));
    expect(response.body.contains('WTF'), isFalse);
  });
}
