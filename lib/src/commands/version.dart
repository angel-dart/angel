import 'package:args/command_runner.dart';
import 'pubspec.update.g.dart';

class VersionCommand extends Command {
  @override
  String get name => 'version';

  @override
  String get description => 'Prints the currently-installed version of the Angel CLI.';

  @override
  run() => print('Angel CLI version $PACKAGE_VERSION');
}