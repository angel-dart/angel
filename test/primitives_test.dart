import 'dart:io' show stderr;
import 'package:angel_framework/angel_framework.dart';
import 'package:dart2_constant/convert.dart';
import 'package:mock_request/mock_request.dart';
import 'package:test/test.dart';

main() {
  Angel app;
  AngelHttp http;

  setUp(() {
    app = new Angel()..inject('global', 305); // Pitbull!
    http = new AngelHttp(app);

    app.get('/string/:string', (String string) => string);

    app.get(
        '/num/parsed/:num',
        waterfall([
          (RequestContext req) {
            req.params['n'] = num.parse(req.params['num']);
            return true;
          },
          (num n) => n,
        ]));

    app.get('/num/global', (num global) => global);

    app.errorHandler = (e, req, res) {
      stderr..writeln(e.error)..writeln(e.stackTrace);
    };
  });

  tearDown(() => app.close());

  test('String type annotation', () async {
    var rq = new MockHttpRequest('GET', Uri.parse('/string/hello'))..close();
    await http.handleRequest(rq);
    var rs = await rq.response.transform(utf8.decoder).join();
    expect(rs, json.encode('hello'));
  });

  test('Primitive after parsed param injection', () async {
    var rq = new MockHttpRequest('GET', Uri.parse('/num/parsed/24'))..close();
    await http.handleRequest(rq);
    var rs = await rq.response.transform(utf8.decoder).join();
    expect(rs, json.encode(24));
  });

  test('globally-injected primitive', () async {
    var rq = new MockHttpRequest('GET', Uri.parse('/num/global'))..close();
    await http.handleRequest(rq);
    var rs = await rq.response.transform(utf8.decoder).join();
    expect(rs, json.encode(305));
  });

  test('unparsed primitive throws error', () async {
    try {
      var rq = new MockHttpRequest('GET', Uri.parse('/num/unparsed/32'))
        ..close();
      var req = await http.createRequestContext(rq);
      var res = await http.createResponseContext(rq.response, req);
      await app.runContained((num unparsed) => unparsed, req, res);
      throw new StateError(
          'ArgumentError should be thrown if a parameter cannot be resolved.');
    } on ArgumentError {
      // Success
    }
  });
}
