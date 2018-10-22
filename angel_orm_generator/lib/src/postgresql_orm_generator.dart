import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:angel_orm/angel_orm.dart';
import 'package:angel_serialize_generator/angel_serialize_generator.dart';
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
        ..name = '_PostgreSql${rc.pascalCase}OrmImpl'
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
        }))
        ..methods.add(buildParseRowMethod(ctx))
        ..methods.add(buildGetById(ctx));
    });
  }

  Method buildParseRowMethod(OrmBuildContext ctx) {
    return new Method((m) {
      m
        ..name = 'parseRow'
        ..static = true
        ..returns = ctx.buildContext.modelClassType
        ..requiredParameters.add(new Parameter((b) => b
          ..name = 'row'
          ..type = refer('List')))
        ..body = new Block((b) {
          var args = <String, Expression>{};

          for (int i = 0; i < ctx.buildContext.fields.length; i++) {
            var field = ctx.buildContext.fields[i];
            args[field.name] = refer('row')
                .index(literalNum(i))
                .asA(convertTypeReference(field.type));
          }

          var returnValue =
              ctx.buildContext.modelClassType.newInstance([], args);
          b.addExpression(returnValue.returned);
        });
    });
  }

  Method buildGetById(OrmBuildContext ctx) {
    /* 
      @override
      Future<Author> getById(id) async  {
        var r = await connection.query('');
        return parseRow(r.first);
      }
     */
    return new Method((m) {
      m
        ..name = 'getById'
        ..annotations.add(refer('override'))
        ..modifier = MethodModifier.async
        ..returns = new TypeReference((b) => b
          ..symbol = 'Future'
          ..types.add(ctx.buildContext.modelClassType))
        ..body = new Block((b) {
          var queryString = new StringBuffer('SELECT');
          int i = 0;

          for (var field in ctx.buildContext.fields) {
            if (i > 0) queryString.write(', ');
            queryString.write(ctx.buildContext.resolveFieldName(field.name));
          }

          queryString.write(' FROM "${ctx.tableName}" id = @id;');
          b.statements.add(refer('connection')
              .property('query')
              .call([
                literalString(queryString.toString())
              ], {
                'substitutionValues': literalMap({'id': refer('id')})
              })
              .awaited
              .assignVar('r')
              .statement);
          b.addExpression(
              refer('parseRow').call([refer('r').property('first')]));
        });
    });
  }
}
