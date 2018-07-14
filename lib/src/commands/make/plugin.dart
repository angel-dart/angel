import 'dart:io';
import 'package:args/command_runner.dart';
import "package:console/console.dart";
import 'package:dart_style/dart_style.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:recase/recase.dart';
import 'maker.dart';

class PluginCommand extends Command {
  final TextPen _pen = new TextPen();

  @override
  String get name => "plugin";

  @override
  String get description => "Creates a new plug-in within the given project.";

  PluginCommand() {
    argParser
      ..addOption('name',
          abbr: 'n', help: 'Specifies a name for the plug-in class.')
      ..addOption('output-dir',
          help: 'Specifies a directory to create the plug-in class in.',
          defaultsTo: 'lib/src/config/plugins');
  }

  @override
  run() async {
    var pubspec = await Pubspec.load(Directory.current);
    String name;
    if (argResults.wasParsed('name')) name = argResults['name'];

    if (name?.isNotEmpty != true) {
      var p = new Prompter('Name of Controller class: ');
      name = await p.prompt(checker: (s) => s.isNotEmpty);
    }

    List<MakerDependency> deps = [
      const MakerDependency('angel_framework', '^1.0.0')
    ];

    var rc = new ReCase(name);
    final pluginDir = new Directory.fromUri(
        Directory.current.uri.resolve(argResults['output-dir']));
    final pluginFile =
        new File.fromUri(pluginDir.uri.resolve("${rc.snakeCase}.dart"));
    if (!await pluginFile.exists()) await pluginFile.create(recursive: true);
    await pluginFile.writeAsString(
        new DartFormatter().format(_generatePlugin(pubspec, rc)));

    if (deps.isNotEmpty) await depend(deps);

    _pen.green();
    _pen(
        '${Icon.CHECKMARK} Successfully generated plug-in file "${pluginFile.absolute.path}".');
    _pen();
  }

  String _generatePlugin(Pubspec pubspec, ReCase rc) {
    return '''
library ${pubspec.name}.src.config.plugins.${rc.snakeCase};

import 'dart:async';
import 'package:angel_framework/angel_framework.dart';

class ${rc.pascalCase}Plugin extends AngelPlugin {
  @override
  Future call(Angel app) async {
    // Work some magic...
  }
}
    ''';
  }
}
