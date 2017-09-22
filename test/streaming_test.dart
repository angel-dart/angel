import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:mock_request/mock_request.dart';
import 'package:test/test.dart';
import 'encoders_buffer_test.dart' show encodingTests;

main() {
  Angel app;

  setUp(() {
    app = new Angel();
    app.injectEncoders(
      {
        'deflate': ZLIB.encoder,
        'gzip': GZIP.encoder,
      },
    );

    app.get('/hello', (res) {
      new Stream<List<int>>.fromIterable(['Hello, world!'.codeUnits]).pipe(res);
    });

    app.get('/write', (res) async {
      await res.addStream(
          new Stream<List<int>>.fromIterable(['Hello, world!'.codeUnits]));
      res.write('bye');
      await res.close();
    });

    app.get('/multiple', (res) async {
      await res.addStream(
          new Stream<List<int>>.fromIterable(['Hello, world!'.codeUnits]));
      await res
          .addStream(new Stream<List<int>>.fromIterable(['bye'.codeUnits]));
      await res.close();
    });

    app.get('/overwrite', (res) async {
      res.statusCode = 32;
      await new Stream<List<int>>.fromIterable(['Hello, world!'.codeUnits])
          .pipe(res);

      try {
        await new Stream<List<int>>.fromIterable(['Hello, world!'.codeUnits])
            .pipe(res);
        throw new Exception('Should throw on rewrite...');
      } on StateError {
        // Yay!!!
      }
    });

    app.get('/error', (res) => res.addError(new StateError('wtf')));

    app.errorHandler = (e, req, res) async {
      stderr..writeln(e.error)..writeln(e.stackTrace);
    };
  });

  tearDown(() => app.close());

  _expectHelloBye(String path) async {
    var rq = new MockHttpRequest('GET', Uri.parse(path))..close();
    await app.handleRequest(rq);
    var body = await rq.response.transform(UTF8.decoder).join();
    expect(body, 'Hello, world!bye');
  }

  test('write after addStream', () => _expectHelloBye('/write'));

  test('multiple addStream', () => _expectHelloBye('/multiple'));

  test('cannot write after close', () async {
    var rq = new MockHttpRequest('GET', Uri.parse('/overwrite'))..close();
    await app.handleRequest(rq);
    var body = await rq.response.transform(UTF8.decoder).join();

    if (rq.response.statusCode != 32)
      throw 'overwrite should throw error; response: $body';
  });

  test('res => addError', () async {
    try {
      var rq = new MockHttpRequest('GET', Uri.parse('/error'))..close();
      await app.handleRequest(rq);
      var body = await rq.response.transform(UTF8.decoder).join();
      throw 'addError should throw error; response: $body';
    } on StateError {
      // Should throw error...
    }
  });

  encodingTests(() => app);
}
