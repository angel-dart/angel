import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_user_agent/angel_user_agent.dart';

main() async {
  var app = new Angel()..before.add(parseUserAgent(strict: true));

  app.get(
      '/',
      (UserAgent ua) => ua.isChrome
          ? 'Woohoo! You are running Chrome.'
          : 'Sorry, we only support Google Chrome.');

  var server = await app.startServer(InternetAddress.ANY_IP_V4, 3000);
  print('Listening at http://${server.address.address}:${server.port}');
}
