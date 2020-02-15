import 'dart:io';
import 'package:args/command_runner.dart';
import '../random_string.dart' as rs;

class KeyCommand extends Command {
  @override
  String get name => 'key';

  @override
  String get description => 'Generates a new `angel_auth` key.';

  @override
  run() async {
    var secret = rs.randomAlphaNumeric(32);
    print('Generated new development JWT secret: $secret');
    await changeSecret(new File('config/default.yaml'), secret);

    secret = rs.randomAlphaNumeric(32);
    print('Generated new production JWT secret: $secret');
    await changeSecret(new File('config/production.yaml'), secret);
  }

  changeSecret(File file, String secret) async {
    if (await file.exists()) {
      var contents = await file.readAsString();
      contents = contents.replaceAll(new RegExp(r'jwt_secret:[^\n]+\n?'), '');
      await file.writeAsString(contents.trim() + '\njwt_secret: "$secret"');
    }
  }
}
