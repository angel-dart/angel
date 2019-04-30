import 'package:angel_framework/angel_framework.dart';
import 'package:angel_static/angel_static.dart';
import 'package:angel_wings/angel_wings.dart';
import 'package:file/local.dart';
import 'package:logging/logging.dart';
import 'pretty_log.dart';

main() async {
  var app = Angel();
  var wings = AngelWings(app);
  var fs = LocalFileSystem();
  var vDir = CachingVirtualDirectory(app, fs,
      source: fs.currentDirectory, allowDirectoryListing: true);

  app.logger = Logger('wings')..onRecord.listen(prettyLog);
  app.mimeTypeResolver.addExtension('yaml', 'text/x-yaml');

  app.get('/', (req, res) => 'WINGS!!!');
  app.fallback(vDir.handleRequest);
  app.fallback((req, res) => throw AngelHttpException.notFound());

  await wings.startServer('127.0.0.1', 3000);
  print('Listening at ${wings.uri}');
}
