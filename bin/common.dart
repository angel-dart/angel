import 'dart:io';
import 'dart:isolate';
import 'package:angel/angel.dart';
import 'package:angel_diagnostics/angel_diagnostics.dart';
import 'package:intl/intl.dart';

startServer({bool clustered: false}) {
  return (args, [SendPort sendPort]) async {
    var app = await createServer();
    var dateFormat = new DateFormat("y-MM-dd");
    var logFile = new File("logs/${dateFormat.format(new DateTime.now())}.txt");
    InternetAddress host;
    int port;

    if (!clustered) {
      host = new InternetAddress(app.properties['host']);
      port = app.properties['port'];
    } else {
      host = InternetAddress.LOOPBACK_IP_V4;
      port = 0;
    }

    var server =
        await new DiagnosticsServer(app, logFile).startServer(host, port);
    sendPort?.send([server.address.address, server.port]);
  };
}

onError(error, [StackTrace stackTrace]) {
  stderr.writeln("Unhandled error occurred: $error");
  if (stackTrace != null) {
    stderr.writeln(stackTrace);
  }
}
