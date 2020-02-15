import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/http.dart';
import 'package:angel_shelf/angel_shelf.dart';
import 'package:logging/logging.dart';
import 'package:pretty_logging/pretty_logging.dart';
import 'package:shelf_static/shelf_static.dart';

main() async {
  Logger.root
    ..level = Level.ALL
    ..onRecord.listen(prettyLog);

  var app = Angel(logger: Logger('angel_shelf_demo'));
  var http = AngelHttp(app);

  // `shelf` request handler
  var shelfHandler = createStaticHandler('.',
      defaultDocument: 'index.html', listDirectories: true);

  // Use `embedShelf` to adapt a `shelf` handler for use within Angel.
  var wrappedHandler = embedShelf(shelfHandler);

  // A normal Angel route.
  app.get('/angel', (req, ResponseContext res) {
    res.write('Hooray for `package:angel_shelf`!');
    return false; // End execution of handlers, so we don't proxy to dartlang.org when we don't need to.
  });

  // Pass any other request through to the static file handler
  app.fallback(wrappedHandler);

  await http.startServer(InternetAddress.loopbackIPv4, 8080);
  print('Running at ${http.uri}');
}
