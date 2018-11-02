import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/http.dart';
import 'package:angel_proxy/angel_proxy.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

final Duration timeout = new Duration(seconds: 5);

main() async {
  var app = new Angel();
  var client = new http.Client();

  // Forward any /api requests to pub.
  // By default, if the host throws a 404, the request will fall through to the next handler.
  var pubProxy = new Proxy(
    client,
    'https://pub.dartlang.org',
    publicPath: '/pub',
    timeout: timeout,
  );
  app.all("/pub/*", pubProxy.handleRequest);

  // Pub's HTML assumes that the site's styles, etc. are on the absolute path `/static`.
  // This is not the case here. Let's patch that up:
  app.get('/static/*', (RequestContext req, res) {
    return pubProxy.servePath(req.path, req, res);
  });

  // Anything else should fall through to dartlang.org.
  var dartlangProxy = new Proxy(
    client,
    'https://dartlang.org',
    timeout: timeout,
    recoverFrom404: false,
  );
  app.all('*', dartlangProxy.handleRequest);

  // In case we can't connect to dartlang.org, show an error.
  app.fallback((req, res) => res.write('Couldn\'t connect to Pub or dartlang.'));

  app.logger = new Logger('angel')
    ..onRecord.listen(
      (rec) {
        print(rec);
        if (rec.error != null) print(rec.error);
        if (rec.stackTrace != null) print(rec.stackTrace);
      },
    );

  var server = await AngelHttp(app).startServer(InternetAddress.loopbackIPv4, 8080);
  print('Listening at http://${server.address.address}:${server.port}');
  print('Check this out! http://${server.address.address}:${server.port}/pub/packages/angel_framework');
}
