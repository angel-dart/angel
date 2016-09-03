import 'dart:io';
import "package:angel_framework/angel_framework.dart";
import "package:angel_framework/defs.dart";

main() async {
  Angel app = new Angel();
  app.before.add((req, ResponseContext res) {
    res.header("Access-Control-Allow-Origin", "*");
  });

  app.use("/todos", new MemoryService<Todo>());

  await app.startServer(InternetAddress.LOOPBACK_IP_V4, 3001);
  print("Server up on localhost:3001");
}

class Todo extends MemoryModel {
  String hello;

  Todo({String this.hello});
}
