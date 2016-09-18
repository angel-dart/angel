import "dart:convert";
import "dart:io";
import "package:args/command_runner.dart";
import "package:console/console.dart";

class InitCommand extends Command {
  final TextPen _pen = new TextPen();

  @override
  String get name => "init";

  @override
  String get description =>
      "Initializes a new Angel project in the current directory.";

  InitCommand() {}

  @override
  run() async {
    Directory projectDir = new Directory(
        argResults.arguments.isEmpty ? "." : argResults.arguments[0]);
    print("Creating new Angel project in ${projectDir.absolute.path}...");
    await _cloneRepo(projectDir);_pen.green();
    _pen("${Icon.CHECKMARK} Successfully initialized Angel project. Now running pub get...");
    _pen();
    await _pubGet();
  }

  _cloneRepo(Directory projectDir) async {
    try {
      if (await projectDir.exists()) {
        var chooser = new Chooser(["Yes", "No"],
            message:
                "Directory '${projectDir.absolute.path}' exists. Overwrite it? (Yes/No)");

        if (await chooser.choose() != "Yes")
          throw new Exception("Chose not to overwrite existing directory.");
        await projectDir.delete(recursive: true);
      }

      var git = await Process.start("git", [
        "clone",
        "--depth",
        "1",
        "https://github.com/angel-dart/angel",
        projectDir.absolute.path
      ]);

      git.stdout.transform(UTF8.decoder).listen(stdout.write);
      git.stderr.transform(UTF8.decoder).listen(stderr.write);

      if (await git.exitCode != 0) {
        throw new Exception("Could not clone repo.");
      }

      var gitDir = new Directory.fromUri(projectDir.uri.resolve(".git"));

      if (await gitDir.exists())
        await gitDir.delete(recursive: true);
    } catch (e) {
      print(e);
      _pen.red();
      _pen("${Icon.BALLOT_X} Could not initialize Angel project.");
      _pen();
      rethrow;
    }
  }

  _pubGet() async {
    var pub = await Process.start("pub", ["get"]);
    pub.stdout.pipe(stdout);
    pub.stderr.pipe(stderr);
    var code = await pub.exitCode;
    print("Pub process exited with code $code");
  }
}
