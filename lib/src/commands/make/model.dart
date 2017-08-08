import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:code_builder/dart/core.dart';
import 'package:code_builder/code_builder.dart';
import 'package:console/console.dart';
import 'package:inflection/inflection.dart';
import 'package:pubspec/pubspec.dart';
import 'package:recase/recase.dart';
import 'maker.dart';

class ModelCommand extends Command {
  final TextPen _pen = new TextPen();

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
    var pubspec = await PubSpec.load(Directory.current);
    String name;
    if (argResults.wasParsed('name')) name = argResults['name'];

    if (name?.isNotEmpty != true) {
      var p = new Prompter('Name of Model class: ');
      name = await p.prompt(checker: (s) => s.isNotEmpty);
    }

    List<MakerDependency> deps = [
      const MakerDependency('angel_framework', '^1.0.0'),
      const MakerDependency('angel_model', '^1.0.0'),
    ];

    var rc = new ReCase(name);
    var modelLib =
        new LibraryBuilder('${pubspec.name}.src.models.${rc.snakeCase}');
    modelLib.addDirective(
        new ImportBuilder('package:angel_model/angel_model.dart'));

    var needsSerialize = argResults['serializable'] || argResults['orm'];

    if (needsSerialize) {
      modelLib.addDirective(
          new ImportBuilder('package:angel_serialize/angel_serialize.dart'));
      deps.add(const MakerDependency('angel_serialize', '^1.0.0-alpha'));
    }

    if (argResults['orm']) {
      modelLib
          .addDirective(new ImportBuilder('package:angel_orm/angel_orm.dart'));
      deps.add(const MakerDependency('angel_orm', '^1.0.0-alpha'));
    }

    var modelClazz = new ClassBuilder(
        needsSerialize ? '_${rc.pascalCase}' : rc.pascalCase,
        asExtends: new TypeBuilder('Model'));
    modelLib.addMember(modelClazz);

    if (needsSerialize) {
      modelLib.addDirective(new PartBuilder('${rc.snakeCase}.g.dart'));
      modelClazz.addAnnotation(reference('serializable'));
    }

    if (argResults['orm']) {
      modelClazz.addAnnotation(reference('orm'));
    }

    // Save model file
    var outputDir = new Directory.fromUri(
        Directory.current.uri.resolve(argResults['output-dir']));
    var modelFile =
        new File.fromUri(outputDir.uri.resolve('${rc.snakeCase}.dart'));
    if (!await modelFile.exists()) await modelFile.create(recursive: true);
    await modelFile.writeAsString(prettyToSource(modelLib.buildAst()));
    _pen
      ..green()
      ..call(
          '${Icon.CHECKMARK} Created model file "${modelFile.absolute.path}".')
      ..call()
      ..reset();

    if (argResults['migration']) {
      deps.add(
          const MakerDependency('angel_migration', '^1.0.0-alpha', dev: true));

      var migrationLib = new LibraryBuilder()
        ..addDirective(
            new ImportBuilder('package:angel_migration/angel_migration.dart'));
      var migrationClazz = new ClassBuilder('${rc.pascalCase}Migration',
          asExtends: new TypeBuilder('Migration'));
      migrationLib.addMember(migrationClazz);
      var tableName = pluralize(rc.snakeCase);

      // up()
      var up = new MethodBuilder('up', returnType: lib$core.$void);
      migrationClazz.addMethod(up);
      up.addAnnotation(lib$core.override);
      up.addPositional(parameter('schema', [new TypeBuilder('Schema')]));

      // (table) { ... }
      var callback = new MethodBuilder.closure();
      callback.addPositional(parameter('table'));

      var cascade = reference('table').cascade((table) => [
            table.invoke('serial', [literal('id')]).invoke('primaryKey', []),
            table.invoke('date', [literal('created_at')]),
            table.invoke('date', [literal('updated_at')])
          ]);
      callback.addStatement(cascade);

      up.addStatement(reference('schema').invoke('create', [callback]));

      // down()
      var down = new MethodBuilder('down', returnType: lib$core.$void);
      migrationClazz.addMethod(down);
      down.addAnnotation(lib$core.override);
      down.addPositional(parameter('schema', [new TypeBuilder('Schema')]));
      down.addStatement(
          reference('schema').invoke('drop', [literal(tableName)]));

      // Save migration file
      var migrationDir = new Directory.fromUri(
          Directory.current.uri.resolve(argResults['migration-dir']));
      var migrationFile =
          new File.fromUri(migrationDir.uri.resolve('${rc.snakeCase}.dart'));
      if (!await migrationFile.exists())
        await migrationFile.create(recursive: true);
      await migrationFile
          .writeAsString(prettyToSource(migrationLib.buildAst()));
    _pen
      ..green()
      ..call(
          '${Icon.CHECKMARK} Created migration file "${migrationFile.absolute.path}".')
      ..call()
      ..reset();
    }

    if (deps.isNotEmpty) await depend(deps);
  }
}
