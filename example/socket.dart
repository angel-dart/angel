import 'package:angel_wings/angel_wings.dart';

main() async {
  var socket = await WingsSocket.bind('127.0.0.1', 3000);
  print([socket.port]);
}
