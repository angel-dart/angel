import 'dart:convert';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:mock_request/mock_request.dart';
import 'package:test/test.dart';

main() {
  Angel app;

  setUp(() {
    app = new Angel()..inject('global', 305); // Pitbull!

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

    app.fatalErrorStream.listen((e) {
      stderr..writeln(e.error)..writeln(e.stack);
    });
  });

  tearDown(() => app.close());

  test('String type annotation', () async {
    var rq = new MockHttpRequest('GET', Uri.parse('/string/hello'))..close();
    await app.handleRequest(rq);
    var rs = await rq.response.transform(UTF8.decoder).join();
    expect(rs, JSON.encode('hello'));
  });

  test('Primitive after parsed param injection', () async {
    var rq = new MockHttpRequest('GET', Uri.parse('/num/parsed/24'))..close();
    await app.handleRequest(rq);
    var rs = await rq.response.transform(UTF8.decoder).join();
    expect(rs, JSON.encode(24));
  });

  test('globally-injected primitive', () async {
    var rq = new MockHttpRequest('GET', Uri.parse('/num/global'))..close();
    await app.handleRequest(rq);
    var rs = await rq.response.transform(UTF8.decoder).join();
    expect(rs, JSON.encode(305));
  });

  test('unparsed primitive throws error', () async {
    try {
      var rq = new MockHttpRequest('GET', Uri.parse('/num/unparsed/32'))
        ..close();
      var req = await app.createRequestContext(rq);
      var res = await app.createResponseContext(rq.response, req);
      await app.runContained((num unparsed) => unparsed, req, res);
      throw new StateError('ArgumentError should be thrown if a parameter cannot be resolved.');
    } on ArgumentError {
      // Success
    }
  });
}
