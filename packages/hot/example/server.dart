import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:logging/logging.dart';
import 'src/foo.dart';

Future<Angel> createServer() async {
  var app = Angel()..serializer = json.encode;
  hierarchicalLoggingEnabled = true;

  // Edit this line, and then refresh the page in your browser!
  app.get('/', (req, res) => {'hello': 'hot world!'});
  app.get('/foo', (req, res) => Foo(bar: 'baz'));

  app.fallback((req, res) => throw AngelHttpException.notFound());

  app.encoders.addAll({
    'gzip': gzip.encoder,
    'deflate': zlib.encoder,
  });

  app.logger = Logger.detached('angel')
    ..onRecord.listen((rec) {
      print(rec);
      if (rec.error != null) {
        print(rec.error);
        print(rec.stackTrace);
      }
    });

  return app;
}
