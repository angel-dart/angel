import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_hot/angel_hot.dart';
import 'package:logging/logging.dart';
import 'src/foo.dart';

main() async {
  var hot = new HotReloader(createServer, [
    new Directory('src'),
    new Directory('src'),
    'server.dart',
    Uri.parse('package:angel_hot/angel_hot.dart')
  ]);
  var server = await hot.startServer(InternetAddress.LOOPBACK_IP_V4, 3000);
  print(
      'Hot server listening at http://${server.address.address}:${server.port}');
}

Future<Angel> createServer() async {
  var app = new Angel();

  app.lazyParseBodies = true;
  app.injectSerializer(JSON.encode);

  // Edit this line, and then refresh the page in your browser!
  app.get('/', {'hello': 'hot world!'});
  app.get('/foo', new Foo(bar: 'baz'));

  app.use(() => throw new AngelHttpException.notFound());

  app.injectEncoders({
    'gzip': GZIP.encoder,
    'deflate': ZLIB.encoder,
  });

  app.logger = new Logger('angel')
  ..onRecord.listen((rec) {
    print(rec);
    if (rec.error != null) {
      print(rec.error);
      print(rec.stackTrace);
    }
  });

  return app;
}
