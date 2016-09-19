import 'dart:async';
import 'dart:io';
import 'package:angel/angel.dart';
import 'package:angel_diagnostics/angel_diagnostics.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:intl/intl.dart';

main() async {
  runZoned(startServer, onError: onError);
}

startServer() async {
  Angel app = await createServer();
  DateFormat dateFormat = new DateFormat("y-MM-dd");
  InternetAddress host = new InternetAddress(app.properties['host']);
  int port = app.properties['port'];
  var now = new DateTime.now();

  await new DiagnosticsServer(app, new File("logs/${dateFormat.format(now)}.txt")).startServer(host, port);
}

onError(error, [StackTrace stackTrace]) {
  stderr.writeln("Unhandled error occurred: $error");
  if (stackTrace != null) {
    stderr.writeln(stackTrace);
  }
}
