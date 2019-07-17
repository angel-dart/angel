import 'dart:async';
import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:inflection2/inflection2.dart';
import 'package:io/ansi.dart';
import 'package:prompts/prompts.dart' as prompts;
import 'package:recase/recase.dart';
import '../../util.dart';
import 'maker.dart';

class MigrationCommand extends Command {
  @override
  String get name => 'migration';

  @override
  String get description => 'Generates a migration class.';

  MigrationCommand() {
    argParser
      ..addOption('name',
          abbr: 'n', help: 'Specifies a name for the model class.')
      ..addOption('output-dir',
          help: 'Specifies a directory to create the migration class in.',
          defaultsTo: 'tool/migrations');
  }

  @override
  FutureOr run() async {
    String name;
    if (argResults.wasParsed('name')) name = argResults['name'] as String;

    if (name?.isNotEmpty != true) {
      name = prompts.get('Name of model class');
    }

    var deps = [const MakerDependency('angel_migration', '^2.0.0')];
    var rc = new ReCase(name);

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
        Directory.current.uri.resolve(argResults['output-dir'] as String));
    var migrationFile =
        new File.fromUri(migrationDir.uri.resolve('${rc.snakeCase}.dart'));
    if (!await migrationFile.exists())
      await migrationFile.create(recursive: true);

    await migrationFile.writeAsString(new DartFormatter()
        .format(migrationLib.accept(new DartEmitter()).toString()));

    print(green.wrap(
        '$checkmark Created migration file "${migrationFile.absolute.path}".'));

    await depend(deps);
  }
}
