import "dart:io";
import "package:args/command_runner.dart";
import "package:console/console.dart";
import 'package:random_string/random_string.dart' as rs;
import 'package:path/path.dart' as p;
import 'key.dart';
import 'pub.dart';
import 'rename.dart';

class InitCommand extends Command {
  final KeyCommand _key = new KeyCommand();
  final TextPen _pen = new TextPen();

  @override
  String get name => "init";

  @override
  String get description =>
      "Initializes a new Angel project in the current directory.";

  InitCommand() {
    argParser.addFlag('pub-get', defaultsTo: true);
  }

  @override
  run() async {
    Directory projectDir = new Directory(
        argResults.arguments.isEmpty ? "." : argResults.arguments[0]);
    print("Creating new Angel project in ${projectDir.absolute.path}...");
    await _cloneRepo(projectDir);
    // await preBuild(projectDir);
    var secret = rs.randomAlphaNumeric(32);
    print('Generated new development JWT secret: $secret');
    await _key.changeSecret(
        new File.fromUri(projectDir.uri.resolve('config/default.yaml')),
        secret);

    secret = rs.randomAlphaNumeric(32);
    print('Generated new production JWT secret: $secret');
    await _key.changeSecret(
        new File.fromUri(projectDir.uri.resolve('config/production.yaml')),
        secret);

    var name = p.basenameWithoutExtension(
        projectDir.absolute.uri.normalizePath().toFilePath());
    print('Renaming project from "angel" to "$name"...');
    await renamePubspec(projectDir, 'angel', name);
    await renameDartFiles(projectDir, 'angel', name);

    if (argResults['pub-get'] != false) {
      print('Now running pub get...');
      await _pubGet(projectDir);
    }

    _pen.green();
    _pen("${Icon.CHECKMARK} Successfully initialized Angel project.");
    _pen();
    _pen
      ..reset()
      ..text('\nCongratulations! You are ready to start developing with Angel!')
      ..text('\nTo start the server (with file watching), run ')
      ..magenta()
      ..text('`angel start`')
      ..normal()
      ..text(' in your terminal.')
      ..text('\n\nFind more documentation about Angel:')
      ..text('\n  * https://angel-dart.github.io')
      ..text('\n  * https://github.com/angel-dart/angel/wiki')
      ..text(
          '\n  * https://www.youtube.com/playlist?list=PLl3P3tmiT-frEV50VdH_cIrA2YqIyHkkY')
      ..text('\n  * https://medium.com/the-angel-framework')
      ..text('\n  * https://dart.academy/tag/angel')
      ..text('\n\nHappy coding!')
      ..call();
  }

  _deleteRecursive(FileSystemEntity entity, [bool self = true]) async {
    if (entity is Directory) {
      await for (var entity in entity.list(recursive: true)) {
        try {
          await _deleteRecursive(entity);
        } catch (e) {}
      }

      try {
        if (self != false) await entity.delete(recursive: true);
      } catch (e) {}
    } else if (entity is File) {
      try {
        await entity.delete(recursive: true);
      } catch (e) {}
    } else if (entity is Link) {
      var path = await entity.resolveSymbolicLinks();
      var stat = await FileStat.stat(path);

      switch (stat.type) {
        case FileSystemEntityType.DIRECTORY:
          return await _deleteRecursive(new Directory(path));
        case FileSystemEntityType.FILE:
          return await _deleteRecursive(new File(path));
        default:
          break;
      }
    }
  }

  _cloneRepo(Directory projectDir) async {
    try {
      if (await projectDir.exists()) {
        var chooser = new Chooser(["Yes", "No"],
            message:
                "Directory '${projectDir.absolute.path}' already exists. Overwrite it? (Yes/No)");

        if (await chooser.choose() != "Yes")
          throw new Exception("Chose not to overwrite existing directory.");
        else if (projectDir.absolute.uri.normalizePath().toFilePath() !=
            Directory.current.absolute.uri.normalizePath().toFilePath())
          await projectDir.delete(recursive: true);
        else {
          await _deleteRecursive(projectDir, false);
        }
      }

      print('Choose a project type before continuing:');
      var boilerplateChooser = new Chooser<BoilerplateInfo>(ALL_BOILERPLATES);
      var boilerplate = await boilerplateChooser.choose();

      print(
          'Cloning "${boilerplate.name}" boilerplate from "${boilerplate.url}"...');
      var git = await Process.start("git",
          ["clone", "--depth", "1", boilerplate.url, projectDir.absolute.path]);

      stdout.addStream(git.stdout);
      stderr.addStream(git.stderr);

      if (await git.exitCode != 0) {
        throw new Exception("Could not clone repo.");
      }

      var gitDir = new Directory.fromUri(projectDir.uri.resolve(".git"));
      if (await gitDir.exists()) await gitDir.delete(recursive: true);
    } catch (e) {
      print(e);
      _pen.red();
      _pen("${Icon.BALLOT_X} Could not initialize Angel project.");
      _pen();
      rethrow;
    }
  }

  _pubGet(Directory projectDir) async {
    var pubPath = resolvePub();
    print('Running pub at "$pubPath"...');
    var pub = await Process.start(pubPath, ["get"],
        workingDirectory: projectDir.absolute.path);
    stdout.addStream(pub.stdout);
    stderr.addStream(pub.stderr);
    var code = await pub.exitCode;
    print("Pub process exited with code $code");
  }
}

preBuild(Directory projectDir) async {
  // Run build
  print('Pre-building resources...');

  var build = await Process.start(Platform.executable, ['tool/build.dart'],
      workingDirectory: projectDir.absolute.path);

  stdout.addStream(build.stdout);
  stderr.addStream(build.stderr);

  var buildCode = await build.exitCode;

  if (buildCode != 0) throw new Exception('Failed to pre-build resources.');
}

const BoilerplateInfo FULL_APPLICATION_BOILERPLATE = const BoilerplateInfo(
    'Full Application',
    'A complete project including authentication, multi-threading, and more.',
    'https://github.com/angel-dart/angel.git');

const BoilerplateInfo LIGHT_BOILERPLATE = const BoilerplateInfo(
    'Light',
    'Minimal starting point for new users',
    'https://github.com/angel-dart/boilerplate_light.git');

const List<BoilerplateInfo> ALL_BOILERPLATES = const [
  FULL_APPLICATION_BOILERPLATE,
  LIGHT_BOILERPLATE
];

class BoilerplateInfo {
  final String name, description, url;

  const BoilerplateInfo(this.name, this.description, this.url);

  @override
  String toString() => '$name ($description)';
}
