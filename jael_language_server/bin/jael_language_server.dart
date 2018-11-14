import 'dart:async';
import 'dart:io';
import 'package:args/args.dart';
import 'package:io/ansi.dart';
import 'package:io/io.dart';
import 'package:dart_language_server/dart_language_server.dart';
import 'package:jael_language_server/jael_language_server.dart';

main(List<String> args) async {
  var argParser = new ArgParser()
    ..addFlag('help',
        abbr: 'h', negatable: false, help: 'Print this help information.')
    ..addOption('log-file', help: 'A path to which to write a log file.');

  void printUsage() {
    print('usage: jael_language_server [options...]\n\nOptions:');
    print(argParser.usage);
  }

  try {
    var argResults = argParser.parse(args);

    if (argResults['help'] as bool) {
      printUsage();
      return;
    } else {
      var jaelServer = new JaelLanguageServer();

      if (argResults.wasParsed('log-file')) {
        var f = new File(argResults['log-file'] as String);
        await f.create(recursive: true);

        jaelServer.logger.onRecord.listen((rec) async {
          var sink = await f.openWrite(mode: FileMode.append);
          sink.writeln(rec);
          if (rec.error != null) sink.writeln(rec.error);
          if (rec.stackTrace != null) sink.writeln(rec.stackTrace);
          await sink.close();
        });
      } else {
        jaelServer.logger.onRecord.listen((rec) async {
          var sink = stderr;
          sink.writeln(rec);
          if (rec.error != null) sink.writeln(rec.error);
          if (rec.stackTrace != null) sink.writeln(rec.stackTrace);
        });
      }

      var spec = new ZoneSpecification(
        handleUncaughtError: (self, parent, zone, error, stackTrace) {
          jaelServer.logger.severe('Uncaught', error, stackTrace);
        },
        print: (self, parent, zone, line) {
          jaelServer.logger.info(line);
        },
      );
      var zone = Zone.current.fork(specification: spec);
      await zone.run(() async {
        var stdio = new StdIOLanguageServer.start(jaelServer);
        await stdio.onDone;
      });
    }
  } on ArgParserException catch (e) {
    print('${red.wrap('error')}: ${e.message}\n');
    printUsage();
    exitCode = ExitCode.usage.code;
  }
}
