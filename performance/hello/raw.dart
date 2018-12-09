/// A basic server that prints "Hello, world!"
library performance.hello;

import 'dart:io';

main() {
  return HttpServer.bind('127.0.0.1', 3000, shared: true).then((server) {
    print('Listening at http://${server.address.address}:${server.port}');

    server.listen((request) {
      if (request.uri.path == '/') {
        request.response.write('Hello, world!');
      }

      request.response.close();
    });
  });
}
