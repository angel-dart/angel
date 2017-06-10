#!/usr/bin/env dart

/// Most Angel applications will not need to use the load balancer.
/// Instead, you can start up a multi-threaded cluster.
library angel.scaled_server;

import 'dart:io';
import 'dart:isolate';
import 'package:angel_compress/angel_compress.dart';
import 'package:angel_diagnostics/angel_diagnostics.dart';
import 'package:angel_multiserver/angel_multiserver.dart';
import 'package:angel/angel.dart';

/// The number of isolates to spawn. You might consider starting one instance
/// per processor core on your machine.
final int nInstances = Platform.numberOfProcessors;

main() {
  var startupPort = new ReceivePort();
  List<String> startupMessages = [];

  // Start up multiple instances of our application.
  for (int i = 0; i < nInstances; i++) {
    Isolate.spawn(isolateMain, [i, startupPort.sendPort]);
  }

  int nStarted = 0;

  // Listen for notifications of application startup...
  startupPort.listen((String startupMessage) {
    startupMessages.add(startupMessage);

    if (++nStarted == nInstances) {
      // Keep track of how many instances successfully started up,
      // and print a success message when they all boot.
      startupMessages.forEach(print);
      print('Spawned $nInstances instance(s) of Angel.');
    }
  });
}

void isolateMain(List args) {
  int instanceId = args[0];
  SendPort startupPort = args[1];

  createServer().then((app) async {
    // Response compression via GZIP.
    //
    // See the documentation here:
    // https://github.com/angel-dart/compress
    app.responseFinalizers.add(gzip());

    // Cache static assets - just to lower response time.
    //
    // See the documentation here:
    // https://github.com/angel-dart/multiserver
    //
    // Here is an example of response caching:
    // https://github.com/angel-dart/multiserver/blob/master/example/cache.dart
    await app.configure(cacheResponses(filters: [new RegExp(r'images/\.*')]));

    var server = await app.startServer(
        InternetAddress.ANY_IP_V4, app.properties['port'] ?? 3000);

    // Print request and error information to the console.
    await app.configure(logRequests());

    // Send a notification back to the main isolate
    startupPort.send('Instance #$instanceId listening at http://${server.address.address}:${server.port}');
  });
}
