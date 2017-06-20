import 'dart:io';
import 'package:angel_diagnostics/angel_diagnostics.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_proxy/angel_proxy.dart';

final Duration TIMEOUT = new Duration(seconds: 5);

main() async {
  var app = new Angel();

  // Forward any /api requests to pub.
  // By default, if the host throws a 404, the request will fall through to the next handler.
  var pubProxy = new ProxyLayer('pub.dartlang.org', 80,
      publicPath: '/pub', timeout: TIMEOUT);
  await app.configure(pubProxy);

  // Pub's HTML assumes that the site's styles, etc. are on the absolute path `/static`.
  // This is not the case here. Let's patch that up:
  app.get('/static/*', (RequestContext req, res) {
    return pubProxy.serveFile(req.path, req, res);
  });

  // Anything else should fall through to dartlang.org.
  await app.configure(new ProxyLayer('dartlang.org', 80, timeout: TIMEOUT));

  // In case we can't connect to dartlang.org, show an error.
  app.after.add('Couldn\'t connect to Pub or dartlang.');

  await app.configure(logRequests());

  app.fatalErrorStream.listen((AngelFatalError e) {
    print(e.error);
    print(e.stack);
  });

  var server = await app.startServer(InternetAddress.LOOPBACK_IP_V4, 8080);
  print('Listening at http://${server.address.address}:${server.port}');
}
