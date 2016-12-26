import 'dart:io';
import 'package:angel_diagnostics/angel_diagnostics.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_test/angel_test.dart';
import 'package:angel_validate/server.dart';
import 'package:test/test.dart';

final Validator echoSchema = new Validator({'message*': isString});

main() {
  Angel app;
  TestClient client;

  setUp(() async {
    app = new Angel();

    app.chain(validate(echoSchema)).post('/echo',
        (RequestContext req, res) async {
      res.write('Hello, ${req.body['message']}!');
    });

    client = await connectTo(new DiagnosticsServer(app, new File('log.txt')));
  });

  tearDown(() async {
    await client.close();
    app = null;
    client = null;
  });

  group('echo', () {
    test('validate', () async {
      var response = await client.post('/echo',
          body: {'message': 'world'}, headers: {HttpHeaders.ACCEPT: '*/*'});
      print('Response: ${response.body}');
      expect(response, hasStatus(HttpStatus.OK));
      expect(response.body, equals('Hello, world!'));
    });

    test('enforce', () async {
      var response = await client.post('/echo',
          body: {'foo': 'bar'}, headers: {HttpHeaders.ACCEPT: '*/*'});
      print('Response: ${response.body}');
      expect(response, hasStatus(HttpStatus.BAD_REQUEST));
    });
  });
}
