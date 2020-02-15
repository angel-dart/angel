import 'dart:async';
import 'dart:convert';

import 'package:angel_container/mirrors.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/http.dart';
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
    app = Angel(reflector: MirrorsReflector());
    http = AngelHttp(app);

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

    /*app.logger = Logger('parameter_meta_test')
      ..onRecord.listen((rec) {
        print(rec);
        if (rec.error != null) print(rec.error);
        if (rec.stackTrace != null) print(rec.stackTrace);
      });
    */
  });

  test('injects header or throws', () async {
    // Invalid request
    var rq = MockHttpRequest('GET', Uri.parse('/header'));
    (rq.close());
    var rs = rq.response;
    (http.handleRequest(rq));

    await printResponse(rs);
    expect(rs.statusCode, 400);

    // Valid request
    rq = MockHttpRequest('GET', Uri.parse('/header'))
      ..headers.add('x-foo', 'bar');
    (rq.close());
    rs = rq.response;
    await (http.handleRequest(rq));

    var body = await readResponse(rs);
    print('Body: $body');
    expect(rs.statusCode, 200);
    expect(body, json.encode('bar'));
  });

  test('injects session or throws', () async {
    // Invalid request
    var rq = MockHttpRequest('GET', Uri.parse('/session'));
    (rq.close());
    var rs = rq.response;
    (http
        .handleRequest(rq)
        .timeout(const Duration(seconds: 5))
        .catchError((_) => null));

    await printResponse(rs);
    expect(rs.statusCode, 500);

    rq = MockHttpRequest('GET', Uri.parse('/session'));
    rq.session['foo'] = 'bar';
    (rq.close());
    rs = rq.response;
    (http.handleRequest(rq));

    await printResponse(rs);
    expect(rs.statusCode, 200);
  });

  // Originally, the plan was to test cookie, session, header, etc.,
  // but that behavior has been consolidated into `getValue`. Thus,
  // they will all function the same way.

  test('pattern matching', () async {
    var rq = MockHttpRequest('GET', Uri.parse('/match?mode=pos'));
    (rq.close());
    var rs = rq.response;
    (http.handleRequest(rq));
    var body = await readResponse(rs);
    print('Body: $body');
    expect(rs.statusCode, 200);
    expect(body, json.encode('YES pos'));

    rq = MockHttpRequest('GET', Uri.parse('/match?mode=neg'));
    (rq.close());
    rs = rq.response;
    (http.handleRequest(rq));
    body = await readResponse(rs);
    print('Body: $body');
    expect(rs.statusCode, 200);
    expect(body, json.encode('NO neg'));

    // Fallback
    rq = MockHttpRequest('GET', Uri.parse('/match?mode=ambi'));
    (rq.close());
    rs = rq.response;
    (http.handleRequest(rq));
    body = await readResponse(rs);
    print('Body: $body');
    expect(rs.statusCode, 200);
    expect(body, json.encode('DEFAULT ambi'));
  });
}
