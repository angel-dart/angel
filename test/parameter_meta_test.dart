import 'dart:async';
import 'dart:convert';

import 'package:angel_container/mirrors.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:mock_request/mock_request.dart';
import 'package:test/test.dart';

Future<String> readResponse(MockHttpResponse rs) {
  return rs.transform(utf8.decoder).join();
}

Future printResponse(MockHttpResponse rs) {
  return readResponse(rs).then((text) {
    print(text.isEmpty ? '<empty response>' : text);
  });
}

void main() {
  group('parameter_meta', parameterMetaTests);
}

parameterMetaTests() {
  Angel app;
  AngelHttp http;

  setUp(() {
    app = new Angel(reflector: MirrorsReflector());
    http = new AngelHttp(app);

    app.get('/cookie', ioc((@CookieValue('token') String jwt) {
      return jwt;
    }));

    app.get('/header', ioc((@Header('x-foo') String header) {
      return header;
    }));

    app.get('/query', ioc((@Query('q') String query) {
      return query;
    }));

    app.get('/session', ioc((@Session('foo') String foo) {
      return foo;
    }));

    app.get('/match', ioc((@Query('mode', match: 'pos') String mode) {
      return 'YES $mode';
    }));

    app.get('/match', ioc((@Query('mode', match: 'neg') String mode) {
      return 'NO $mode';
    }));

    app.get('/match', ioc((@Query('mode') String mode) {
      return 'DEFAULT $mode';
    }));

    /*app.logger = new Logger('parameter_meta_test')
      ..onRecord.listen((rec) {
        print(rec);
        if (rec.error != null) print(rec.error);
        if (rec.stackTrace != null) print(rec.stackTrace);
      });
    */
  });

  test('injects header or throws', () async {
    // Invalid request
    var rq = new MockHttpRequest('GET', Uri.parse('/header'))..close();
    var rs = rq.response;
    http.handleRequest(rq);

    await printResponse(rs);
    expect(rs.statusCode, 400);

    // Valid request
    rq = new MockHttpRequest('GET', Uri.parse('/header'))
      ..headers.add('x-foo', 'bar')
      ..close();
    rs = rq.response;
    await http.handleRequest(rq);

    var body = await readResponse(rs);
    print('Body: $body');
    expect(rs.statusCode, 200);
    expect(body, json.encode('bar'));
  });

  test('injects session or throws', () async {
    // Invalid request
    var rq = new MockHttpRequest('GET', Uri.parse('/session'))..close();
    var rs = rq.response;
    http
        .handleRequest(rq)
        .timeout(const Duration(seconds: 5))
        .catchError((_) => null);

    await printResponse(rs);
    expect(rs.statusCode, 500);

    rq = new MockHttpRequest('GET', Uri.parse('/session'));
    rq.session['foo'] = 'bar';
    rq.close();
    rs = rq.response;
    http.handleRequest(rq);

    await printResponse(rs);
    expect(rs.statusCode, 200);
  });

  // Originally, the plan was to test cookie, session, header, etc.,
  // but that behavior has been consolidated into `getValue`. Thus,
  // they will all function the same way.

  test('pattern matching', () async {
    var rq = new MockHttpRequest('GET', Uri.parse('/match?mode=pos'))..close();
    var rs = rq.response;
    http.handleRequest(rq);
    var body = await readResponse(rs);
    print('Body: $body');
    expect(rs.statusCode, 200);
    expect(body, json.encode('YES pos'));

    rq = new MockHttpRequest('GET', Uri.parse('/match?mode=neg'))..close();
    rs = rq.response;
    http.handleRequest(rq);
    body = await readResponse(rs);
    print('Body: $body');
    expect(rs.statusCode, 200);
    expect(body, json.encode('NO neg'));

    // Fallback
    rq = new MockHttpRequest('GET', Uri.parse('/match?mode=ambi'))..close();
    rs = rq.response;
    http.handleRequest(rq);
    body = await readResponse(rs);
    print('Body: $body');
    expect(rs.statusCode, 200);
    expect(body, json.encode('DEFAULT ambi'));
  });
}
