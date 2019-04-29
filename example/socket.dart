import 'package:angel_wings/angel_wings.dart';

main() async {
  var socket = await WingsSocket.bind('127.0.0.1', 3000);

  await for (var fd in socket) {
    print('FD: $fd');
    closeNativeSocketDescriptor(fd);
  }
}
