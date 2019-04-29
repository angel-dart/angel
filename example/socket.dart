import 'dart:convert';
import 'dart:typed_data';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_wings/angel_wings.dart';

main() async {
  var app = Angel();
  var socket = await WingsSocket.bind('127.0.0.1', 3000);
  print('Listening at http://localhost:3000');

  await for (var fd in socket) {
    var response = '''
HTTP/1.1 200 Not Found\r
Date: Fri, 31 Dec 1999 23:59:59 GMT\r
server: wings-test\r\n\r
Nope, nothing's here!
\r\n\r
''';
    var bytes = utf8.encode(response);
    var data = Uint8List.fromList(bytes);
    var rq = await WingsRequestContext.from(app, fd);
    print('Yay: $rq');
    print(rq.headers);
    writeToNativeSocket(fd.fileDescriptor, data);
    closeNativeSocketDescriptor(fd.fileDescriptor);
  }
}
