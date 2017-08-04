import 'dart:io';
import 'package:args/command_runner.dart';
import "package:console/console.dart";
import 'package:dart_style/dart_style.dart';
import 'package:pubspec/pubspec.dart';
import 'package:recase/recase.dart';

class PluginCommand extends Command {
  final TextPen _pen = new TextPen();

  @override
  String get name => "plugin";

  @override
  String get description => "Creates a new plugin within the given project.";

  @override
  run() async {
    var pubspec = await PubSpec.load(Directory.current);
    final name = await readInput("Name of Plugin: "),
        lower = new ReCase(name).snakeCase;
    final testDir = new Directory("lib/src/config/plugins");
    final pluginFile = new File.fromUri(testDir.uri.resolve("$lower.dart"));

    if (!await pluginFile.exists()) await pluginFile.create(recursive: true);

    await pluginFile.writeAsString(
        new DartFormatter().format(_generatePlugin(pubspec, name, lower)));

    _pen.green();
    _pen("${Icon.CHECKMARK} Successfully generated plugin $name.");
    _pen();
  }

  String _generatePlugin(PubSpec pubspec, String name, String lower) {
    return '''
library ${pubspec.name}.config.plugins.$lower;

import 'dart:async';
import 'package:angel_framework/angel_framework.dart';

class $name extends AngelPlugin {
  @override
  Future call(Angel app) async {
    // Work some magic...
  }
}
    '''
        .trim();
  }
}
