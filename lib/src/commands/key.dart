import 'dart:convert';
import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:random_string/random_string.dart' as rs;

class KeyCommand extends Command {
  @override
  String get name => 'key';

  @override
  String get description => 'Generates a new `angel_auth`key.';

  @override
  run() async {
    var secret = rs.randomAlphaNumeric(32);
    print('Generated new JWT secret: $secret');
    await changeSecret(new File('config/default.yaml'), secret);
    await changeSecret(new File('config/production.yaml'), secret);
  }

  changeSecret(File file, String secret) async {
    if (await file.exists()) {
      bool foundSecret = false;
      var sink = await file.openWrite();

      await for (var chunk in await file.openRead().transform(UTF8.decoder)) {
        var lines = chunk.split('\n');

        for (String line in lines) {
          if (line.contains('jwt_secret:')) {
            foundSecret = true;
            sink.writeln('jwt_secret: $secret');
          } else
            sink.writeln(line);
        }
      }

      if (!foundSecret) sink.writeln('jwt:secret: $secret');
      await sink.close();
    }
  }
}
