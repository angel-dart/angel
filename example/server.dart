import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:body_parser/body_parser.dart';

main() async {
  var address = InternetAddress.LOOPBACK_IP_V4;
  var port = 3000;
  var futures = <Future>[];

  for (int i = 1; i < Platform.numberOfProcessors; i++) {
    futures.add(Isolate.spawn(start, [address.address, port, i]));
  }

  Future.wait(futures).then((_) {
    print('All instances started.');
    print(
        'Test with "wrk -t12 -c400 -d30s -s ./example/post.lua http://localhost:3000" or similar');
    start([address.address, port, 0]);
  });
}

void start(List args) {
  var address = new InternetAddress(args[0]);
  int port = args[1], id = args[2];

  HttpServer.bind(address, port, shared: true).then((server) {
    server.listen((request) async {
      var body = await parseBody(request);
      request.response
        ..headers.contentType = ContentType.JSON
        ..write(JSON.encode(body.body))
        ..close();
    });

    print(
        'Server #$id listening at http://${server.address.address}:${server.port}');
  });
}
