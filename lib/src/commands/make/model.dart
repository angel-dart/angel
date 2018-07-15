import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:inflection/inflection.dart';
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
          help: 'Generate an angel_orm migration file.',
          negatable: false)
      ..addFlag('orm', help: 'Generate angel_orm code.', negatable: false)
      ..addFlag('serializable',
          help: 'Generate angel_serialize annotations.', defaultsTo: true)
      ..addOption('name',
          abbr: 'n', help: 'Specifies a name for the model class.')
      ..addOption('output-dir',
          help: 'Specifies a directory to create the model class in.',
          defaultsTo: 'lib/src/models')
      ..addOption('migration-dir',
          help: 'Specifies a directory to create the migration class in.',
          defaultsTo: 'tool/migrations');
  }

  @override
  run() async {
    var pubspec = await loadPubspec();
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
      modelLib.directives
          .add(new Directive.import('package:angel_model/angel_model.dart'));

      var needsSerialize =
          argResults['serializable'] as bool || argResults['orm'] as bool;

      if (needsSerialize) {
        modelLib.directives.add(new Directive.import(
            'package:angel_serialize/angel_serialize.dart'));
        deps.add(const MakerDependency('angel_serialize', '^2.0.0'));
        deps.add(const MakerDependency('angel_serialize_generator', '^2.0.0'));
        deps.add(const MakerDependency('build_runner', '">=0.7.0 <0.10.0"'));
      }

      if (argResults['orm'] as bool) {
        modelLib.directives
            .add(new Directive.import('package:angel_orm/angel_orm.dart'));
        deps.add(const MakerDependency('angel_orm', '^1.0.0-alpha'));
      }

      modelLib.body.addAll([
        new Code("part '${rc.snakeCase}.g.dart';"),
        new Code("part '${rc.snakeCase}.serializer.g.dart';"),
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
          modelClazz.annotations.add(refer('orm'));
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

    if (argResults['migration'] as bool) {
      deps.add(const MakerDependency('angel_migration', '^1.0.0-alpha'));

      var migrationLib = new Library((migrationLib) {
        migrationLib
          ..directives.add(new Directive.import(
              'package:angel_migration.dart/angel_migration.dart'))
          ..body.add(new Class((migrationClazz) {
            migrationClazz
              ..name = '${rc.pascalCase}Migration'
              ..extend = refer('Migration');

            var tableName = pluralize(rc.snakeCase);

            // up()
            migrationClazz.methods.add(new Method((up) {
              up
                ..name = 'up'
                ..returns = refer('void')
                ..annotations.add(refer('override'))
                ..requiredParameters.add(new Parameter((b) => b
                  ..name = 'schema'
                  ..type = refer('Schema')))
                ..body = new Block((block) {
                  // (table) { ... }
                  var callback = new Method((callback) {
                    callback
                      ..requiredParameters
                          .add(new Parameter((b) => b..name = 'table'))
                      ..body = new Block((block) {
                        var table = refer('table');

                        block.addExpression(
                          (table.property('serial').call([literal('id')]))
                              .property('primaryKey')
                              .call([]),
                        );

                        block.addExpression(
                          table.property('date').call([
                            literal('created_at'),
                          ]),
                        );

                        block.addExpression(
                          table.property('date').call([
                            literal('updated_at'),
                          ]),
                        );
                      });
                  });

                  block.addExpression(refer('schema').property('create').call([
                    literal(tableName),
                    callback.closure,
                  ]));
                });
            }));

            // down()
            migrationClazz.methods.add(new Method((down) {
              down
                ..name = 'down'
                ..returns = refer('void')
                ..annotations.add(refer('override'))
                ..requiredParameters.add(new Parameter((b) => b
                  ..name = 'schema'
                  ..type = refer('Schema')))
                ..body = new Block((block) {
                  block.addExpression(
                    refer('schema').property('drop').call([
                      literal(tableName),
                    ]),
                  );
                });
            }));
          }));
      });

      // Save migration file
      var migrationDir = new Directory.fromUri(
          Directory.current.uri.resolve(argResults['migration-dir'] as String));
      var migrationFile =
          new File.fromUri(migrationDir.uri.resolve('${rc.snakeCase}.dart'));
      if (!await migrationFile.exists())
        await migrationFile.create(recursive: true);

      await migrationFile.writeAsString(new DartFormatter()
          .format(migrationLib.accept(new DartEmitter()).toString()));

      print(green.wrap(
          '$checkmark Created migration file "${migrationFile.absolute.path}".'));
    }

    if (deps.isNotEmpty) await depend(deps);
  }
}
