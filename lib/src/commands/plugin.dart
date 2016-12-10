import 'dart:io';
import 'package:args/command_runner.dart';
import "package:console/console.dart";

class PluginCommand extends Command {
  final TextPen _pen = new TextPen();

  @override
  String get name => "plugin";

  @override
  String get description => "Creates a new plugin within the given project.";

  @override
  run() async {
    final name = await readInput("Name of Plugin: "), lower = name.toLowerCase();
    final testDir = new Directory("lib/src/config/plugins");
    final pluginFile = new File.fromUri(
        testDir.uri.resolve("$lower.dart"));

    if (!await pluginFile.exists())
      await pluginFile.create(recursive: true);

    await pluginFile.writeAsString(_generatePlugin(lower));

    _pen.green();
    _pen("${Icon.CHECKMARK} Successfully generated plugin $name.");
    _pen();
  }

  String _generatePlugin(String name) {

    return '''
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
