import 'package:args/command_runner.dart';
import 'make/controller.dart';
import 'make/migration.dart';
import 'make/model.dart';
import 'make/plugin.dart';
import 'make/service.dart';
import 'make/test.dart';

class MakeCommand extends Command {
  @override
  String get name => 'make';

  @override
  String get description =>
      'Generates common code for your project, such as projects and controllers.';

  MakeCommand() {
    addSubcommand(new ControllerCommand());
    addSubcommand(new MigrationCommand());
    addSubcommand(new ModelCommand());
    addSubcommand(new PluginCommand());
    addSubcommand(new TestCommand());
    addSubcommand(new ServiceCommand());
  }
}
