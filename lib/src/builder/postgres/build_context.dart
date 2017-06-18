import 'package:analyzer/dart/element/element.dart';
import 'package:angel_serialize/angel_serialize.dart';
import 'package:build/build.dart';
import 'package:inflection/inflection.dart';
import 'package:path/path.dart' as p;
import 'package:recase/recase.dart';
import '../../annotations.dart';
import '../../migration.dart';
import '../../relations.dart';
import '../find_annotation.dart';
import 'postgres_build_context.dart';

// TODO: Should add id, createdAt, updatedAt...
PostgresBuildContext buildContext(ClassElement clazz, ORM annotation,
    BuildStep buildStep, bool autoSnakeCaseNames) {
  var ctx = new PostgresBuildContext(annotation,
      originalClassName: clazz.name,
      tableName: annotation.tableName?.isNotEmpty == true
          ? annotation.tableName
          : pluralize(new ReCase(clazz.name).snakeCase),
      sourceFilename: p.basename(buildStep.inputId.path));

  for (var field in clazz.fields) {
    if (field.getter != null && field.setter != null) {
      // Check for relationship. If so, skip.
      Relationship relationship = findAnnotation<HasOne>(field, HasOne) ??
          findAnnotation<HasMany>(field, HasMany) ??
          findAnnotation<BelongsTo>(field, BelongsTo);

      if (relationship != null) {
        ctx.relationships[field.name] = relationship;
        continue;
      } else print('Hm: ${field.name}');
      // Check for alias
      var alias = findAnnotation<Alias>(field, Alias);

      if (alias?.name?.isNotEmpty == true) {
        ctx.aliases[field.name] = alias.name;
      } else if (autoSnakeCaseNames != false) {
        ctx.aliases[field.name] = new ReCase(field.name).snakeCase;
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
            column = const Column(type: ColumnType.DATE_TIME);
            break;
        }
      }

      if (column == null)
        throw 'Cannot infer SQL column type for field "${field.name}" with type "${field.type.name}".';
      ctx.columnInfo[field.name] = column;
      ctx.fields.add(field);
    }
  }

  return ctx;
}
