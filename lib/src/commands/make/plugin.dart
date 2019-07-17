import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:dart_style/dart_style.dart';
import 'package:io/ansi.dart';
import 'package:prompts/prompts.dart' as prompts;
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:recase/recase.dart';
import '../../util.dart';
import 'maker.dart';

class PluginCommand extends Command {
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
    var pubspec = await loadPubspec();
    String name;
    if (argResults.wasParsed('name')) name = argResults['name'] as String;

    if (name?.isNotEmpty != true) {
      name = prompts.get('Name of plug-in class');
    }

    List<MakerDependency> deps = [
      const MakerDependency('angel_framework', '^2.0.0')
    ];

    var rc = new ReCase(name);
    final pluginDir = new Directory.fromUri(
        Directory.current.uri.resolve(argResults['output-dir'] as String));
    final pluginFile =
        new File.fromUri(pluginDir.uri.resolve("${rc.snakeCase}.dart"));
    if (!await pluginFile.exists()) await pluginFile.create(recursive: true);
    await pluginFile.writeAsString(
        new DartFormatter().format(_generatePlugin(pubspec, rc)));

    if (deps.isNotEmpty) await depend(deps);

    print(green.wrap(
        '$checkmark Successfully generated plug-in file "${pluginFile.absolute.path}".'));
  }

  String _generatePlugin(Pubspec pubspec, ReCase rc) {
    return '''
library ${pubspec.name}.src.config.plugins.${rc.snakeCase};

import 'package:angel_framework/angel_framework.dart';

AngelConfigurer ${rc.camelCase}() {
  return (Angel app) async {
    // Work some magic...
  };
}
    ''';
  }
}
