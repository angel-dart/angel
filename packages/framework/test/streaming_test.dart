import 'dart:async';
import 'dart:convert';
import 'dart:io' show stderr;
import 'dart:io';

import 'package:angel_container/mirrors.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/http.dart';
import 'package:logging/logging.dart';
import 'package:mock_request/mock_request.dart';

import 'package:test/test.dart';

import 'encoders_buffer_test.dart' show encodingTests;

main() {
  Angel app;
  AngelHttp http;

  setUp(() {
    app = Angel(reflector: MirrorsReflector());
    http = AngelHttp(app, useZone: true);

    app.logger = Logger('streaming_test')
      ..onRecord.listen((rec) {
        print(rec);
        if (rec.stackTrace != null) print(rec.stackTrace);
      });

    app.encoders.addAll(
      {
        'deflate': zlib.encoder,
        'gzip': gzip.encoder,
      },
    );

    app.get('/hello', (req, res) {
      return Stream<List<int>>.fromIterable(['Hello, world!'.codeUnits])
          .pipe(res);
    });

    app.get('/write', (req, res) async {
      await res.addStream(
          Stream<List<int>>.fromIterable(['Hello, world!'.codeUnits]));
      res.write('bye');
      await res.close();
    });

    app.get('/multiple', (req, res) async {
      await res.addStream(
          Stream<List<int>>.fromIterable(['Hello, world!'.codeUnits]));
      await res.addStream(Stream<List<int>>.fromIterable(['bye'.codeUnits]));
      await res.close();
    });

    app.get('/overwrite', (req, res) async {
      res.statusCode = 32;
      await Stream<List<int>>.fromIterable(['Hello, world!'.codeUnits])
          .pipe(res);

      var f = Stream<List<int>>.fromIterable(['Hello, world!'.codeUnits])
          .pipe(res)
          .then((_) => false)
          .catchError((_) => true);

      expect(f, completion(true));
    });

    app.get('/error', (req, res) => res.addError(StateError('wtf')));

    app.errorHandler = (e, req, res) async {
      stderr..writeln(e.error)..writeln(e.stackTrace);
    };
  });

  tearDown(() => http.close());

  _expectHelloBye(String path) async {
    var rq = MockHttpRequest('GET', Uri.parse(path));
    (rq.close());
    await http.handleRequest(rq);
    var body = await rq.response.transform(utf8.decoder).join();
    expect(body, 'Hello, world!bye');
  }

  test('write after addStream', () => _expectHelloBye('/write'));

  test('multiple addStream', () => _expectHelloBye('/multiple'));

  test('cannot write after close', () async {
    try {
      var rq = MockHttpRequest('GET', Uri.parse('/overwrite'));
      (rq.close());
      await http.handleRequest(rq);
      var body = await rq.response.transform(utf8.decoder).join();

      if (rq.response.statusCode != 32) {
        throw 'overwrite should throw error; response: $body';
      }
    } on StateError {
      // Success
    }
  });

  test('res => addError', () async {
    try {
      var rq = MockHttpRequest('GET', Uri.parse('/error'));
      (rq.close());
      await http.handleRequest(rq);
      var body = await rq.response.transform(utf8.decoder).join();
      throw 'addError should throw error; response: $body';
    } on StateError {
      // Should throw error...
    }
  });

  encodingTests(() => app);
}
