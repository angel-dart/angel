import 'dart:async';
import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:watcher/watcher.dart';
import 'package:yaml/yaml.dart';
import 'init.dart';

Process server;
bool watching = false;

class StartCommand extends Command {
  @override
  String get name => 'start';

  @override
  String get description =>
      'Runs any `start` scripts, and then runs the server.';

  StartCommand() : super() {
    argParser
      ..addFlag('multi',
          help: 'Starts bin/multi_server.dart, instead of the standard server.',
          negatable: false,
          defaultsTo: false)
      ..addFlag('production',
          help: 'Starts the server in production mode.',
          negatable: false,
          defaultsTo: false)
      ..addFlag('watch',
          abbr: 'w',
          help: 'Restart the server on file changes.',
          defaultsTo: true);
  }

  @override
  run() async {
    if (argResults['watch']) {
      try {
        new DirectoryWatcher('bin').events.listen((_) async => start());
      } catch (e) {
        // Fail silently...
      }

      try {
        new DirectoryWatcher('config').events.listen((_) async => start());
      } catch (e) {
        // Fail silently...
      }

      try {
        new DirectoryWatcher('lib').events.listen((_) async => start());
      } catch (e) {
        // Fail silently...
      }
    }

    return await start();
  }

  start() async {
    bool isNew = true;
    if (server != null) {
      isNew = false;

      if (!server.kill()) {
        throw new Exception('Could not kill existing server process.');
      }
    }

    final pubspec = new File('pubspec.yaml');

    if (await pubspec.exists()) {
      // Run start scripts
      final doc = loadYamlDocument(await pubspec.readAsString());
      final scriptsNode = doc.contents['scripts'];

      if (scriptsNode != null && scriptsNode.containsKey('start')) {
        try {
          var scripts =
              await Process.start(InitCommand.resolvePub(), ['global', 'run', 'scripts', 'start']);
          listen(scripts.stdout, stdout);
          listen(scripts.stderr, stderr);
          int code = await scripts.exitCode;

          if (code != 0) {
            throw new Exception('`scripts start` failed with exit code $code.');
          }
        } catch (e) {
          // No scripts? No problem...
        }
      }
    }

    if (isNew)
      print('Starting server...');
    else
      print('Changes detected - restarting server...');

    final env = {};

    if (argResults['production']) env['ANGEL_ENV'] = 'production';

    server = await Process.start(
        Platform.executable,
        [
          argResults['multi'] == true
              ? 'bin/multi_server.dart'
              : 'bin/server.dart'
        ],
        environment: env);

    try {
      listen(server.stdout, stdout);
      listen(server.stderr, stderr);
    } catch (e) {
      print(e);
    }

    if (!isNew) {
      print(
          '${new DateTime.now().toIso8601String()}: Successfully restarted server.');
    }

    exitCode = await server.exitCode;
  }
}

void listen(Stream<List<int>> stream, IOSink sink) {
  stream.listen(sink.add);
}
