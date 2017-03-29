const String SERVER = '''
import 'dart:io';
import "package:angel_framework/angel_framework.dart";
import "package:angel_framework/common.dart";
import 'package:stream_channel/stream_channel.dart';

hybridMain(StreamChannel channel) async {
  var app = new Angel();

  app.before.add((req, ResponseContext res) {
    res.headers["Access-Control-Allow-Origin"] = "*";
    return true;
  });

  app.use("/todos", new TypedService<Todo>(new MapService()));

  var server = await app.startServer(InternetAddress.LOOPBACK_IP_V4, 0);

  print("Server up; listening at http://localhost:\${server.port}");
  channel.sink.add('http://\${server.address.address}:\${server.port}');
}

class Todo extends Model {
  String hello;

  Todo({int id, this.hello}) {
    this.id = id;
  }
}
''';
