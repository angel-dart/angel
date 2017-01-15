#!/usr/bin/env dart
/// This is intended to replace Nginx in your web stack.
/// Either use this or another reverse proxy, but there is no real
/// reason to use them together.
library angel.multiserver;

import 'dart:io';
import 'package:angel_compress/angel_compress.dart';
import 'package:angel_multiserver/angel_multiserver.dart';

final Uri cluster = Platform.script.resolve('cluster.dart');

main() async {
  var app = new LoadBalancer();
  // Or, for SSL: 
  // var app = new LoadBalancer.secure('<server-chain>', '<server-key>');

  // Response compression!
  app.responseFinalizers.add(gzip());
  
  // Cache static assets - just to lower response time
  await app.configure(cacheResponses(filters: [new RegExp('images/\.*')]));

  // Start up 5 instances of our main application
  await app.spawnIsolates(cluster, count: 5);

  app.onCrash.listen((_) async {
    // Boot up a new instance on crash
    await app.spawnIsolates(cluster);
  });

  var host = InternetAddress.ANY_IP_V4;
  var port = 3000;
  var server = await app.startServer(host, port);
  print('Listening at http://${server.address.address}:${server.port}');
}
