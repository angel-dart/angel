#!/usr/bin/env dart

import 'dart:async';
import 'dart:io';
import 'package:angel/angel.dart';
import 'package:angel_diagnostics/angel_diagnostics.dart';
import 'package:intl/intl.dart';

main() async {
  runZoned(startServer, onError: onError);
}

startServer() async {
  var app = await createServer();
  var dateFormat = new DateFormat("y-MM-dd");
  var logFile = new File("logs/${dateFormat.format(new DateTime.now())}.txt");
  var host = new InternetAddress(app.properties['host']);
  var port = app.properties['port'];

  await new DiagnosticsServer(app, logFile).startServer(host, port);
}

onError(error, [StackTrace stackTrace]) {
  stderr.writeln("Unhandled error occurred: $error");
  if (stackTrace != null) {
    stderr.writeln(stackTrace);
  }
}
