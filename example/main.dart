import 'package:angel_framework/angel_framework.dart';
import 'package:angel_seo/angel_seo.dart';
import 'package:angel_static/angel_static.dart';
import 'package:file/local.dart';

main() async {
  var app = new Angel()..lazyParseBodies = true;
  var fs = const LocalFileSystem();
  var http = new AngelHttp(app);

  var vDir = inlineAssets(
    new VirtualDirectory(
      app,
      fs,
      source: fs.directory('web'),
    ),
  );

  app.use(vDir.handleRequest);

  app.use(() => throw new AngelHttpException.notFound());

  var server = await http.startServer('127.0.0.1', 3000);
  print('Listening at http://${server.address.address}:${server.port}');
}
