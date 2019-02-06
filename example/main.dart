import 'dart:isolate';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_hot/angel_hot.dart';

main(_, [SendPort sendPort]) {
  return runHot(sendPort, (client) {
    var app = Angel();

    if (client != null) {
      // Specify which paths to listen to.
      client.watchPaths([
        'src',
        'main.dart',
        'package:angel_hot/angel_hot.dart',
      ]);

      // When the top-level triggers a hot reload, shut down the existing server.
      client.onReload.listen((reload) {

      });
    }
  });
}
