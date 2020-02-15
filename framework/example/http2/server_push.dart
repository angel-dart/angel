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

  var publicDir = Directory('example/http2/public');
  var indexHtml =
      const LocalFileSystem().file(publicDir.uri.resolve('index.html'));
  var styleCss =
      const LocalFileSystem().file(publicDir.uri.resolve('style.css'));
  var appJs = const LocalFileSystem().file(publicDir.uri.resolve('app.js'));

  // Send files when requested
  app
    ..get('/style.css', (req, res) => res.streamFile(styleCss))
    ..get('/app.js', (req, res) => res.streamFile(appJs));

  app.get('/', (req, res) async {
    // Regardless of whether we pushed other resources, let's still send /index.html.
    await res.streamFile(indexHtml);

    // If the client is HTTP/2 and supports server push, let's
    // send down /style.css and /app.js as well, to improve initial load time.
    if (res is Http2ResponseContext && res.canPush) {
      await res.push('/style.css').streamFile(styleCss);
      await res.push('/app.js').streamFile(appJs);
    }
  });

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
