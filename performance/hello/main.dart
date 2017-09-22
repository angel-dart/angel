/// A basic server that prints "Hello, world!"
library performance.hello;

import 'dart:io';
import 'dart:isolate';
import 'package:angel_framework/angel_framework.dart';
import 'package:logging/logging.dart';

main() {
  for (int i = 0; i < Platform.numberOfProcessors - 1; i++)
    Isolate.spawn(start, i + 1);
  start(0);
}

void start(int id) {
  var app = new Angel.custom(startShared)
    ..lazyParseBodies = true
    ..get('/', (req, res) => res.write('Hello, world!'))
    ..optimizeForProduction(force: true)
    ..logger = (new Logger('streaming_test')
      ..onRecord.listen((rec) {
        print(rec);
        if (rec.stackTrace != null) print(rec.stackTrace);
      }));

  var oldHandler = app.errorHandler;
  app.errorHandler = (e, req, res) {
    print('Oops: ${e.error ?? e}');
    print(e.stackTrace);
    return oldHandler(e, req, res);
  };
  app.startServer(InternetAddress.LOOPBACK_IP_V4, 3000).then((server) {
    print(
        'Instance #$id listening at http://${server.address.address}:${server.port}');
  });
}
