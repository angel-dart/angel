import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:angel_orm/angel_orm.dart';
import 'package:angel_serialize_generator/src/find_annotation.dart';
import 'package:angel_serialize_generator/build_context.dart' as serialize;
import 'package:angel_serialize_generator/context.dart' as serialize;
import 'package:build/build.dart';
import 'package:inflection/inflection.dart';
import 'package:recase/recase.dart';
import 'package:source_gen/source_gen.dart';
import 'postgres_build_context.dart';

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
          : pluralize(new ReCase(clazz.name).snakeCase),
      autoSnakeCaseNames: autoSnakeCaseNames != false,
      autoIdAndDateFields: autoIdAndDateFields != false);
  var relations = new TypeChecker.fromRuntime(Relationship);
  List<String> fieldNames = [];
  List<FieldElement> fields = [];

  for (var field in raw.fields) {
    fieldNames.add(field.name);
    // Check for relationship. If so, skip.
    var relationshipAnnotation = relations.firstAnnotationOf(field);
    /* findAnnotation<HasOne>(field, HasOne) ??
          findAnnotation<HasMany>(field, HasMany) ??
          findAnnotation<BelongsTo>(field, BelongsTo);*/

    if (relationshipAnnotation != null) {
      int type = -1;

      switch (relationshipAnnotation.type.name) {
        case 'HasMany':
          type = RelationshipType.HAS_MANY;
          break;
        case 'HasOne':
          type = RelationshipType.HAS_ONE;
          break;
        case 'BelongsTo':
          type = RelationshipType.BELONGS_TO;
          break;
        case 'BelongsToMany':
          type = RelationshipType.BELONGS_TO_MANY;
          break;
        default:
          throw new UnsupportedError(
              'Unsupported relationship type "${relationshipAnnotation.type.name}".');
      }

      ctx.relationshipFields.add(field);
      ctx.relationships[field.name] = new Relationship(type,
          localKey:
              relationshipAnnotation.getField('localKey')?.toStringValue(),
          foreignKey:
              relationshipAnnotation.getField('foreignKey')?.toStringValue(),
          foreignTable:
              relationshipAnnotation.getField('foreignTable')?.toStringValue(),
          cascadeOnDelete: relationshipAnnotation
              .getField('cascadeOnDelete')
              ?.toBoolValue());
      continue;
    }

    // Check for column annotation...
    var column = findAnnotation<Column>(field, Column);

    if (column == null && field.name == 'id' && ctx.shimmed['id'] == true) {
      column = const Column(type: ColumnType.SERIAL);
    }

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
          column = const Column(type: ColumnType.BOOLEAN);
          break;
        case 'DateTime':
          column = const Column(type: ColumnType.TIME_STAMP);
          break;
      }
    }

    if (column == null)
      throw 'Cannot infer SQL column type for field "${field.name}" with type "${field.type.name}".';
    ctx.columnInfo[field.name] = column;
    fields.add(field);
  }

  ctx.fields.addAll(fields);

  // Add belongs to fields
  // TODO: Do this for belongs to many as well
  ctx.relationships.forEach((name, r) {
    var relationship = ctx.populateRelationship(name);
    var rc = new ReCase(relationship.localKey);

    if (relationship.type == RelationshipType.BELONGS_TO) {
      var field = new RelationshipConstraintField(
          rc.camelCase, ctx.typeProvider.intType, name);
      ctx.fields.add(field);
      ctx.aliases[field.name] = relationship.localKey;
    }
  });

  return ctx;
}

class RelationshipConstraintField extends FieldElementImpl {
  @override
  final DartType type;
  final String originalName;
  RelationshipConstraintField(String name, this.type, this.originalName)
      : super(name, -1);
}
