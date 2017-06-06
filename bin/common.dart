import 'dart:io';
import 'dart:isolate';
import 'package:angel/angel.dart';
import 'package:angel_diagnostics/angel_diagnostics.dart';
import 'package:angel_hot/angel_hot.dart';
import 'package:intl/intl.dart';

startServer(args, {bool clustered: false, SendPort sendPort}) {
  return () async {
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

    await app.configure(logRequests(logFile));
    HttpServer server;

    // Use `package:angel_hot` in any case, EXCEPT if starting in production mode.
    if (Platform.environment['ANGEL_ENV'] == 'production')
      server = await app.startServer(host, port);
    else {
      var hot = new HotReloader(() async {
        var app = await createServer();
        await app.configure(logRequests(logFile));
        return app;
      }, [new Directory('config'), new Directory('lib')]);
      server = await hot.startServer(host, port);
    }

    if (sendPort == null) {
      print('Listening at http://${server.address.address}:${server.port}');
    } else
      sendPort?.send([server.address.address, server.port]);
  };
}

onError(error, [StackTrace stackTrace]) {
  stderr.writeln("Unhandled error occurred: $error");
  if (stackTrace != null) {
    stderr.writeln(stackTrace);
  }
}
