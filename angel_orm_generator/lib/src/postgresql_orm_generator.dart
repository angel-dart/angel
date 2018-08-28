import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:angel_orm/angel_orm.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart' hide LibraryBuilder;
import 'package:path/path.dart' as p;
import 'package:source_gen/source_gen.dart';

import 'orm_build_context.dart';

Builder postgreSqlOrmBuilder(_) {
  return new LibraryBuilder(new PostgreSqlOrmGenerator(),
      generatedExtension: '.postgresql.orm.g.dart');
}

/// Builder that generates `.orm.g.dart`, with an abstract `FooOrm` class.
class PostgreSqlOrmGenerator extends GeneratorForAnnotation<Orm> {
  final bool autoSnakeCaseNames;
  final bool autoIdAndDateFields;

  PostgreSqlOrmGenerator({this.autoSnakeCaseNames, this.autoIdAndDateFields});

  @override
  Future<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    if (element is ClassElement) {
      var ctx = await buildOrmContext(element, annotation, buildStep,
          buildStep.resolver, autoSnakeCaseNames, autoIdAndDateFields);
      var lib = buildOrmLibrary(buildStep.inputId, ctx);
      return lib.accept(new DartEmitter()).toString();
    } else {
      throw 'The @Orm() annotation can only be applied to classes.';
    }
  }

  Library buildOrmLibrary(AssetId inputId, OrmBuildContext ctx) {
    return new Library((lib) {
      // Add part of
      var libFile = p.setExtension(p.basename(inputId.uri.path), '.orm.g.dart');
      lib.body.add(new Code("part of '$libFile';"));

      // Add _PostgresqlFooOrmImpl
      lib.body.add(buildOrmClass(ctx));
    });
  }

  Class buildOrmClass(OrmBuildContext ctx) {
    return new Class((clazz) {
      var rc = ctx.buildContext.modelClassNameRecase;
      clazz
        ..name = '_Postgresql${rc.pascalCase}OrmImpl'
        ..implements.add(refer('${rc.pascalCase}Orm'))

        // final PostgreSQLConnection connection;
        ..fields.add(new Field((b) {
          b
            ..modifier = FieldModifier.final$
            ..name = 'connection'
            ..type = refer('PostgreSQLConnection');
        }))

        // _PostgresqlFooOrmImpl(this.connection);
        ..constructors.add(new Constructor((b) {
          b
            ..requiredParameters.add(new Parameter((b) => b
              ..name = 'connection'
              ..toThis = true));
        }));
    });
  }
}
