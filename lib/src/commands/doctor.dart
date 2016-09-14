import "dart:convert";
import "dart:io";
import "package:args/command_runner.dart";
import "package:console/console.dart";

class DoctorCommand extends Command {
  final TextPen _pen = new TextPen();

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
        var version = await git.stdout.transform(UTF8.decoder).join();
        _pen.green();
        _pen("${Icon.CHECKMARK} Git executable found: v${version.replaceAll('git version', '').trim()}");
        _pen();
      } else
        throw new Exception("Git executable exit code not 0");
    } catch (exc) {
      _pen.red();
      _pen("${Icon.BALLOT_X} Git executable not found");
      _pen();
    }
  }
}
