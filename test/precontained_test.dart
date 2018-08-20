import 'package:angel_container/mirrors.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:dart2_constant/convert.dart';
import 'package:mock_request/mock_request.dart';
import 'package:test/test.dart';

main() {
  test('preinjects functions', () async {
    var app = new Angel(reflector: MirrorsReflector())
      ..configuration['foo'] = 'bar'
      ..get('/foo', echoAppFoo);
    app.optimizeForProduction(force: true);
    print(app.preContained);
    expect(app.preContained, contains(echoAppFoo));

    var rq = new MockHttpRequest('GET', new Uri(path: '/foo'));
    rq.close();
    await new AngelHttp(app).handleRequest(rq);
    var rs = rq.response;
    var body = await rs.transform(utf8.decoder).join();
    expect(body, json.encode('bar'));
  });
}

echoAppFoo(String foo) => foo;
