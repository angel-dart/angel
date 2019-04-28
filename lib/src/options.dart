import 'dart:io';
import 'package:args/args.dart';

class RunnerOptions {
  static final ArgParser argParser = new ArgParser()
    ..addFlag('help',
        abbr: 'h', help: 'Print this help information.', negatable: false)
    ..addFlag('respawn',
        help: 'Automatically respawn crashed application instances.',
        defaultsTo: true,
        negatable: true)
    ..addFlag('use-zone',
        negatable: false, help: 'Create a new Zone for each request.')
    ..addOption('address',
        abbr: 'a', defaultsTo: '127.0.0.1', help: 'The address to listen on.')
    ..addOption('concurrency',
        abbr: 'j',
        defaultsTo: Platform.numberOfProcessors.toString(),
        help: 'The number of isolates to spawn.')
    ..addOption('port',
        abbr: 'p', defaultsTo: '3000', help: 'The port to listen on.');

  final String hostname;
  final int concurrency, port;
  final bool useZone, respawn;

  RunnerOptions(
      {this.hostname = '127.0.0.1',
      this.port = 3000,
      this.concurrency = 1,
      this.useZone = false,
      this.respawn = true});

  factory RunnerOptions.fromArgResults(ArgResults argResults) {
    return new RunnerOptions(
      hostname: argResults['address'] as String,
      port: int.parse(argResults['port'] as String),
      concurrency: int.parse(argResults['concurrency'] as String),
      useZone: argResults['use-zone'] as bool,
      respawn: argResults['respawn'] as bool,
    );
  }
}
