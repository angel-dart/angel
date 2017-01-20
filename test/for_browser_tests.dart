const String SERVER = '''
import 'dart:io';
import "package:angel_framework/angel_framework.dart";
import "package:angel_framework/src/defs.dart";
import 'package:stream_channel/stream_channel.dart';

hybridMain(StreamChannel channel) async {
  var app = new Angel();

  app.before.add((req, ResponseContext res) {
    res.headers["Access-Control-Allow-Origin"] = "*";
    return true;
  });

  app.use("/todos", new MemoryService<Todo>());

  var server = await app.startServer(InternetAddress.LOOPBACK_IP_V4, 0);

  print("Server up; listening at http://localhost:\${server.port}");
  channel.sink.add(server.port);
}

class Todo extends MemoryModel {
  String hello;

  Todo({int id, this.hello}) {
    this.id = id;
  }
}
''';
