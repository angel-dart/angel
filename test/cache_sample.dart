import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_static/angel_static.dart';

main() async {
  Angel app;
  Directory testDir = new Directory('test');
  app = new Angel(debug: true);

  await app.configure(new CachingVirtualDirectory(
      source: testDir,
      maxAge: 350,
      onlyInProduction: false,
      // useWeakEtags: false,
      //publicPath: '/virtual',
      indexFileNames: ['index.txt']));

  app.get('*', 'Fallback');

  app.dumpTree(showMatchers: true);

  await app.startServer(InternetAddress.LOOPBACK_IP_V4, 0);
  print('Open at http://${app.httpServer.address.host}:${app.httpServer.port}');
}
