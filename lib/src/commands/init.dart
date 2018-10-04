import 'dart:async';
import "dart:io";
import "package:args/command_runner.dart";
import 'package:io/ansi.dart';
import 'package:path/path.dart' as p;
import 'package:prompts/prompts.dart' as prompts;
import '../random_string.dart' as rs;
import '../util.dart';
import 'key.dart';
import 'pub.dart';
import 'rename.dart';

class InitCommand extends Command {
  final KeyCommand _key = new KeyCommand();

  @override
  String get name => "init";

  @override
  String get description =>
      "Initializes a new Angel project in the current directory.";

  InitCommand() {
    argParser..addFlag('pub-get', defaultsTo: true);
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

    print(green.wrap("$checkmark Successfully initialized Angel project."));

    stdout
      ..writeln()
      ..writeln(
          'Congratulations! You are ready to start developing with Angel!')
      ..write('To start the server (with ')
      ..write(cyan.wrap('hot-reloading'))
      ..write('), run ')
      ..write(magenta.wrap('`dart --observe bin/dev.dart`'))
      ..writeln(' in your terminal.')
      ..writeln()
      ..writeln('Find more documentation about Angel:')
      ..writeln('  * https://angel-dart.github.io')
      ..writeln('  * https://github.com/angel-dart/angel/wiki')
      ..writeln(
          '  * https://www.youtube.com/playlist?list=PLl3P3tmiT-frEV50VdH_cIrA2YqIyHkkY')
      ..writeln('  * https://medium.com/the-angel-framework')
      ..writeln('  * https://dart.academy/tag/angel')
      ..writeln()
      ..writeln('Happy coding!');
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
        case FileSystemEntityType.directory:
          return await _deleteRecursive(new Directory(path));
        case FileSystemEntityType.file:
          return await _deleteRecursive(new File(path));
        default:
          break;
      }
    }
  }

  _cloneRepo(Directory projectDir) async {
    try {
      if (await projectDir.exists()) {
        var shouldDelete = prompts.getBool(
            "Directory '${projectDir.absolute.path}' already exists. Overwrite it?");

        if (!shouldDelete)
          throw "Chose not to overwrite existing directory.";
        else if (projectDir.absolute.uri.normalizePath().toFilePath() !=
            Directory.current.absolute.uri.normalizePath().toFilePath())
          await projectDir.delete(recursive: true);
        else {
          await _deleteRecursive(projectDir, false);
        }
      }

      print('Choose a project type before continuing:');

      //var boilerplate = basicBoilerplate;
      var boilerplate = prompts.choose(
          'Choose a project type before continuing', boilerplates);

      print(
          'Cloning "${boilerplate.name}" boilerplate from "${boilerplate.url}"...');
      var git = await Process.start("git",
          ["clone", "--depth", "1", boilerplate.url, projectDir.absolute.path]);

      stdout.addStream(git.stdout);
      stderr.addStream(git.stderr);

      if (await git.exitCode != 0) {
        throw new Exception("Could not clone repo.");
      }

      if (boilerplate.ref != null) {
        git = await Process.start("git", ["checkout", boilerplate.ref]);

        stdout.addStream(git.stdout);
        stderr.addStream(git.stderr);

        if (await git.exitCode != 0) {
          throw new Exception("Could not checkout branch ${boilerplate.ref}.");
        }
      }

      if (boilerplate.needsPrebuild) {
        await preBuild(projectDir).catchError((_) => null);
      }

      var gitDir = new Directory.fromUri(projectDir.uri.resolve(".git"));
      if (await gitDir.exists()) await gitDir.delete(recursive: true);
    } catch (e) {
      if (e is! String) {
        print(red.wrap("$ballot Could not initialize Angel project."));
      }
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

Future preBuild(Directory projectDir) async {
  // Run build
  print('Running `pub run build_runner build`...');

  var build = await Process.start(resolvePub(), ['run', 'build'],
      workingDirectory: projectDir.absolute.path);

  stdout.addStream(build.stdout);
  stderr.addStream(build.stderr);

  var buildCode = await build.exitCode;

  if (buildCode != 0) throw new Exception('Failed to pre-build resources.');
}

const BoilerplateInfo ormBoilerplate = const BoilerplateInfo(
  'ORM',
  "A starting point for applications that use Angel's ORM.",
  'https://github.com/angel-dart/boilerplate_orm.git',
);

const BoilerplateInfo basicBoilerplate = const BoilerplateInfo(
    'Basic',
    'Minimal starting point for Angel 2.x - A simple server with only a few additional packages.',
    'https://github.com/angel-dart/angel.git',
    ref: '2.x');

const BoilerplateInfo legacyBoilerplate = const BoilerplateInfo(
  'Legacy',
  'Minimal starting point for applications running Angel 1.1.x.',
  'https://github.com/angel-dart/angel.git',
  ref: '1.1.x',
);

const List<BoilerplateInfo> boilerplates = const [
  basicBoilerplate,
  legacyBoilerplate,
  //ormBoilerplate,
];

class BoilerplateInfo {
  final String name, description, url, ref;
  final bool needsPrebuild;

  const BoilerplateInfo(this.name, this.description, this.url,
      {this.ref, this.needsPrebuild: false});

  @override
  String toString() => '$name ($description)';
}
