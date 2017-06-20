import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_shelf/angel_shelf.dart';
import 'package:shelf_proxy/shelf_proxy.dart';

main() async {
  var app = new Angel();

  // `shelf` request handler
  var shelfHandler = proxyHandler('https://www.dartlang.org');

  // Use `embedShelf` to adapt a `shelf` handler for use within Angel.
  var angelHandler = embedShelf(shelfHandler);

  // A normal Angel route.
  app.get('/angel', (req, ResponseContext res) {
    res.write('Hooray for `package:angel_shelf`!');
    res.end(); // End execution of handlers, so we don't proxy to dartlang.org when we don't need to.
  });

  // Proxy any other request through to dartlang.org
  app.after.add(angelHandler);

  var server = await app.startServer(InternetAddress.LOOPBACK_IP_V4, 8080);
  print('Proxying at http://${server.address.host}:${server.port}');
}
