import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:yaml/yaml.dart';

class StartCommand extends Command {
  @override
  String get name => 'start';

  @override
  String get description =>
      'Runs any `start` scripts, and then runs the server.';

  StartCommand() : super() {
    argParser.addFlag('production',
        help: 'Starts the server in production mode.',
        negatable: false,
        defaultsTo: false);
  }

  @override
  run() async {
    final pubspec = new File('pubspec.yaml');

    if (await pubspec.exists()) {
      // Run start scripts
      final doc = loadYamlDocument(await pubspec.readAsString());
      final scriptsNode = doc.contents['scripts'];

      if (scriptsNode != null && scriptsNode.containsKey('start')) {
        final scripts = scriptsNode['start'] is List
            ? scriptsNode['start']
            : [scriptsNode['start']];

        for (String script in scripts) {
          final split = script.split(' ');
          final result = await Process.run(split.first, split.skip(1).toList(),
              stdoutEncoding: null, stderrEncoding: null);
          final code = result.exitCode;

          stdout.add(result.stdout);
          stderr.add(result.stderr);

          if (code != 0) {
            throw new Exception("Command '$script' exited with code $code.");
          }
        }
      }
    }

    print('Starting server...');

    final env = {};

    if (argResults['production']) env['ANGEL_ENV'] = 'production';

    final server = await Process.start(Platform.executable, ['bin/server.dart'],
        environment: env);
    server.stdout.pipe(stdout);
    server.stderr.pipe(stderr);

    exitCode = await server.exitCode;
  }
}
