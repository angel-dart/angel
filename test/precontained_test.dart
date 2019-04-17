import 'dart:convert';

import 'package:angel_container/mirrors.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/http.dart';
import 'package:mock_request/mock_request.dart';
import 'package:pedantic/pedantic.dart';
import 'package:test/test.dart';

main() {
  test('preinjects functions', () async {
    var app = new Angel(reflector: MirrorsReflector())
      ..configuration['foo'] = 'bar'
      ..get('/foo', ioc(echoAppFoo));
    app.optimizeForProduction(force: true);
    print(app.preContained);
    expect(app.preContained.keys, contains(echoAppFoo));

    var rq = new MockHttpRequest('GET', new Uri(path: '/foo'));
    unawaited(rq.close());
    await new AngelHttp(app).handleRequest(rq);
    var rs = rq.response;
    var body = await rs.transform(utf8.decoder).join();
    expect(body, json.encode('bar'));
  }, skip: 'Angel no longer has to preinject functions');
}

echoAppFoo(String foo) => foo;
