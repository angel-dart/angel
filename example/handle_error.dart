import 'dart:async';
import 'dart:io';
import 'package:angel_container/mirrors.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:logging/logging.dart';

main() async {
  var app = new Angel(MirrorsReflector())
    ..lazyParseBodies = true
    ..logger = (new Logger('angel')..onRecord.listen(print))
    ..encoders.addAll({'gzip': gzip.encoder});

  app.use(() => new Future.error('Throwing just because I feel like!'));

  var http = new AngelHttp(app);
  var server = await http.startServer('127.0.0.1', 3000);
  var url = 'http://${server.address.address}:${server.port}';
  print('Listening at $url');
}
