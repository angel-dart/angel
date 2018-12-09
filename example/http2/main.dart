import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/http.dart';
import 'package:angel_framework/http2.dart';
import 'package:logging/logging.dart';
import 'pretty_logging.dart';

main() async {
  var app = new Angel()
    ..encoders.addAll({
      'gzip': gzip.encoder,
      'deflate': zlib.encoder,
    });
  app.logger = new Logger('angel')..onRecord.listen(prettyLog);

  app.get('/', (req, res) => 'Hello HTTP/2!!!');

  app.fallback((req, res) => throw new AngelHttpException.notFound(
      message: 'No file exists at ${req.uri}'));

  var ctx = new SecurityContext()
    ..useCertificateChain('dev.pem')
    ..usePrivateKey('dev.key', password: 'dartdart');

  try {
    ctx.setAlpnProtocols(['h2'], true);
  } catch (e, st) {
    app.logger.severe(
      'Cannot set ALPN protocol on server to `h2`. The server will only serve HTTP/1.x.',
      e,
      st,
    );
  }

  var http1 = new AngelHttp(app);
  var http2 = new AngelHttp2(app, ctx);

  // HTTP/1.x requests will fallback to `AngelHttp`
  http2.onHttp1.listen(http1.handleRequest);

  await http2.startServer('127.0.0.1', 3000);
  print('Listening at ${http2.uri}');
}
