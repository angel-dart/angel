import 'dart:io';
import 'dart:isolate';
import 'package:angel/angel.dart';
import 'package:angel_diagnostics/angel_diagnostics.dart';
import 'package:angel_hot/angel_hot.dart';
import 'package:intl/intl.dart';

/// Start a single instance of this application.
///
/// If a [sendPort] is provided, then the URL of the mounted server will be sent through the port.
/// Use this if you are starting multiple instances of your server.
startServer(args, {SendPort sendPort}) {
  return () async {
    var app = await createServer();
    var dateFormat = new DateFormat("y-MM-dd");
    var logFile = new File("logs/${dateFormat.format(new DateTime.now())}.txt");
    InternetAddress host;
    int port;

    // Load the right host and port from application config.
    host = new InternetAddress(app.properties['host']);

    // Listen on port 0 if we are using the load balancer.
    port = sendPort != null ? 0 : app.properties['port'];

    // Log requests and errors to a log file.
    await app.configure(logRequests(logFile));
    HttpServer server;

    // Use `package:angel_hot` in any case, EXCEPT if starting in production mode.
    //
    // With hot-reloading, our server will automatically reload in-place on file changes,
    // for a faster development cycle. :)
    if (Platform.environment['ANGEL_ENV'] == 'production')
      server = await app.startServer(host, port);
    else {
      var hot = new HotReloader(() async {
        // If we are hot-reloading, we need to provide a callback
        // to use to start a fresh instance on-the-fly.
        var app = await createServer();
        await app.configure(logRequests(logFile));
        return app;
      },
          // Paths we might want to listen for changes on...
          [
            new Directory('config'),
            new Directory('lib'),
            new Directory('views')
          ]);
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
