import 'dart:io';
import 'package:angel/angel.dart';

import 'package:angel_container/mirrors.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_hot/angel_hot.dart';
import 'package:lumberjack/lumberjack.dart';
import 'package:lumberjack/io.dart';

main() async {
  // Watch the config/ and web/ directories for changes, and hot-reload the server.
  var hot = HotReloader(() async {
    var app = Angel(reflector: MirrorsReflector());
    await app.configure(configureServer);
    app.logger = Logger('angel')..pipe(AnsiLogPrinter.toStdout());
    app.shutdownHooks.add((_) => app.logger.close());
  }, [
    Directory('config'),
    Directory('lib'),
  ]);

  var server = await hot.startServer('127.0.0.1', 3000);
  print('Listening at http://${server.address.address}:${server.port}');
}
