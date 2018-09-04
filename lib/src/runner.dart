import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:angel_container/angel_container.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:io/ansi.dart';
import 'package:io/io.dart';
import 'options.dart';

/// A command-line utility for easier running of multiple instances of an Angel application.
///
/// Makes it easy to do things like configure SSL, log messages, and send messages between
/// all running instances.
class Runner {
  final String name;
  final AngelConfigurer configureServer;
  final Reflector reflector;

  Runner(this.name, this.configureServer,
      {this.reflector: const EmptyReflector()});

  static const String asciiArt = '''
____________   ________________________ 
___    |__  | / /_  ____/__  ____/__  / 
__  /| |_   |/ /_  / __ __  __/  __  /  
_  ___ |  /|  / / /_/ / _  /___  _  /___
/_/  |_/_/ |_/  \____/  /_____/  /_____/
                                        
''';

  static void handleLogRecord(LogRecord record) {
    var code = chooseLogColor(record.level);

    if (record.error == null) print(code.wrap(record.toString()));

    if (record.error != null) {
      var err = record.error;
      if (err is AngelHttpException && err.statusCode != 500) return;
      print(code.wrap(record.toString() + '\n'));
      print(code.wrap(err.toString()));

      if (record.stackTrace != null) {
        print(code.wrap(record.stackTrace.toString()));
      }
    }
  }

  /// Chooses a color based on the logger [level].
  static AnsiCode chooseLogColor(Level level) {
    if (level == Level.SHOUT)
      return backgroundRed;
    else if (level == Level.SEVERE)
      return red;
    else if (level == Level.WARNING)
      return yellow;
    else if (level == Level.INFO)
      return cyan;
    else if (level == Level.FINER || level == Level.FINEST) return lightGray;
    return resetAll;
  }

  /// Spawns a new instance of the application in a separate isolate.
  ///
  /// If the command-line arguments permit, then the instance will be respawned on crashes.
  ///
  /// The returned [Future] completes when the application instance exits.
  ///
  /// If respawning is enabled, the [Future] will *never* complete.
  Future spawnIsolate(RunnerOptions options) {
    return _spawnIsolate(new Completer(), options);
  }

  Future _spawnIsolate(Completer c, RunnerOptions options) {
    var onLogRecord = new ReceivePort();
    var onExit = new ReceivePort();
    var onError = new ReceivePort();
    var runnerArgs = new _RunnerArgs(
        name, configureServer, options, reflector, onLogRecord.sendPort);

    Isolate.spawn(isolateMain, runnerArgs,
            onExit: onExit.sendPort,
            onError: onError.sendPort,
            errorsAreFatal: true && false)
        .then((isolate) {})
        .catchError(c.completeError);

    onLogRecord.listen((msg) => handleLogRecord(msg as LogRecord));

    onError.listen((msg) {
      if (msg is List) {
        var e = msg[0], st = StackTrace.fromString(msg[1].toString());
        handleLogRecord(new LogRecord(
            Level.SEVERE, 'Fatal error', runnerArgs.loggerName, e, st));
      } else {
        handleLogRecord(new LogRecord(
            Level.SEVERE, 'Fatal error', runnerArgs.loggerName, msg));
      }
    });

    onExit.listen((_) {
      if (options.respawn) {
        handleLogRecord(new LogRecord(
            Level.WARNING,
            'Detected a crashed instance at ${new DateTime.now()}. Respawning immediately...',
            runnerArgs.loggerName));
        _spawnIsolate(c, options);
      } else {
        c.complete();
      }
    });

    return c.future
        .whenComplete(onExit.close)
        .whenComplete(onError.close)
        .whenComplete(onLogRecord.close);
  }

  /// Starts a number of isolates, running identical instances of an Angel application.
  Future run(List<String> args) async {
    try {
      var argResults = RunnerOptions.argParser.parse(args);
      var options = new RunnerOptions.fromArgResults(argResults);

      print(darkGray.wrap(asciiArt.trim() +
          '\n\n' +
          "A batteries-included, full-featured, full-stack framework in Dart." +
          '\n\n' +
          'https://angel-dart.github.io\n'));

      if (argResults['help'] == true) {
        stdout..writeln('Options:')..writeln(RunnerOptions.argParser.usage);
        return;
      }

      print('Starting `${name}` application...');
      print('Arguments: $args...\n');

      await Future.wait(
          new List.generate(options.concurrency, (_) => spawnIsolate(options)));
    } on ArgParserException catch (e) {
      stderr
        ..writeln(e.message)
        ..writeln()
        ..writeln('Options:')
        ..writeln(RunnerOptions.argParser.usage);
      exitCode = ExitCode.usage.code;
    } catch (e) {
      stderr..writeln('fatal error: $e');
      exitCode = 1;
    }
  }

  static void isolateMain(_RunnerArgs args) {
    hierarchicalLoggingEnabled = true;

    var zone = Zone.current.fork(specification: new ZoneSpecification(
      print: (self, parent, zone, msg) {
        args.loggingSendPort
            .send(new LogRecord(Level.INFO, msg, args.loggerName));
      },
    ));

    zone.run(() async {
      var app = new Angel(reflector: args.reflector);
      await app.configure(args.configureServer);

      if (app.logger == null) {
        app.logger = new Logger(args.loggerName)
          ..onRecord.listen(Runner.handleLogRecord);
      }

      var http =
          new AngelHttp.custom(app, startShared, useZone: args.options.useZone);
      var server =
          await http.startServer(args.options.hostname, args.options.port);
      var url = new Uri(
          scheme: 'http', host: server.address.address, port: server.port);
      print('Listening at $url');
    });
  }
}

class _RunnerArgs {
  final String name;

  final AngelConfigurer configureServer;

  final RunnerOptions options;

  final Reflector reflector;

  final SendPort loggingSendPort;

  _RunnerArgs(this.name, this.configureServer, this.options, this.reflector,
      this.loggingSendPort);

  String get loggerName => name;
}
