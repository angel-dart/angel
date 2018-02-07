import 'dart:convert';
import 'package:angel_framework/angel_framework.dart';
import 'package:mock_request/mock_request.dart';
import 'package:test/test.dart';

main() {
  test('preinjects functions', () async {
    var app = new Angel()
      ..configuration['foo'] = 'bar'
      ..get('/foo', echoAppFoo);
    app.optimizeForProduction(force: true);
    print(app.preContained);
    expect(app.preContained, contains(echoAppFoo));

    var rq = new MockHttpRequest('GET', new Uri(path: '/foo'));
    rq.close();
    await new AngelHttp(app).handleRequest(rq);
    var rs = rq.response;
    var body = await rs.transform(UTF8.decoder).join();
    expect(body, JSON.encode('bar'));
  });
}

echoAppFoo(String foo) => foo;
