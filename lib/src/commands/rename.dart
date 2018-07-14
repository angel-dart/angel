import 'dart:io';
import 'package:analyzer/analyzer.dart';
import 'package:args/command_runner.dart';
import 'package:console/console.dart';
import 'package:dart_style/dart_style.dart';
import 'package:glob/glob.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'pub.dart';

class RenameCommand extends Command {
  @override
  String get name => 'rename';

  @override
  String get description => 'Renames the current project.';

  @override
  String get invocation => '$name <new name>';

  @override
  run() async {
    String newName;

    if (argResults.rest.isNotEmpty)
      newName = argResults.rest.first;
    else {
      var p = new Prompter('Enter new project name: ');
      newName = await p.prompt(checker: (String str) => str.isNotEmpty);
    }

    var ch = new Chooser<String>(['Yes', 'No'],
        message: 'Rename the project to `$newName`? ');
    var choice = await ch.choose();

    if (choice == 'Yes') {
      print('Renaming project to `$newName`...');
      var pubspecFile =
          new File.fromUri(Directory.current.uri.resolve('pubspec.yaml'));

      if (!await pubspecFile.exists()) {
        throw new Exception('No pubspec.yaml found in current directory.');
      } else {
        var pubspec = await Pubspec.load(Directory.current);
        var oldName = pubspec.name;
        await renamePubspec(Directory.current, oldName, newName);
        await renameDartFiles(Directory.current, oldName, newName);
        print('Now running `pub get`...');
        var pubPath = resolvePub();
        print('Pub path: $pubPath');
        var pub = await Process.start(pubPath, ['get']);
        stdout.addStream(pub.stdout);
        stderr.addStream(pub.stderr);
        await pub.exitCode;
      }
    }
  }
}

renamePubspec(Directory dir, String oldName, String newName) async {
  var pubspec = await Pubspec.load(dir);
  var newPubspec = new Pubspec.fromJson(pubspec.toJson()..['name'] = newName);
  await newPubspec.save(dir);
}

renameDartFiles(Directory dir, String oldName, String newName) async {
  // Try to replace MongoDB URL
  var configGlob = new Glob('config/**/*.yaml');

  await for (var yamlFile in configGlob.list(root: dir.absolute.path)) {
    if (yamlFile is File) {
      print('Replacing occurrences of "$oldName" with "$newName" in file "${yamlFile.absolute.path}"...');
      var contents = await yamlFile.readAsString();
      contents = contents.replaceAll(oldName, newName);
      await yamlFile.writeAsString(contents);
    }
  }

  var entry = new File.fromUri(dir.uri.resolve('lib/$oldName.dart'));

  if (await entry.exists()) {
    await entry.rename(dir.uri.resolve('lib/$newName.dart').toFilePath());
    print('Renaming library file `${entry.absolute.path}`...');
  }

  var fmt = new DartFormatter();
  await for (FileSystemEntity file in dir.list(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      var contents = await file.readAsString();
      var ast = parseCompilationUnit(contents);
      var visitor = new RenamingVisitor(oldName, newName)
        ..visitCompilationUnit(ast);

      if (visitor.replace.isNotEmpty) {
        visitor.replace.forEach((range, replacement) {
          if (range.first is int) {
            contents =
                contents.replaceRange(range.first, range.last, replacement);
          } else if (range.first is String) {
            contents = contents.replaceAll(range.first, replacement);
          }
        });

        await file.writeAsString(fmt.format(contents));
        print('Updated file `${file.absolute.path}`.');
      }
    }
  }
}

class RenamingVisitor extends RecursiveAstVisitor {
  final String oldName, newName;
  final Map<List, String> replace = {};

  RenamingVisitor(this.oldName, this.newName);

  String updateUri(String uri) {
    if (uri == 'package:$oldName/$oldName.dart') {
      return 'package:$newName/$newName.dart';
    } else if (uri.startsWith('package:$oldName/')) {
      return 'package:$newName/' + uri.replaceFirst('package:$oldName/', '');
    } else
      return uri;
  }

  @override
  visitExportDirective(ExportDirective ctx) {
    var uri = ctx.uri.stringValue, updated = updateUri(uri);
    if (uri != updated) replace[[uri]] = updated;
  }

  @override
  visitImportDirective(ImportDirective ctx) {
    var uri = ctx.uri.stringValue, updated = updateUri(uri);
    if (uri != updated) replace[[uri]] = updated;
  }

  @override
  visitLibraryDirective(LibraryDirective ctx) {
    var name = ctx.name.name;

    if (name.startsWith(oldName)) {
      replace[[ctx.offset, ctx.end]] =
          'library ' + name.replaceFirst(oldName, newName) + ';';
    }
  }

  @override
  visitPartOfDirective(PartOfDirective ctx) {
    var name = ctx.libraryName.name;

    if (name.startsWith(oldName)) {
      replace[[ctx.offset, ctx.end]] =
          'part of ' + name.replaceFirst(oldName, newName) + ';';
    }
  }
}
