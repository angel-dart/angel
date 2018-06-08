/// A basic server that prints "Hello, world!"
library performance.hello;

import 'dart:io';
import 'dart:isolate';

main() {
  for (int i = 0; i < Platform.numberOfProcessors - 1; i++)
    Isolate.spawn(start, i + 1);
  start(0);
}

void start(int id) {
  HttpServer
      .bind('127.0.0.1', 3000, shared: true)
      .then((server) {
    print(
        'Instance #$id listening at http://${server.address.address}:${server.port}');

    server.listen((request) {
      if (request.uri.path == '/') {
        request.response.write('Hello, world!');
      }

      request.response.close();
    });
  });
}
