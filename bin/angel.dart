#!/usr/bin/env dart
library demon.tool;

import "dart:io";
import "package:args/command_runner.dart";
import 'package:angel_cli/angel_cli.dart';
import 'package:angel_cli/pubspec.update.g.dart';
import 'package:console/console.dart';
import 'package:http/http.dart' as http;

final String DOCTOR = "doctor";

main(List<String> args) async {
  var runner =
      new CommandRunner("angel", "Command-line tools for the Angel framework.");

  runner
    ..addCommand(new DoctorCommand())
    ..addCommand(new KeyCommand())
    ..addCommand(new ServiceCommand())
    ..addCommand(new InitCommand())
    ..addCommand(new TestCommand())
    ..addCommand(new PluginCommand())
    ..addCommand(new StartCommand())
    ..addCommand(new RenameCommand());

  stdout.write('Checking for update... ');
  var client = new http.Client();
  var update = await checkForUpdate(client);
  client.close();

  if (update != null) {
    stdout.writeln();
    var pen = new TextPen();
    pen.cyan();
    pen.text(
        'ATTENTION: There is a new version of the Angel CLI available (version $update).');
    pen.text('\nTo update, run `pub global activate angel_cli`.');
    pen();
    stdout.writeln();
  } else
    stdout.writeln('No update available.');

  return await runner.run(args).then((_) {}).catchError((exc) {
    stderr.writeln("Oops, something went wrong: $exc");
    exitCode = 1;
  });
}
