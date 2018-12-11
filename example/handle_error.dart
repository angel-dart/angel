import 'dart:async';
import 'dart:io';
import 'package:angel_container/mirrors.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/http.dart';
import 'package:lumberjack/lumberjack.dart';
import 'package:lumberjack/io.dart';

main() async {
  var app = new Angel(reflector: MirrorsReflector())
    ..logger = (new Logger('angel')..pipe(new AnsiLogPrinter.toStdout()))
    ..encoders.addAll({'gzip': gzip.encoder});

  app.fallback(
      (req, res) => new Future.error('Throwing just because I feel like!'));

  var http = new AngelHttp(app);
  var server = await http.startServer('127.0.0.1', 3000);
  var url = 'http://${server.address.address}:${server.port}';
  print('Listening at $url');
}
