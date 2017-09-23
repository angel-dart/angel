import 'package:angel_framework/angel_framework.dart';
import 'package:angel_static/angel_static.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';

main() async {
  Angel app;
  Directory testDir = const LocalFileSystem().directory('test');
  app = new Angel();

  app.use(
    new CachingVirtualDirectory(app, const LocalFileSystem(),
        source: testDir,
        maxAge: 350,
        onlyInProduction: false,
        indexFileNames: ['index.txt']).handleRequest,
  );

  app.get('*', 'Fallback');

  app.dumpTree(showMatchers: true);

  var server = await app.startServer();
  print('Open at http://${server.address.host}:${server.port}');
}
