import 'package:angel_framework/angel_framework.dart';
import 'package:angel_security/angel_security.dart';
import 'package:angel_test/angel_test.dart';
import 'package:test/test.dart';

verifyProxy(RequestContext req, ResponseContext res) =>
    req.container.has<ForwardedClient>() ? 'Yep' : 'Nope';

main() {
  Angel app;
  TestClient client;

  setUp(() async {
    app = Angel()
      ..chain([trustProxy('127.*.*.*')]).get('/hello', verifyProxy)
      ..chain([trustProxy('1.2.3.4')]).get('/foo', verifyProxy);
    client = await connectTo(app);
  });

  tearDown(() => client.close());

  test('wildcard', () async {
    var response =
        await client.get('/hello', headers: {'X-Forwarded-Host': 'foo'});
    print(response.body);
    expect(response.body, contains('Yep'));
  });

  test('exclude unknown', () async {
    var response =
        await client.get('/foo', headers: {'X-Forwarded-Host': 'foo'});
    print(response.body);
    expect(response.body, contains('Nope'));
  });
}
