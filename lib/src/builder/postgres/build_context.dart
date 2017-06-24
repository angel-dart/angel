import 'package:analyzer/dart/element/element.dart';
import 'package:angel_serialize/build_context.dart' as serialize;
import 'package:angel_serialize/context.dart' as serialize;
import 'package:build/build.dart';
import 'package:inflection/inflection.dart';
import 'package:recase/recase.dart';
import '../../annotations.dart';
import '../../migration.dart';
import '../../relations.dart';
import 'package:angel_serialize/src/find_annotation.dart';
import 'package:source_gen/src/annotation.dart';
import 'postgres_build_context.dart';

// TODO: Should add id, createdAt, updatedAt...
PostgresBuildContext buildContext(
    ClassElement clazz,
    ORM annotation,
    BuildStep buildStep,
    Resolver resolver,
    bool autoSnakeCaseNames,
    bool autoIdAndDateFields) {
  var raw = serialize.buildContext(clazz, null, buildStep, resolver,
      autoSnakeCaseNames != false, autoIdAndDateFields != false);
  var ctx = new PostgresBuildContext(raw, annotation, resolver, buildStep,
      tableName: annotation.tableName?.isNotEmpty == true
          ? annotation.tableName
          : pluralize(new ReCase(clazz.name).snakeCase));
  List<String> fieldNames = [];

  for (var field in raw.fields) {
    fieldNames.add(field.name);
    // Check for relationship. If so, skip.
    Relationship relationship = null;
    /* findAnnotation<HasOne>(field, HasOne) ??
          findAnnotation<HasMany>(field, HasMany) ??
          findAnnotation<BelongsTo>(field, BelongsTo);*/
    bool isRelationship = field.metadata.any((ann) {
      return matchAnnotation(Relationship, ann) ||
          matchAnnotation(HasMany, ann) ||
          matchAnnotation(HasOne, ann) ||
          matchAnnotation(BelongsTo, ann);
    });

    if (relationship != null) {
      ctx.relationships[field.name] = relationship;
      continue;
    } else if (isRelationship) {
      ctx.relationships[field.name] = null;
      continue;
    }

    // Check for column annotation...
    var column = findAnnotation<Column>(field, Column);

    if (column == null) {
      // Guess what kind of column this is...
      switch (field.type.name) {
        case 'String':
          column = const Column(type: ColumnType.VAR_CHAR);
          break;
        case 'int':
          column = const Column(type: ColumnType.INT);
          break;
        case 'double':
          column = const Column(type: ColumnType.DECIMAL);
          break;
        case 'num':
          column = const Column(type: ColumnType.NUMERIC);
          break;
        case 'num':
          column = const Column(type: ColumnType.NUMERIC);
          break;
        case 'bool':
          column = const Column(type: ColumnType.BIT);
          break;
        case 'DateTime':
          column = const Column(type: ColumnType.TIME_STAMP);
          break;
      }
    }

    if (column == null)
      throw 'Cannot infer SQL column type for field "${field.name}" with type "${field.type.name}".';
    ctx.columnInfo[field.name] = column;
  }

  return ctx;
}
