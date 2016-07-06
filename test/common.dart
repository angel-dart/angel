import 'dart:async';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/defs.dart';

class Todo extends MemoryModel {
  String text;
  String when;

  Todo({String this.text, String this.when});
}

Future startTestServer(Angel app) async {
  var host = InternetAddress.LOOPBACK_IP_V4;
  var port = 3000;

  await app.startServer(host, port);
  app.properties["ws_url"] = "ws://${host.address}:$port/ws";
  print("Test server listening on ${host.address}:$port");
}
