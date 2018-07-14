import "dart:convert";
import "dart:io";
import "package:args/command_runner.dart";
import 'package:io/ansi.dart';
import '../util.dart';

class DoctorCommand extends Command {
  @override
  String get name => "doctor";

  @override
  String get description =>
      "Ensures that the current system is capable of running Angel.";

  @override
  run() async {
    print("Checking your system for dependencies...");
    await _checkForGit();
  }

  _checkForGit() async {
    try {
      var git = await Process.start("git", ["--version"]);
      if (await git.exitCode == 0) {
        var version = await git.stdout.transform(utf8.decoder).join();
        print(green.wrap(
            "$checkmark Git executable found: v${version.replaceAll('git version', '').trim()}"));
      } else
        throw new Exception("Git executable exit code not 0");
    } catch (exc) {
      print(red.wrap("$ballot Git executable not found"));
    }
  }
}
