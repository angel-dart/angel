import 'package:angel_framework/angel_framework.dart';
import 'package:angel_static/angel_static.dart';
import 'package:file/local.dart';

main() async {
  var app = new Angel();
  var fs = const LocalFileSystem();
  var vDir = new VirtualDirectory(
    app,
    fs,
    allowDirectoryListing: true,
    source: fs.directory(fs.currentDirectory),
  );
  app.use(vDir.handleRequest);

  var server = await app.startServer('127.0.0.1', 3000);
  print('Listening at http://${server.address.address}:${server.port}');
}
