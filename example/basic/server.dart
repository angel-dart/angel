import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:angel_compress/angel_compress.dart';
import 'package:angel_diagnostics/angel_diagnostics.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_hot/angel_hot.dart';
import 'src/foo.dart';

main() async {
  var hot = new HotReloader(createServer, [
    new Directory('src'),
    'server.dart',
    Uri.parse('package:angel_hot/angel_hot.dart')
  ]);
  var server = await hot.startServer(InternetAddress.LOOPBACK_IP_V4, 3000);
  print(
      'Hot server listening at http://${server.address.address}:${server.port}');
}

Future<Angel> createServer() async {
  // Max speed???
  var app = new Angel();

  app.lazyParseBodies = true;
  app.injectSerializer(JSON.encode);

  app.get('/', {'hello': 'hot world!'});
  app.get('/foo', new Foo(bar: 'baz'));

  app.after.add(() => throw new AngelHttpException.notFound());

  app.responseFinalizers.add(gzip());
  //await app.configure(cacheResponses());
  await app.configure(logRequests());
  return app;
}
