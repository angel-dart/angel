import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/http.dart';
import 'package:angel_shelf/angel_shelf.dart';
import 'package:shelf_static/shelf_static.dart';

main() async {
  var app = new Angel();
  var http = new AngelHttp(app);

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

  // Proxy any other request through to the static file handler
  app.fallback(wrappedHandler);

  await http.startServer(InternetAddress.loopbackIPv4, 8080);
  print('Proxying at ${http.uri}');
}
