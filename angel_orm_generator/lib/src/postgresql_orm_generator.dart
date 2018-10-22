import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:angel_orm/angel_orm.dart';
import 'package:angel_serialize_generator/angel_serialize_generator.dart';
import 'package:angel_serialize_generator/build_context.dart';
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
        ..methods.add(buildGetById(ctx))
        ..methods.add(buildDeleteById(ctx))
        ..methods.add(buildGetAll(ctx))
        ..methods.add(buildCreate(ctx))
        ..methods.add(buildUpdate(ctx));
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

  String buildFieldString(OrmBuildContext ctx) {
    var queryString = new StringBuffer();
    int i = 0;

    for (var field in ctx.buildContext.fields) {
      if (i++ > 0) queryString.write(',');
      queryString.write(' ' + ctx.buildContext.resolveFieldName(field.name));
    }
    return queryString.toString();
  }

  String buildQuotedFieldString(OrmBuildContext ctx) {
    var queryString = new StringBuffer();
    int i = 0;

    for (var field in ctx.buildContext.fields) {
      if (i++ > 0) queryString.write(',');
      queryString
          .write(' "' + ctx.buildContext.resolveFieldName(field.name) + '"');
    }
    return queryString.toString();
  }

  String buildInsertionValueString(OrmBuildContext ctx) {
    var buf = new StringBuffer('(');

    int i = 0;

    for (var field in ctx.buildContext.fields) {
      if (i++ > 0) buf.write(',');
      if (dateTimeTypeChecker.isAssignableFromType(field.type))
        buf.write(
            'CAST (@${field.name} AS ${ctx.columns[field.name].type.name})');
      else
        buf.write('@${field.name}');
    }

    return buf.toString() + ')';
  }

  Expression buildSubstitutionValues(OrmBuildContext ctx) {
    var values = <Expression, Expression>{};

    for (var field in ctx.buildContext.fields) {
      values[literalString(field.name)] = refer('model').property(field.name);
    }

    return literalMap(values);
  }

  void applyQuery(
      BlockBuilder b, String queryString, Expression substitutionValues) {
    b.statements.add(refer('connection')
        .property('query')
        .call(
            [literalString(queryString)],
            substitutionValues == null
                ? {}
                : {'substitutionValues': substitutionValues})
        .awaited
        .assignVar('r')
        .statement);
  }

  void applyQueryAndReturnOne(
      BlockBuilder b, String queryString, Expression substitutionValues) {
    applyQuery(b, queryString, substitutionValues);
    b.addExpression(
        (refer('parseRow').call([refer('r').property('first')])).returned);
  }

  void applyQueryAndReturnList(
      BlockBuilder b, String queryString, Expression substitutionValues) {
    applyQuery(b, queryString, substitutionValues);
    b.statements.add(new Code('return r.map(parseRow).toList();'));
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
        ..requiredParameters.add(new Parameter((b) => b
          ..name = 'id'
          ..type = refer('String')))
        ..returns = new TypeReference((b) => b
          ..symbol = 'Future'
          ..types.add(ctx.buildContext.modelClassType))
        ..body = new Block((b) {
          var fields = buildFieldString(ctx);
          var queryString =
              'SELECT $fields FROM "${ctx.tableName}" WHERE id = @id LIMIT 1;';
          applyQueryAndReturnOne(
              b,
              queryString,
              literalMap({
                'id': refer('int').property('parse').call([refer('id')])
              }));
        });
    });
  }

  Method buildDeleteById(OrmBuildContext ctx) {
    /* 
      @override
      Future<Author> getById(id) async  {
        var r = await connection.query('');
        return parseRow(r.first);
      }
     */
    return new Method((m) {
      m
        ..name = 'deleteById'
        ..annotations.add(refer('override'))
        ..modifier = MethodModifier.async
        ..requiredParameters.add(new Parameter((b) => b
          ..name = 'id'
          ..type = refer('String')))
        ..returns = new TypeReference((b) => b
          ..symbol = 'Future'
          ..types.add(ctx.buildContext.modelClassType))
        ..body = new Block((b) {
          var fields = buildQuotedFieldString(ctx);
          var queryString =
              'DELETE FROM "${ctx.tableName}" WHERE id = @id RETURNING $fields;';
          applyQueryAndReturnOne(
              b,
              queryString,
              literalMap({
                'id': refer('int').property('parse').call([refer('id')])
              }));
        });
    });
  }

  Method buildGetAll(OrmBuildContext ctx) {
    /*
      @override
      Future<List<Author>> getAll() async {
        var r = await connection
            .query('SELECT id, name, created_at, updated_at FROM "authors";');
        return r.map(parseRow).toList();
      }
    */
    return new Method((method) {
      method
        ..name = 'getAll'
        ..modifier = MethodModifier.async
        ..returns = refer('Future<List<${ctx.buildContext.modelClassName}>>')
        ..annotations.add(refer('override'))
        ..body = new Block((block) {
          var fields = buildFieldString(ctx);
          var queryString = 'SELECT $fields FROM "${ctx.tableName}";';
          applyQueryAndReturnList(block, queryString, null);
        });
    });
  }

  Method buildCreate(OrmBuildContext ctx) {
    /*
    @override
    Future<Author> createAuthor(Author model) async {
      // ...
    }
    */
    return new Method((method) {
      method
        ..name = 'create${ctx.buildContext.modelClassName}'
        ..modifier = MethodModifier.async
        ..annotations.add(refer('override'))
        ..returns = refer('Future<${ctx.buildContext.modelClassName}>')
        ..requiredParameters.add(new Parameter((b) => b
          ..name = 'model'
          ..type = ctx.buildContext.modelClassType))
        ..body = new Block((block) {
          if (ctx.buildContext.autoIdAndDateFields != false) {
            // If we are auto-managing created+updated at, do so now
            block.statements.add(new Code(
                'model = model.copyWith(createdAt: new DateTime.now(), updatedAt: new DateTime.now());'));
          }

          var fields = buildQuotedFieldString(ctx);
          var fieldSet = buildInsertionValueString(ctx);
          var queryString =
              'INSERT INTO "${ctx.tableName}" ($fields) VALUES $fieldSet RETURNING $fields;';
          applyQueryAndReturnOne(
              block, queryString, buildSubstitutionValues(ctx));
        });
    });
  }

  Method buildUpdate(OrmBuildContext ctx) {
    /*
    @override
    Future<Author> updateAuthor(Author model) async {
      // ...
    }
    */
    return new Method((method) {
      method
        ..name = 'update${ctx.buildContext.modelClassName}'
        ..modifier = MethodModifier.async
        ..annotations.add(refer('override'))
        ..returns = refer('Future<${ctx.buildContext.modelClassName}>')
        ..requiredParameters.add(new Parameter((b) => b
          ..name = 'model'
          ..type = ctx.buildContext.modelClassType))
        ..body = new Block((block) {
          if (ctx.buildContext.autoIdAndDateFields != false) {
            // If we are auto-managing created+updated at, do so now
            block.statements.add(new Code(
                'model = model.copyWith(updatedAt: new DateTime.now());'));
          }

          var fields = buildQuotedFieldString(ctx);
          var fieldSet = buildInsertionValueString(ctx);
          var queryString =
              'UPDATE "${ctx.tableName}" SET ($fields) = $fieldSet RETURNING $fields;';
          applyQueryAndReturnOne(
              block, queryString, buildSubstitutionValues(ctx));
        });
    });
  }
}
