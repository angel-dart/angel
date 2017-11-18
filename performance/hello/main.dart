/// A basic server that prints "Hello, world!"
library performance.hello;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/metrics.dart';

main() {
  for (int i = 0; i < Platform.numberOfProcessors; i++) {
    Isolate.spawn(start, i + 1);
  }

  start(0);
}

void start(int id) {
  var app = new AngelMetrics.custom(startShared)
    ..lazyParseBodies = true
    ..get('/', (req, res) => res.write('Hello, world!'));

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
