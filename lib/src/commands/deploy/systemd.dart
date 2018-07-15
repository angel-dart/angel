import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:io/ansi.dart';
import 'package:path/path.dart' as p;
import '../../util.dart';

class SystemdCommand extends Command {
  @override
  String get name => 'systemd';

  @override
  String get description =>
      'Generates a systemd service to continuously run your server.';

  SystemdCommand() {
    argParser
      ..addOption('user',
          abbr: 'u',
          defaultsTo: 'web',
          help: 'The name of the unprivileged account to run the server as.')
      ..addOption('out',
          abbr: 'o',
          help:
              'An optional output file to write to; otherwise prints to stdout.');
  }

  @override
  run() async {
    var projectPath = p.absolute(p.current);
    var pubspec = await loadPubspec();
    var user = argResults['user'];
    var systemdText = '''
[Unit]
Description=`${pubspec.name}` server

[Service]
Environment=ANGEL_ENV=production
User=$user # Name of unprivileged `$user` user
WorkingDirectory=$projectPath # Path to `${pubspec.name}` project
ExecStart=${Platform.resolvedExecutable} bin/prod.dart
Restart=always # Restart process on crash

[Install]
WantedBy=multi-user.target
    '''
        .trim();

    if (!argResults.wasParsed('out')) {
      print(systemdText);
    } else {
      var file = new File(argResults['out'] as String);
      await file.create(recursive: true);
      await file.writeAsString(systemdText);
      print(green.wrap(
          "$checkmark Successfully generated systemd service in '${file.path}'."));
    }
  }
}
