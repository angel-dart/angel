#!/usr/bin/env dart
library angel_cli.tool;

import "dart:io";
import "package:args/command_runner.dart";
import 'package:angel_cli/angel_cli.dart';
import 'package:io/ansi.dart';

final String DOCTOR = "doctor";

main(List<String> args) async {
  var runner = new CommandRunner(
      "angel",
      asciiArt.trim() +
          '\n\n' +
          "Command-line tools for the Angel framework." +
          '\n\n' +
          'https://angel-dart.github.io');

  runner.argParser
      .addFlag('verbose', help: 'Print verbose output.', negatable: false);

  runner
    ..addCommand(new DeployCommand())
    ..addCommand(new DoctorCommand())
    ..addCommand(new KeyCommand())
    ..addCommand(new InitCommand())
    ..addCommand(new InstallCommand())
    ..addCommand(new RenameCommand())
    ..addCommand(new MakeCommand());

  return await runner.run(args).catchError((exc, st) {
    if (exc is String) {
      stdout.writeln(exc);
    } else {
      stderr.writeln("Oops, something went wrong: $exc");
      if (args.contains('--verbose')) {
        stderr.writeln(st);
      }
    }

    exitCode = 1;
  }).whenComplete(() {
    stdout.write(resetAll.wrap(''));
  });
}

const String asciiArt = '''
____________   ________________________ 
___    |__  | / /_  ____/__  ____/__  / 
__  /| |_   |/ /_  / __ __  __/  __  /  
_  ___ |  /|  / / /_/ / _  /___  _  /___
/_/  |_/_/ |_/  \____/  /_____/  /_____/
                                        
''';
