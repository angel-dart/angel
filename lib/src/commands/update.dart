import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:console/console.dart';
import 'package:http/http.dart' as http;
import 'pubspec.update.g.dart';
import 'pub.dart';

class UpdateCommand extends Command {
  @override
  String get name => 'update';

  @override
  String get description => 'Updates the Angel CLI, if an update is available.';

  @override
  run() async {
    stdout.write('Checking for update... ');

    try {
      var client = new http.Client();
      var update = await checkForUpdate(client);
      client.close();

      if (update != null) {
        stdout.writeln();
        var pen = new TextPen();
        pen.cyan();
        pen.text(
            'ATTENTION: There is a new version of the Angel CLI available (version $update).');
        pen.call();
        var prompt = new Chooser<String>(['Yes', 'No']);
        print('Update now?');
        var choice = await prompt.choose();

        if (choice != 'Yes') {
          pen.reset();
          pen.cyan();
          pen.text(
              'When you are ready to update, run `pub global activate angel_cli`.');
          pen();
          stdout.writeln();
        } else {
          var pubPath = resolvePub();
          print('Running `pub global activate` using $pubPath...');
          var p =
              await Process.start(pubPath, ['global', 'activate', 'angel_cli']);
          p.stderr.listen(stderr.add);
          p.stdout.listen(stdout.add);
          var exitCode = await p.exitCode;

          if (exitCode != 0)
            throw 'Pub terminated with a non-zero exit code.';
          else {
            pen.reset();
            pen.green();
            pen("${Icon.CHECKMARK} Successfully updated the Angel CLI to version $update.\n");
            pen();
          }
        }
      } else
        stdout.writeln('No update available.');
    } catch (e) {
      stdout.writeln('Failed to check for update.');
    }
  }
}
