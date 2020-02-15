import 'dart:async';
import "dart:io";
import "package:args/command_runner.dart";
import 'package:io/ansi.dart';
import 'package:path/path.dart' as p;
import 'package:prompts/prompts.dart' as prompts;
import 'package:recase/recase.dart';
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
    argParser
      ..addFlag('offline',
          help:
              'Disable online fetching of boilerplates. Also disables `pub-get`.',
          negatable: false)
      ..addFlag('pub-get', defaultsTo: true)
      ..addOption('project-name',
          abbr: 'n', help: 'The name for this project.');
  }

  @override
  run() async {
    Directory projectDir =
        new Directory(argResults.rest.isEmpty ? "." : argResults.rest[0]);
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

    var name = argResults.wasParsed('project-name')
        ? argResults['project-name'] as String
        : p.basenameWithoutExtension(
            projectDir.absolute.uri.normalizePath().toFilePath());

    name = ReCase(name).snakeCase;
    print('Renaming project from "angel" to "$name"...');
    await renamePubspec(projectDir, 'angel', name);
    await renameDartFiles(projectDir, 'angel', name);

    if (argResults['pub-get'] != false && argResults['offline'] == false) {
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
    Directory boilerplateDir;

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

      // var boilerplate = basicBoilerplate;
      print('Choose a project type before continuing:');
      var boilerplate = prompts.choose(
          'Choose a project type before continuing', boilerplates);

      // Ultimately, we want a clone of every boilerplate locally on the system.
      var boilerplateRootDir = Directory(p.join(angelDir.path, 'boilerplates'));
      var boilerplateBasename = p.basenameWithoutExtension(boilerplate.url);
      if (boilerplate.ref != null) boilerplateBasename += '.${boilerplate.ref}';
      boilerplateDir =
          Directory(p.join(boilerplateRootDir.path, boilerplateBasename));
      await boilerplateRootDir.create(recursive: true);

      var branch = boilerplate.ref ?? 'master';

      // If there is no clone existing, clone it.
      if (!await boilerplateDir.exists()) {
        if (argResults['offline'] as bool) {
          throw Exception(
              '--offline was selected, but the "${boilerplate.name}" boilerplate has not yet been downloaded.');
        }

        print(
            'Cloning "${boilerplate.name}" boilerplate from "${boilerplate.url}"...');
        Process git;

        if (boilerplate.ref == null) {
          print(darkGray.wrap(
              '\$ git clone --depth 1 ${boilerplate.url} ${boilerplateDir.absolute.path}'));
          git = await Process.start(
            "git",
            [
              "clone",
              "--depth",
              "1",
              boilerplate.url,
              boilerplateDir.absolute.path
            ],
            mode: ProcessStartMode.inheritStdio,
          );
        } else {
          // git clone --single-branch -b branch host:/dir.git
          print(darkGray.wrap(
              '\$ git clone --depth 1 --single-branch -b ${boilerplate.ref} ${boilerplate.url} ${boilerplateDir.absolute.path}'));
          git = await Process.start(
            "git",
            [
              "clone",
              "--depth",
              "1",
              "--single-branch",
              "-b",
              boilerplate.ref,
              boilerplate.url,
              boilerplateDir.absolute.path
            ],
            mode: ProcessStartMode.inheritStdio,
          );
        }

        if (await git.exitCode != 0) {
          throw new Exception("Could not clone repo.");
        }
      }

      // Otherwise, pull from git.
      else if (!(argResults['offline'] as bool)) {
        print(darkGray.wrap('\$ git pull origin $branch'));
        var git = await Process.start("git", ['pull', 'origin', '$branch'],
            mode: ProcessStartMode.inheritStdio,
            workingDirectory: boilerplateDir.absolute.path);
        if (await git.exitCode != 0) {
          print(yellow.wrap(
              "Update of $branch failed. Attempting to continue with existing contents."));
        }
      } else {
        print(darkGray.wrap(
            'Using existing contents of "${boilerplate.name}" boilerplate.'));
      }

      // Next, just copy everything into the given directory.
      await copyDirectory(boilerplateDir, projectDir);

      if (boilerplate.needsPrebuild) {
        await preBuild(projectDir).catchError((_) => null);
      }

      var gitDir = new Directory.fromUri(projectDir.uri.resolve(".git"));
      if (await gitDir.exists()) await gitDir.delete(recursive: true);
    } catch (e) {
      await boilerplateDir.delete(recursive: true).catchError((_) => null);

      if (e is! String) {
        print(red.wrap("$ballot Could not initialize Angel project."));
      }
      rethrow;
    }
  }

  _pubGet(Directory projectDir) async {
    var pubPath = resolvePub();
    print(darkGray.wrap('Running pub at "$pubPath"...'));
    print(darkGray.wrap('\$ $pubPath get'));
    var pub = await Process.start(pubPath, ["get"],
        workingDirectory: projectDir.absolute.path,
        mode: ProcessStartMode.inheritStdio);
    var code = await pub.exitCode;
    print("Pub process exited with code $code");
  }
}

Future preBuild(Directory projectDir) async {
  // Run build
  // print('Running `pub run build_runner build`...');
  print(darkGray.wrap('\$ pub run build_runner build'));

  var build = await Process.start(
      resolvePub(), ['run', 'build_runner', 'build'],
      workingDirectory: projectDir.absolute.path,
      mode: ProcessStartMode.inheritStdio);

  var buildCode = await build.exitCode;

  if (buildCode != 0) throw new Exception('Failed to pre-build resources.');
}

const BoilerplateInfo graphQLBoilerplate = const BoilerplateInfo(
  'GraphQL',
  "A starting point for GraphQL API servers.",
  'https://github.com/angel-dart/angel.git',
  ref: 'graphql',
);

const BoilerplateInfo ormBoilerplate = const BoilerplateInfo(
  'ORM',
  "A starting point for applications that use Angel's ORM.",
  'https://github.com/angel-dart/angel.git',
  ref: 'orm',
);

const BoilerplateInfo basicBoilerplate = const BoilerplateInfo(
    'Basic',
    'Minimal starting point for Angel 2.x - A simple server with only a few additional packages.',
    'https://github.com/angel-dart/angel.git');

const BoilerplateInfo legacyBoilerplate = const BoilerplateInfo(
  'Legacy',
  'Minimal starting point for applications running Angel 1.1.x.',
  'https://github.com/angel-dart/angel.git',
  ref: '1.1.x',
);

const BoilerplateInfo sharedBoilerplate = const BoilerplateInfo(
    'Shared',
    'Holds common models and files shared across multiple Dart projects.',
    'https://github.com/angel-dart/boilerplate_shared.git');

const BoilerplateInfo sharedOrmBoilerplate = const BoilerplateInfo(
  'Shared (ORM)',
  'Holds common models and files shared across multiple Dart projects.',
  'https://github.com/angel-dart/boilerplate_shared.git',
  ref: 'orm',
);

const List<BoilerplateInfo> boilerplates = const [
  basicBoilerplate,
  //legacyBoilerplate,
  ormBoilerplate,
  graphQLBoilerplate,
  sharedBoilerplate,
  sharedOrmBoilerplate,
];

class BoilerplateInfo {
  final String name, description, url, ref;
  final bool needsPrebuild;

  const BoilerplateInfo(this.name, this.description, this.url,
      {this.ref, this.needsPrebuild: false});

  @override
  String toString() => '$name ($description)';
}
