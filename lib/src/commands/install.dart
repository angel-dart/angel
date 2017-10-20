import 'dart:async';
import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:console/console.dart';
import 'package:glob/glob.dart';
import 'package:homedir/homedir.dart';
import 'package:mustache4dart/mustache4dart.dart' as mustache;
import 'package:path/path.dart' as p;
import 'package:pubspec/pubspec.dart';
import 'package:yaml/yaml.dart' as yaml;
import 'make/maker.dart';

class InstallCommand extends Command {
  static const String repo = 'https://github.com/angel-dart/install.git';
  static final Directory installRepo =
      new Directory.fromUri(homeDir.uri.resolve('./.angel/addons'));

  @override
  String get name => 'install';

  @override
  String get description =>
      'Installs additional add-ons to minimize boilerplate.';

  InstallCommand() {
    argParser
      ..addFlag(
        'list',
        help: 'List all currently-installed add-ons.',
        negatable: false,
        defaultsTo: false,
      )
      ..addFlag(
        'update',
        help: 'Update the local add-on repository.',
        negatable: false,
        defaultsTo: false,
      )
      ..addFlag(
        'wipe',
        help: 'Wipe the local add-on repository.',
        negatable: false,
        defaultsTo: false,
      );
  }

  @override
  run() async {
    if (argResults['wipe']) {
      if (await installRepo.exists()) await installRepo.delete();
    } else if (argResults['list']) {
      var addons = await list();
      print('${addons.length} add-on(s) installed:');

      for (var addon in addons) {
        print('  * ${addon.name}@${addon.version}: ${addon.description}');
      }
    } else if (argResults['update']) {
      await update();
    } else if (argResults.rest.isNotEmpty) {
      if (!await installRepo.exists())
        throw 'No local add-on database exists. Run `angel install --update` first.';

      var pubspec = await PubSpec.load(Directory.current);

      for (var packageName in argResults.rest) {
        var packageDir =
            new Directory.fromUri(installRepo.uri.resolve(packageName));

        if (!await packageDir.exists())
          throw 'No add-on named "$packageName" is installed. You might need to run `angel install --update`.';
        print('Installing $packageName...');

        Map<String, dynamic> values = {
          'project_name': pubspec.name,
          'pubspec': pubspec,
        };

        List<Glob> globs = [];

        var projectPubspec = await PubSpec.load(packageDir);
        var deps = projectPubspec.dependencies.keys
            .map((k) {
          var dep = projectPubspec.dependencies[k];
          if (dep is HostedReference)
            return new MakerDependency(
                k, dep.versionConstraint.toString());
          return null;
        })
            .where((d) => d != null)
            .toList();

        deps.addAll(projectPubspec.devDependencies.keys.map((k) {
          var dep = projectPubspec.devDependencies[k];
          if (dep is HostedReference)
            return new MakerDependency(k, dep.versionConstraint.toString(),
                dev: true);
          return null;
        }).where((d) => d != null));

        await depend(deps);

        var promptFile =
            new File.fromUri(packageDir.uri.resolve('angel_cli.yaml'));

        if (await promptFile.exists()) {
          var contents = await promptFile.readAsString();
          var y = yaml.loadYamlDocument(contents);
          var cfg = y.contents.value as Map<String, dynamic>;

          // Loads globs
          if (cfg['templates'] is List) {
            globs.addAll(cfg['templates'].map((p) => new Glob(p)));
          }

          if (cfg['values'] is Map) {
            var val = cfg['values'] as Map<String, dynamic>;

            for (var key in val.keys) {
              var desc = val[key]['description'] ?? key;

              if (val[key]['type'] == 'prompt') {
                Prompter prompt;

                if (val[key]['default'] != null) {
                  prompt = new Prompter('$desc (${val[key]['default']}): ');
                } else {
                  prompt = new Prompter('$desc: ');
                }

                if (val[key]['default'] != null) {
                  var v = await prompt.prompt();
                  v = v.isNotEmpty ? v : val[key]['default'];
                  values[key] = v;
                } else
                  values[key] =
                      await prompt.prompt(checker: (s) => s.isNotEmpty);
              } else if (val[key]['type'] == 'choice') {
                var chooser =
                    new Chooser(val[key]['choices'], message: '$desc: ');
                values[key] = await chooser.choose();
              }
            }
          }
        }

        Future merge(Directory src, Directory dst, String prefix) async {
          if (!await src.exists()) return;
          print('Copying ${src.absolute.path} into ${dst.absolute.path}...');
          if (!await dst.exists()) await dst.create(recursive: true);

          await for (var entity in src.list()) {
            if (entity is Directory) {
              var name = p.basename(entity.path);
              var newDir = new Directory.fromUri(dst.uri.resolve(name));
              await merge(
                  entity, newDir, prefix.isEmpty ? name : '$prefix/$name');
            } else if (entity is File &&
                !entity.path.endsWith('angel_cli.yaml')) {
              var name = p.basename(entity.path);
              var target = dst.uri.resolve(name);
              var targetFile = new File.fromUri(target);
              bool allClear = !await targetFile.exists();

              if (!allClear) {
                print('The file ${entity.absolute.path} already exists.');
                var p = new Prompter('Overwrite the existing file? [y/N]');
                var answer = await p.prompt(
                    checker: (s) => s.trim() == 'y' || s.trim() == 'N');
                allClear = answer == 'y';
                if (allClear) await targetFile.delete();
              }

              if (allClear) {
                try {
                  var path = prefix.isEmpty ? name : '$prefix/$name';

                  if (globs.any((g) => g.matches(path))) {
                    print('Rendering Mustache template from ${entity.absolute
                        .path} to ${targetFile.absolute.path}...');
                    var contents = await entity.readAsString();
                    var renderer = mustache.compile(contents);
                    var generated = renderer(values);
                    await targetFile.writeAsString(generated);
                  } else {
                    print(
                        'Copying ${entity.absolute.path} to ${targetFile.absolute.path}...');
                    await targetFile.parent.create(recursive: true);
                    await entity.copy(targetFile.absolute.path);
                  }
                } catch (_) {
                  print('Failed to copy.');
                }
              } else {
                print('Skipped ${entity.absolute.path}.');
              }
            }
          }
        }

        await merge(new Directory.fromUri(packageDir.uri.resolve('files')),
            Directory.current, '');
        print('Successfully installed $packageName@${projectPubspec.version}.');
      }
    } else {
      print('No add-ons were specified to be installed.');
    }
  }

  Future<List<PubSpec>> list() async {
    if (!await installRepo.exists()) {
      throw 'No local add-on database exists. Run `angel install --update` first.';
    } else {
      List<PubSpec> repos = [];

      await for (var entity in installRepo.list()) {
        if (entity is Directory) {
          try {
            repos.add(await PubSpec.load(entity));
          } catch (_) {
            // Ignore failures...
          }
        }
      }

      return repos;
    }
  }

  Future update() async {
    Process git;

    if (!await installRepo.exists()) {
      git = await Process.start('git', [
        'clone',
        repo,
        installRepo.absolute.path,
      ]);
    } else {
      git = await Process.start(
        'git',
        [
          'pull',
          'origin',
          'master',
        ],
        workingDirectory: installRepo.absolute.path,
      );
    }

    git..stdout.listen(stdout.add)..stderr.listen(stderr.add);

    var code = await git.exitCode;

    if (code != 0) {
      throw 'git exited with code $code.';
    }
  }
}
