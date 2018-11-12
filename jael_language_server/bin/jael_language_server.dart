import 'dart:io';
import 'package:args/args.dart';
import 'package:io/ansi.dart';
import 'package:io/io.dart';
import 'package:dart_language_server/dart_language_server.dart';
import 'package:jael_language_server/jael_language_server.dart';

main(List<String> args) async {
  var argParser = new ArgParser()
    ..addFlag('help',
        abbr: 'h', negatable: false, help: 'Print this help information.');

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

      jaelServer.logger.onRecord.listen((rec) async {
        // TODO: Remove this
        var f = new File(
            '/Users/thosakwe/Source/Angel/vscode/jael_language_server/.dart_tool/log.txt');
        await f.create(recursive: true);
        var sink = await f.openWrite(mode: FileMode.append);
        sink.writeln(rec);
        if (rec.error != null) sink.writeln(rec.error);
        if (rec.stackTrace != null) sink.writeln(rec.stackTrace);
        await sink.close();
      });

      var stdio = new StdIOLanguageServer.start(jaelServer);
      await stdio.onDone;
    }
  } on ArgParserException catch (e) {
    print('${red.wrap('error')}: ${e.message}\n');
    printUsage();
    exitCode = ExitCode.usage.code;
  }
}
