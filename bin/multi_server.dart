import 'dart:convert';
import 'dart:io';
import 'package:angel_multiserver/angel_multiserver.dart';

final Uri cluster = Platform.script.resolve('cluster.dart');
final error502 = GZIP.encode(UTF8.encode('''
        <!DOCTYPE html>
        <html>
          <head>
            <title>502 Bad Gateway</title>
          </head>
          <body>
            <h1>502 Bad Gateway</h1>
          </body>
        </html>
        '''));
final error503 = GZIP.encode(UTF8.encode('''
        <!DOCTYPE html>
        <html>
          <head>
            <title>503 Service Unavailable</title>
          </head>
          <body>
            <h1>503 Service Unavailable</h1>
            <i>There is no server available to service your request.</i>
          </body>
        </html>
        '''));

main() async {
  var loadBalancer = new LoadBalancer();
  await loadBalancer.spawnIsolates(cluster, count: 3);

  loadBalancer
    ..onCrash.listen((_) {
      // Auto-spawn a new instance on crash
      loadBalancer.spawnIsolates(cluster);
    })
    ..onErrored.listen((socket) async {
       try {
         socket
           ..writeln('HTTP/1.1 502 Bad Gateway')
           ..writeln(HttpDate.format(new DateTime.now()))
           ..writeln('Content-Encoding: gzip')
           ..writeln()
           ..add(error502)
           ..writeln();
      await socket.close();
       } catch(_) {}
    })
    ..onUnavailable.listen((socket) async {
      socket
        ..writeln('HTTP/1.1 503 Service Unavailable')
        ..writeln(HttpDate.format(new DateTime.now()))
        ..writeln('Content-Encoding: gzip')
        ..writeln()
        ..add(error503)
        ..writeln();
      await socket.close();
    });

  var server = await loadBalancer.startServer();
  print(
      'Load balancer listening at http://${server.address.address}:${server.port}');
}
