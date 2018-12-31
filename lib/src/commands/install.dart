import 'dart:async';
import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:glob/glob.dart';
import 'package:io/ansi.dart';
import 'package:mustache4dart/mustache4dart.dart' as mustache;
import 'package:path/path.dart' as p;
import 'package:prompts/prompts.dart' as prompts;
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:yaml/yaml.dart' as yaml;
import '../util.dart';
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
    print(yellow.wrap(
        'WARNING: The `install` command is no longer considered necessary, and has been deprecated.\n'
        'Expect it to be removed in an upcoming release.\n\n'
        'See here: https://github.com/angel-dart/install.git\n\n'
        'To stop seeing this, downgrade to `package:angel_cli@<=2.0.0`.'));

    if (argResults['wipe'] as bool) {
      if (await installRepo.exists()) await installRepo.delete(recursive: true);
    } else if (argResults['list'] as bool) {
      var addons = await list();
      print('${addons.length} add-on(s) installed:');

      for (var addon in addons) {
        print('  * ${addon.name}@${addon.version}: ${addon.description}');
      }
    } else if (argResults['update'] as bool) {
      await update();
    } else if (argResults.rest.isNotEmpty) {
      if (!await installRepo.exists())
        throw 'No local add-on database exists. Run `angel install --update` first.';

      var pubspec = await loadPubspec();

      for (var packageName in argResults.rest) {
        var packageDir =
            new Directory.fromUri(installRepo.uri.resolve(packageName));

        if (!await packageDir.exists())
          throw 'No add-on named "$packageName" is installed. You might need to run `angel install --update`.';
        print('Installing $packageName...');

        Map values = {
          'project_name': pubspec.name,
          'pubspec': pubspec,
        };

        List<Glob> globs = [];

        var projectPubspec = await loadPubspec(packageDir);
        var deps = projectPubspec.dependencies.keys
            .map((k) {
              var dep = projectPubspec.dependencies[k];
              if (dep is HostedDependency)
                return new MakerDependency(k, dep.version.toString());
              return null;
            })
            .where((d) => d != null)
            .toList();

        deps.addAll(projectPubspec.devDependencies.keys.map((k) {
          var dep = projectPubspec.devDependencies[k];
          if (dep is HostedDependency)
            return new MakerDependency(k, dep.version.toString(), dev: true);
          return null;
        }).where((d) => d != null));

        await depend(deps);

        var promptFile =
            new File.fromUri(packageDir.uri.resolve('angel_cli.yaml'));

        if (await promptFile.exists()) {
          var contents = await promptFile.readAsString();
          var y = yaml.loadYamlDocument(contents);
          var cfg = y.contents.value as Map;

          // Loads globs
          if (cfg['templates'] is List) {
            globs.addAll(
                (cfg['templates'] as List).map((p) => new Glob(p.toString())));
          }

          if (cfg['values'] is Map) {
            var val = cfg['values'] as Map;

            for (var key in val.keys) {
              var desc = val[key]['description'] ?? key;

              if (val[key]['type'] == 'prompt') {
                values[key] = prompts.get(desc.toString(),
                    defaultsTo: val[key]['default']?.toString());
              } else if (val[key]['type'] == 'choice') {
                values[key] = prompts.choose(
                    desc.toString(), val[key]['choices'] as Iterable);
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
                allClear = prompts.getBool('Overwrite the existing file?');
                if (allClear) await targetFile.delete();
              }

              if (allClear) {
                try {
                  var path = prefix.isEmpty ? name : '$prefix/$name';

                  if (globs.any((g) => g.matches(path))) {
                    print(
                        'Rendering Mustache template from ${entity.absolute.path} to ${targetFile.absolute.path}...');
                    var contents = await entity.readAsString();
                    var renderer = mustache.compile(contents);
                    var generated = renderer(values);
                    await targetFile.writeAsString(generated.toString());
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

  Future<List<Pubspec>> list() async {
    if (!await installRepo.exists()) {
      throw 'No local add-on database exists. Run `angel install --update` first.';
    } else {
      List<Pubspec> repos = [];

      await for (var entity in installRepo.list()) {
        if (entity is Directory) {
          try {
            repos.add(await loadPubspec(entity));
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
