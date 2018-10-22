import 'dart:async';
import 'dart:collection';
import 'package:analyzer/dart/element/element.dart';
import 'package:angel_orm/angel_orm.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart' hide LibraryBuilder;
import 'package:path/path.dart' as p;
import 'package:recase/recase.dart';
import 'package:source_gen/source_gen.dart';

import 'orm_build_context.dart';

Builder ormBuilder(_) {
  return new LibraryBuilder(new OrmGenerator(),
      generatedExtension: '.orm.g.dart');
}

TypeReference futureOf(String type) {
  return new TypeReference((b) => b
    ..symbol = 'Future'
    ..types.add(refer(type)));
}

/// Builder that generates `.orm.g.dart`, with an abstract `FooOrm` class.
class OrmGenerator extends GeneratorForAnnotation<Orm> {
  final bool autoSnakeCaseNames;
  final bool autoIdAndDateFields;

  OrmGenerator({this.autoSnakeCaseNames, this.autoIdAndDateFields});

  @override
  Future<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    if (element is ClassElement) {
      var ctx = await buildOrmContext(element, annotation, buildStep,
          buildStep.resolver, autoSnakeCaseNames, autoIdAndDateFields);
      var lib = buildOrmBaseLibrary(buildStep.inputId, ctx);
      return lib.accept(new DartEmitter()).toString();
    } else {
      throw 'The @Orm() annotation can only be applied to classes.';
    }
  }

  Library buildOrmBaseLibrary(AssetId inputId, OrmBuildContext ctx) {
    return new Library((lib) {
      // Necessary imports
      var imports = new SplayTreeSet<String>.from(
          ['dart:async', p.basename(inputId.uri.path)]);

      switch (ctx.ormAnnotation.type) {
//        case OrmType.mongoDB:
//          imports.add('package:mongo_dart/mongo_dart.dart');
//          break;
        case OrmType.postgreSql:
          imports.add('package:postgres/postgres.dart');
          break;
        default:
          break;
      }

      lib.directives.addAll(imports.map((url) => new Directive.import(url)));

      // Add the corresponding `part`
      String dbExtension;

      switch (ctx.ormAnnotation.type) {
//        case OrmType.mongoDB:
//          dbExtension = 'mongodb';
//          break;
        case OrmType.rethinkDB:
          dbExtension = 'rethinkdb';
          break;
        case OrmType.mySql:
          dbExtension = 'mysql';
          break;
        case OrmType.postgreSql:
          dbExtension = 'postgresql';
          break;
        default:
          throw 'Unsupported ORM type: ${ctx.ormAnnotation.type}';
      }

      var dbFile = p.setExtension(
          p.basename(inputId.uri.path), '.$dbExtension.orm.g.dart');

      lib.body.add(new Code("part '$dbFile';"));

      // Create `FooOrm` abstract class
      var rc = ctx.buildContext.modelClassNameRecase;

      lib.body.add(new Class((clazz) {
        clazz
          ..name = '${rc.pascalCase}Orm'
          ..abstract = true;

        // Add factory constructors.
        switch (ctx.ormAnnotation.type) {
          case OrmType.postgreSql:
            clazz.constructors.add(new Constructor((b) {
              b
                ..name = 'postgreSql'
                ..factory = true
                ..redirect = refer('PostgreSql${rc.pascalCase}Orm')
                ..requiredParameters.add(new Parameter((b) {
                  b
                    ..name = 'connection'
                    ..type = refer('PostgreSQLConnection');
                }));
            }));
            dbExtension = 'postgresql';
            break;
          default:
            break;
        }

        // Next, add method stubs.
        // * getAll
        // * getById
        // * deleteById
        // * updateX()
        // * createX()
        // * query()

        // getAll
        clazz.methods.add(new Method((m) {
          m
            ..name = 'getAll'
            ..returns = new TypeReference((b) => b
              ..symbol = 'Future'
              ..types.add(new TypeReference((b) => b
                ..symbol = 'List'
                ..types.add(ctx.buildContext.modelClassType))));
        }));

        // getById
        clazz.methods.add(new Method((m) {
          m
            ..name = 'getById'
            ..returns = futureOf(ctx.buildContext.modelClassName)
            ..requiredParameters.add(new Parameter((b) => b
              ..name = 'id'
              ..type = refer('String')));
        }));

        // deleteById
        clazz.methods.add(new Method((m) {
          m
            ..name = 'deleteById'
            ..returns = futureOf(ctx.buildContext.modelClassName)
            ..requiredParameters.add(new Parameter((b) => b
              ..name = 'id'
              ..type = refer('String')));
        }));

        // createX()
        clazz.methods.add(new Method((m) {
          m
            ..name = 'create${ctx.buildContext.modelClassName}'
            ..returns = futureOf(ctx.buildContext.modelClassName)
            ..requiredParameters.add(new Parameter((b) => b
              ..name = 'model'
              ..type = ctx.buildContext.modelClassType));
        }));

        // updateX()
        clazz.methods.add(new Method((m) {
          m
            ..name = 'update${ctx.buildContext.modelClassName}'
            ..returns = futureOf(ctx.buildContext.modelClassName)
            ..requiredParameters.add(new Parameter((b) => b
              ..name = 'model'
              ..type = ctx.buildContext.modelClassType));
        }));

        // query()
        clazz.methods.add(new Method((m) {
          m
            ..name = 'query'
            ..returns = refer('${rc.pascalCase}Query');
        }));
      }));

      // Create `FooQuery` class
      lib.body.add(new Class((clazz) {
        clazz..name = '${rc.pascalCase}Query';
      }));
    });
  }
}
