import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';
import 'package:jael/jael.dart';

var argParser = ArgParser()
  ..addOption('line-length',
      abbr: 'l',
      help: 'The maximum length of a single line. Longer lines will wrap.',
      defaultsTo: '80')
  ..addOption('stdin-name',
      help: 'The filename to print when an error occurs in standard input.',
      defaultsTo: '<stdin>')
  ..addOption('tab-size',
      help: 'The number of spaces to output where a TAB would be inserted.',
      defaultsTo: '2')
  ..addFlag('dry-run',
      abbr: 'n',
      help:
          'Print the names of files that would be changed, without actually overwriting them.',
      negatable: false)
  ..addFlag('help',
      abbr: 'h', help: 'Print this usage information.', negatable: false)
  ..addFlag('insert-spaces',
      help: 'Insert spaces instead of TAB character.', defaultsTo: true)
  ..addFlag('overwrite',
      abbr: 'w',
      help: 'Overwrite input files with formatted output.',
      negatable: false);

main(List<String> args) async {
  try {
    var argResults = argParser.parse(args);
    if (argResults['help'] as bool) {
      stdout..writeln('Formatter for Jael templates.')..writeln();
      printUsage(stdout);
      return;
    }

    if (argResults.rest.isEmpty) {
      var text = await stdin.transform(utf8.decoder).join();
      var result =
          await format(argResults['stdin-name'] as String, text, argResults);
      if (result != null) print(result);
    } else {
      for (var arg in argResults.rest) {
        await formatPath(arg, argResults);
      }
    }
  } on ArgParserException catch (e) {
    stderr..writeln(e.message)..writeln();
    printUsage(stderr);
    exitCode = 65;
  }
}

void printUsage(IOSink sink) {
  sink
    ..writeln('Usage: jaelfmt [options...] [files or directories...]')
    ..writeln()
    ..writeln('Options:')
    ..writeln(argParser.usage);
}

Future<void> formatPath(String path, ArgResults argResults) async {
  var stat = await FileStat.stat(path);
  await formatStat(stat, path, argResults);
}

Future<void> formatStat(
    FileStat stat, String path, ArgResults argResults) async {
  switch (stat.type) {
    case FileSystemEntityType.directory:
      await for (var entity in Directory(path).list()) {
        await formatStat(await entity.stat(), entity.path, argResults);
      }
      break;
    case FileSystemEntityType.file:
      if (path.endsWith('.jael')) await formatFile(File(path), argResults);
      break;
    case FileSystemEntityType.link:
      var link = await Link(path).resolveSymbolicLinks();
      await formatPath(link, argResults);
      break;
    default:
      throw 'No file or directory found at "$path".';
      break;
  }
}

Future<void> formatFile(File file, ArgResults argResults) async {
  var content = await file.readAsString();
  var formatted = await format(file.path, content, argResults);
  if (formatted == null) return;
  if (argResults['overwrite'] as bool) {
    if (formatted != content) {
      if (argResults['dry-run'] as bool) {
        print('Would have formatted ${file.path}');
      } else {
        await file.writeAsStringSync(formatted);
        print('Formatted ${file.path}');
      }
    } else {
      print('Unchanged ${file.path}');
    }
  } else {
    print(formatted);
  }
}

String format(String filename, String content, ArgResults argResults) {
  var errored = false;
  var doc = parseDocument(content, sourceUrl: filename, onError: (e) {
    stderr.writeln(e);
    errored = true;
  });
  if (errored) return null;
  var fmt = JaelFormatter(
      int.parse(argResults['tab-size'] as String),
      argResults['insert-spaces'] as bool,
      int.parse(argResults['line-length'] as String));
  return fmt.apply(doc);
}
