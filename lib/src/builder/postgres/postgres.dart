import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:angel_serialize/angel_serialize.dart';
import 'package:build/build.dart';
import 'package:code_builder/dart/async.dart';
import 'package:code_builder/dart/core.dart';
import 'package:code_builder/code_builder.dart';
import 'package:inflection/inflection.dart';
import 'package:path/path.dart' as p;
import 'package:recase/recase.dart';
import 'package:source_gen/source_gen.dart';
import '../../annotations.dart';
import '../../migration.dart';
import '../find_annotation.dart';
import 'build_context.dart';
import 'postgres_build_context.dart';

// TODO: HasOne, HasMany, BelongsTo
class PostgresORMGenerator extends GeneratorForAnnotation<ORM> {
  /// If `true` (default), then field names will automatically be (de)serialized as snake_case.
  final bool autoSnakeCaseNames;

  const PostgresORMGenerator({this.autoSnakeCaseNames: true});

  @override
  Future<String> generateForAnnotatedElement(
      Element element, ORM annotation, BuildStep buildStep) {
    if (element is! ClassElement)
      throw 'Only classes can be annotated with @model.';
    var context =
        buildContext(element, annotation, buildStep, autoSnakeCaseNames);
    return new Future<String>.value(
        prettyToSource(generateOrmLibrary(context).buildAst()));
  }

  LibraryBuilder generateOrmLibrary(PostgresBuildContext ctx) {
    var lib = new LibraryBuilder();
    lib.addDirective(new ImportBuilder('dart:async'));
    lib.addDirective(new ImportBuilder('package:angel_orm/angel_orm.dart'));
    lib.addDirective(new ImportBuilder('package:postgres/postgres.dart'));
    lib.addDirective(new ImportBuilder(ctx.sourceFilename));
    lib.addMember(buildQueryClass(ctx));
    lib.addMember(buildWhereClass(ctx));
    return lib;
  }

  ClassBuilder buildQueryClass(PostgresBuildContext ctx) {
    var clazz = new ClassBuilder(ctx.queryClassName);

    // Add or + not
    for (var relation in ['and', 'or', 'not']) {
      clazz.addField(varFinal('_$relation',
          type: new TypeBuilder('List', genericTypes: [lib$core.String]),
          value: list([])));
      var relationMethod =
          new MethodBuilder(relation, returnType: lib$core.$void);
      relationMethod.addPositional(
          parameter('other', [new TypeBuilder(ctx.queryClassName)]));
      var otherWhere = reference('other').property('where');
      var compiled = reference('compiled');
      relationMethod.addStatement(
          varField('compiled', value: otherWhere.invoke('toWhereClause', [])));
      relationMethod.addStatement(ifThen(compiled.notEquals(literal(null)), [
        reference('_$relation').invoke('add', [compiled])
      ]));
      clazz.addMethod(relationMethod);
    }

    // Add _buildSelectQuery()

    // Add where...
    clazz.addField(varFinal('where',
        type: new TypeBuilder(ctx.whereClassName),
        value: new TypeBuilder(ctx.whereClassName).newInstance([])));

    // Add get()...
    clazz.addMethod(buildGetMethod(ctx));

    // Add getOne()...
    clazz.addMethod(buildGetOneMethod(ctx));

    // Add update()...
    clazz.addMethod(buildUpdateMethod(ctx));

    // Add remove()...
    clazz.addMethod(buildDeleteMethod(ctx));

    // Add insert()...
    clazz.addMethod(buildInsertMethod(ctx), asStatic: true);

    // Add getAll() => new TodoQuery().get();
    clazz.addMethod(
        new MethodBuilder('getAll',
            returnType: new TypeBuilder('Stream',
                genericTypes: [new TypeBuilder(ctx.modelClassName)]),
            returns: new TypeBuilder(ctx.queryClassName)
                .newInstance([]).invoke('get', [])),
        asStatic: true);

    return clazz;
  }

  MethodBuilder buildGetMethod(PostgresBuildContext ctx) {
    var meth = new MethodBuilder('get',
        returnType: new TypeBuilder('Stream',
            genericTypes: [new TypeBuilder(ctx.modelClassName)]));
    return meth;
  }

  MethodBuilder buildGetOneMethod(PostgresBuildContext ctx) {
    var meth = new MethodBuilder('getOne',
        returnType: new TypeBuilder('Future',
            genericTypes: [new TypeBuilder(ctx.modelClassName)]));
    return meth;
  }

  MethodBuilder buildUpdateMethod(PostgresBuildContext ctx) {
    var meth = new MethodBuilder('update',
        returnType: new TypeBuilder('Future',
            genericTypes: [new TypeBuilder(ctx.modelClassName)]));
    return meth;
  }

  MethodBuilder buildDeleteMethod(PostgresBuildContext ctx) {
    var meth = new MethodBuilder('delete',
        returnType: new TypeBuilder('Future',
            genericTypes: [new TypeBuilder(ctx.modelClassName)]));
    return meth;
  }

  MethodBuilder buildInsertMethod(PostgresBuildContext ctx) {
    var meth = new MethodBuilder('insert',
        returnType: new TypeBuilder('Future',
            genericTypes: [new TypeBuilder(ctx.modelClassName)]));
    meth.addPositional(
        parameter('connection', [new TypeBuilder('PostgreSQLConnection')]));

    // Add all named params
    ctx.fields.forEach((field) {
      var p = new ParameterBuilder(field.name,
          type: new TypeBuilder(field.type.name));
      var column = ctx.columnInfo[field.name];
      if (column?.defaultValue != null)
        p = p.asOptional(literal(column.defaultValue));
      meth.addNamed(p);
    });

    return meth;
  }

  ClassBuilder buildWhereClass(PostgresBuildContext ctx) {
    var clazz = new ClassBuilder(ctx.whereClassName);

    ctx.fields.forEach((field) {
      TypeBuilder queryBuilderType;
      List<ExpressionBuilder> args = [];

      switch (field.type.name) {
        case 'String':
          queryBuilderType = new TypeBuilder('StringSqlExpressionBuilder');
          break;
        case 'int':
          queryBuilderType = new TypeBuilder('NumericSqlExpressionBuilder',
              genericTypes: [lib$core.int]);
          break;
        case 'double':
          queryBuilderType = new TypeBuilder('NumericSqlExpressionBuilder',
              genericTypes: [new TypeBuilder('double')]);
          break;
        case 'num':
          queryBuilderType = new TypeBuilder('NumericSqlExpressionBuilder');
          break;
        case 'bool':
          queryBuilderType = new TypeBuilder('BooleanSqlExpressionBuilder');
          break;
        case 'DateTime':
          queryBuilderType = new TypeBuilder('DateTimeSqlExpressionBuilder');
          args.add(literal(ctx.resolveFieldName(field.name)));
          break;
      }

      if (queryBuilderType == null)
        throw 'Could not resolve query builder type for field "${field.name}" of type "${field.type.name}".';
      clazz.addField(varFinal(field.name,
          type: queryBuilderType, value: queryBuilderType.newInstance(args)));
    });

    // Create `toWhereClause()`
    var toWhereClause =
        new MethodBuilder('toWhereClause', returnType: lib$core.String);

    // List<String> expressions = [];
    toWhereClause.addStatement(varFinal('expressions',
        type: new TypeBuilder('List', genericTypes: [lib$core.String]),
        value: list([])));
    var expressions = reference('expressions');

    // Add all expressions...
    ctx.fields.forEach((field) {
      var name = ctx.resolveFieldName(field.name);
      var queryBuilder = reference(field.name);
      var toAdd = field.type.name == 'DateTime'
          ? queryBuilder.invoke('compile', [])
          : (literal('`$name` ') + queryBuilder.invoke('compile', []));

      toWhereClause.addStatement(ifThen(queryBuilder.property('hasValue'), [
        expressions.invoke('add', [toAdd])
      ]));
    });

    // return expressions.isEmpty ? null : ('WHERE ' + expressions.join(' AND '));
    toWhereClause.addStatement(expressions
        .property('isEmpty')
        .ternary(
            literal(null),
            (literal('WHERE ') + expressions.invoke('join', [literal(' AND ')]))
                .parentheses())
        .asReturn());

    clazz.addMethod(toWhereClause);

    return clazz;
  }
}
