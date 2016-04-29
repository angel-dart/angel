import 'dart:async';
import 'dart:io';
import 'package:angel/angel.dart';
import 'package:angel_framework/angel_framework.dart';

main() async {
  Angel app = await createServer();

  runZoned(() async {
    await app.startServer(
        new InternetAddress(app.properties['host']), app.properties['port']);
    print("Angel server listening on ${app.httpServer.address.host}:${app
        .httpServer.port}");
  }, onError: (error, [StackTrace stackTrace]) {
    stderr.writeln("Unhandled error occurred: $error");
    if (stackTrace != null) {
      stderr.writeln(stackTrace);
    }
  });
}