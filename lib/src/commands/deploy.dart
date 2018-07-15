import 'package:args/command_runner.dart';
import 'deploy/nginx.dart';
import 'deploy/systemd.dart';

class DeployCommand extends Command {
  @override
  String get name => 'deploy';

  @override
  String get description =>
      'Generates scaffolding + helper functionality for deploying servers. Run this in your project root.';

  DeployCommand() {
    addSubcommand(new NginxCommand());
    addSubcommand(new SystemdCommand());
  }
}
