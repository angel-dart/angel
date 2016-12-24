#!/usr/bin/env dart
library angel_cli.tool;

import "dart:io";
import "package:args/command_runner.dart";
import 'package:angel_cli/angel_cli.dart';

final String DOCTOR = "doctor";

main(List<String> args) {
  var runner =
      new CommandRunner("angel", "Command-line tools for the Angel framework.");

  runner
    ..addCommand(new DoctorCommand())
    ..addCommand(new KeyCommand())
    ..addCommand(new ServiceCommand())
    ..addCommand(new InitCommand())
    ..addCommand(new TestCommand())
    ..addCommand(new PluginCommand())
    ..addCommand(new StartCommand());

  return runner.run(args).then((_) {}).catchError((exc) {
    stderr.writeln("Oops, something went wrong: $exc");
    exitCode = 1;
  });
}
