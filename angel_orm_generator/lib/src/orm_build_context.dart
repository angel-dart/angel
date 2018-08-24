import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:angel_orm/angel_orm.dart';
import 'package:angel_serialize_generator/build_context.dart';
import 'package:angel_serialize_generator/context.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'readers.dart';

Future<OrmBuildContext> buildOrmContext(
    ClassElement clazz,
    ConstantReader annotation,
    BuildStep buildStep,
    Resolver resolver,
    bool autoSnakeCaseNames,
    bool autoIdAndDateFields,
    {bool heedExclude: true}) async {
  var buildCtx = await buildContext(clazz, annotation, buildStep, resolver,
      autoSnakeCaseNames, autoIdAndDateFields);
  var ormAnnotation = reviveORMAnnotation(annotation);
  var ctx = new OrmBuildContext(buildCtx, ormAnnotation);

  // Read all fields
  for (var field in buildCtx.fields) {
    // Check for column annotation...
    Column column;
    var columnAnnotation = columnTypeChecker.firstAnnotationOf(field);

    if (columnAnnotation != null) {
      column = reviveColumn(new ConstantReader(columnAnnotation));
    }

    if (column == null && field.name == 'id' && autoIdAndDateFields == true) {
      // TODO: This is only for PostgreSQL!!!
      column = const Column(type: ColumnType.serial);
    }

    if (column == null) {
      // Guess what kind of column this is...
      column = new Column(
        type: inferColumnType(
          field.type,
        ),
      );
    }

    if (column != null && column.type == null) {
      column = new Column(
        isNullable: column.isNullable,
        length: column.length,
        indexType: column.indexType,
        defaultValue: column.defaultValue,
        type: inferColumnType(field.type),
      );
    }

    if (column?.type == null)
      throw 'Cannot infer SQL column type for field "${field.name}" with type "${field.type.name}".';
    ctx.columns[field.name] = column;
  }

  return ctx;
}

ColumnType inferColumnType(DartType type) {
  if (const TypeChecker.fromRuntime(String).isAssignableFromType(type))
    return ColumnType.varChar;
  if (const TypeChecker.fromRuntime(int).isAssignableFromType(type))
    return ColumnType.int;
  if (const TypeChecker.fromRuntime(double).isAssignableFromType(type))
    return ColumnType.decimal;
  if (const TypeChecker.fromRuntime(num).isAssignableFromType(type))
    return ColumnType.numeric;
  if (const TypeChecker.fromRuntime(bool).isAssignableFromType(type))
    return ColumnType.boolean;
  if (const TypeChecker.fromRuntime(DateTime).isAssignableFromType(type))
    return ColumnType.timeStamp;
  return null;
}

Column reviveColumn(ConstantReader cr) {
  var args = cr.revive().namedArguments;
  IndexType indexType = IndexType.none;
  ColumnType columnType;

  if (args.containsKey('index')) {
    indexType =
        IndexType.values[args['indexType'].getField('index').toIntValue()];
  }

  if (args.containsKey('type')) {
    columnType = new _ColumnType(args['type'].getField('name').toStringValue());
  }

  return new Column(
    isNullable: cr.peek('isNullable')?.boolValue,
    length: cr.peek('length')?.intValue,
    defaultValue: cr.peek('defaultValue')?.literalValue,
    type: columnType,
    indexType: indexType,
  );
}

class OrmBuildContext {
  final BuildContext buildContext;
  final ORM ormAnnotation;

  final Map<String, Column> columns = {};

  OrmBuildContext(this.buildContext, this.ormAnnotation);
}

class _ColumnType implements ColumnType {
  @override
  final String name;

  _ColumnType(this.name);
}
