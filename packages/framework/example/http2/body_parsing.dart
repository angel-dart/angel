import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/http.dart';
import 'package:angel_framework/http2.dart';
import 'package:file/local.dart';
import 'package:logging/logging.dart';

main() async {
  var app = Angel();
  app.logger = Logger('angel')
    ..onRecord.listen((rec) {
      print(rec);
      if (rec.error != null) print(rec.error);
      if (rec.stackTrace != null) print(rec.stackTrace);
    });

  var publicDir = Directory('example/public');
  var indexHtml =
      const LocalFileSystem().file(publicDir.uri.resolve('body_parsing.html'));

  app.get('/', (req, res) => res.streamFile(indexHtml));

  app.post('/', (req, res) => req.parseBody().then((_) => req.bodyAsMap));

  var ctx = SecurityContext()
    ..useCertificateChain('dev.pem')
    ..usePrivateKey('dev.key', password: 'dartdart');

  try {
    ctx.setAlpnProtocols(['h2'], true);
  } catch (e, st) {
    app.logger.severe(
        'Cannot set ALPN protocol on server to `h2`. The server will only serve HTTP/1.x.',
        e,
        st);
  }

  var http1 = AngelHttp(app);
  var http2 = AngelHttp2(app, ctx);

  // HTTP/1.x requests will fallback to `AngelHttp`
  http2.onHttp1.listen(http1.handleRequest);

  var server = await http2.startServer('127.0.0.1', 3000);
  print('Listening at https://${server.address.address}:${server.port}');
}
