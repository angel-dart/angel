import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:io/ansi.dart';
import 'package:prompts/prompts.dart' as prompts;
import 'package:recase/recase.dart';
import '../../util.dart';
import 'maker.dart';

class ModelCommand extends Command {
  @override
  String get name => 'model';

  @override
  String get description => 'Generates a model class.';

  ModelCommand() {
    argParser
      ..addFlag('migration',
          abbr: 'm',
          help: 'Generate migrations when running `build_runner`.',
          defaultsTo: true)
      ..addFlag('orm', help: 'Generate angel_orm code.', negatable: false)
      ..addFlag('serializable',
          help: 'Generate angel_serialize annotations.', defaultsTo: true)
      ..addOption('name',
          abbr: 'n', help: 'Specifies a name for the model class.')
      ..addOption('output-dir',
          help: 'Specifies a directory to create the model class in.',
          defaultsTo: 'lib/src/models');
  }

  @override
  run() async {
    String name;
    if (argResults.wasParsed('name')) name = argResults['name'] as String;

    if (name?.isNotEmpty != true) {
      name = prompts.get('Name of model class');
    }

    List<MakerDependency> deps = [
      const MakerDependency('angel_model', '^1.0.0'),
    ];

    var rc = new ReCase(name);

    var modelLib = new Library((modelLib) {
      if (argResults['orm'] as bool && argResults['migration'] as bool) {
        modelLib.directives.addAll([
          new Directive.import('package:angel_migration/angel_migration.dart'),
        ]);
      }

      var needsSerialize =
          argResults['serializable'] as bool || argResults['orm'] as bool;
      // argResults['migration'] as bool;

      if (needsSerialize) {
        modelLib.directives.add(new Directive.import(
            'package:angel_serialize/angel_serialize.dart'));
        deps.add(const MakerDependency('angel_serialize', '^2.0.0'));
        deps.add(const MakerDependency('angel_serialize_generator', '^2.0.0'));
        deps.add(const MakerDependency('build_runner', '^1.0.0'));
      }

      // else {
      //   modelLib.directives
      //       .add(new Directive.import('package:angel_model/angel_model.dart'));
      //   deps.add(const MakerDependency('angel_model', '^1.0.0'));
      // }

      if (argResults['orm'] as bool) {
        modelLib.directives.addAll([
          new Directive.import('package:angel_orm/angel_orm.dart'),
        ]);
        deps.add(const MakerDependency('angel_orm', '^2.0.0'));
      }

      modelLib.body.addAll([
        new Code("part '${rc.snakeCase}.g.dart';"),
      ]);

      modelLib.body.add(new Class((modelClazz) {
        modelClazz
          ..abstract = true
          ..name = needsSerialize ? '_${rc.pascalCase}' : rc.pascalCase
          ..extend = refer('Model');

        if (needsSerialize) {
          // modelLib.addDirective(new PartBuilder('${rc.snakeCase}.g.dart'));
          modelClazz.annotations.add(refer('serializable'));
        }

        if (argResults['orm'] as bool) {
          if (argResults['migration'] as bool) {
            modelClazz.annotations.add(refer('orm'));
          } else {
            modelClazz.annotations.add(
                refer('Orm').call([], {'generateMigration': literalFalse}));
          }
        }
      }));
    });

    // Save model file
    var outputDir = new Directory.fromUri(
        Directory.current.uri.resolve(argResults['output-dir'] as String));
    var modelFile =
        new File.fromUri(outputDir.uri.resolve('${rc.snakeCase}.dart'));
    if (!await modelFile.exists()) await modelFile.create(recursive: true);

    await modelFile.writeAsString(new DartFormatter()
        .format(modelLib.accept(new DartEmitter()).toString()));

    print(green
        .wrap('$checkmark Created model file "${modelFile.absolute.path}".'));

    if (deps.isNotEmpty) await depend(deps);
  }
}
