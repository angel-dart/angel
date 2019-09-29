import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_static/angel_static.dart';
import 'package:angel_wings/angel_wings.dart';
import 'package:file/local.dart';
import 'package:logging/logging.dart';
import 'package:pretty_logging/pretty_logging.dart';

main() async {
  hierarchicalLoggingEnabled = true;

  var logger = Logger.detached('wings')
    ..level = Level.ALL
    ..onRecord.listen(prettyLog);
  var app = Angel(logger: logger);
  var wings = AngelWings(app);
  var fs = LocalFileSystem();
  var vDir = CachingVirtualDirectory(app, fs,
      source: fs.currentDirectory, allowDirectoryListing: true);

  app.mimeTypeResolver.addExtension('yaml', 'text/x-yaml');

  app.get('/', (req, res) => 'WINGS!!!');
  app.post('/', (req, res) async {
    await req.parseBody();
    return req.bodyAsMap;
  });
  
  app.fallback(vDir.handleRequest);
  app.fallback((req, res) => throw AngelHttpException.notFound());

  await wings.startServer(InternetAddress.loopbackIPv4, 3000);
  print('Listening at ${wings.uri}');
}
