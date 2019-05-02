import 'dart:async';
import 'package:angel_container/mirrors.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/http.dart';
import 'package:mock_request/mock_request.dart';
import 'package:test/test.dart';

final Uri ENDPOINT = Uri.parse('http://example.com/accept');

main() {
  test('no content type', () async {
    var req = await acceptContentTypes();
    expect(req.acceptsAll, isFalse);
    //expect(req.accepts(ContentType.JSON), isFalse);
    expect(req.accepts('application/json'), isFalse);
    //expect(req.accepts(ContentType.HTML), isFalse);
    expect(req.accepts('text/html'), isFalse);
  });

  test('wildcard', () async {
    var req = await acceptContentTypes(['*/*']);
    expect(req.acceptsAll, isTrue);
    //expect(req.accepts(ContentType.JSON), isTrue);
    expect(req.accepts('application/json'), isTrue);
    //expect(req.accepts(ContentType.HTML), isTrue);
    expect(req.accepts('text/html'), isTrue);
  });

  test('specific type', () async {
    var req = await acceptContentTypes(['text/html']);
    expect(req.acceptsAll, isFalse);
    //expect(req.accepts(ContentType.JSON), isFalse);
    expect(req.accepts('application/json'), isFalse);
    //expect(req.accepts(ContentType.HTML), isTrue);
    expect(req.accepts('text/html'), isTrue);
  });

  test('strict', () async {
    var req = await acceptContentTypes(['text/html', "*/*"]);
    expect(req.accepts('text/html'), isTrue);
    //expect(req.accepts(ContentType.HTML), isTrue);
    //expect(req.accepts(ContentType.JSON, strict: true), isFalse);
    expect(req.accepts('application/json', strict: true), isFalse);
  });

  group('disallow null', () {
    RequestContext req;

    setUp(() async {
      req = await acceptContentTypes();
    });

    test('throws error', () {
      expect(() => req.accepts(null), throwsArgumentError);
    });
  });
}

Future<RequestContext> acceptContentTypes(
    [Iterable<String> contentTypes = const []]) {
  var headerString = contentTypes.isEmpty ? null : contentTypes.join(',');
  var rq = MockHttpRequest('GET', ENDPOINT);
  rq.headers.set('accept', headerString);
  rq.close();
  var app = Angel(reflector: MirrorsReflector());
  var http = AngelHttp(app);
  return http.createRequestContext(rq, rq.response);
}
