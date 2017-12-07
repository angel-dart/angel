import 'dart:async';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:angel_orm/angel_orm.dart';
import 'package:angel_serialize_generator/build_context.dart' as serialize;
import 'package:angel_serialize_generator/context.dart' as serialize;
import 'package:build/build.dart';
import 'package:inflection/inflection.dart';
import 'package:recase/recase.dart';
import 'package:source_gen/source_gen.dart';
import 'postgres_build_context.dart';

const TypeChecker columnTypeChecker = const TypeChecker.fromRuntime(Column),
    dateTimeTypeChecker = const TypeChecker.fromRuntime(DateTime),
    ormTypeChecker = const TypeChecker.fromRuntime(ORM),
    relationshipTypeChecker = const TypeChecker.fromRuntime(Relationship);

const TypeChecker hasOneTypeChecker = const TypeChecker.fromRuntime(HasOne),
    hasManyTypeChecker = const TypeChecker.fromRuntime(HasMany),
    belongsToTypeChecker = const TypeChecker.fromRuntime(BelongsTo),
    belongsToManyTypeChecker = const TypeChecker.fromRuntime(BelongsToMany);

ColumnType inferColumnType(DartType type) {
  if (const TypeChecker.fromRuntime(String).isAssignableFromType(type))
    return ColumnType.VAR_CHAR;
  if (const TypeChecker.fromRuntime(int).isAssignableFromType(type))
    return ColumnType.INT;
  if (const TypeChecker.fromRuntime(double).isAssignableFromType(type))
    return ColumnType.DECIMAL;
  if (const TypeChecker.fromRuntime(num).isAssignableFromType(type))
    return ColumnType.NUMERIC;
  if (const TypeChecker.fromRuntime(bool).isAssignableFromType(type))
    return ColumnType.BOOLEAN;
  if (const TypeChecker.fromRuntime(DateTime).isAssignableFromType(type))
    return ColumnType.TIME_STAMP;
  return null;
}

Column reviveColumn(ConstantReader cr) {
  // TODO: Get index type, column type...
  var args = cr.revive().namedArguments;
  IndexType indexType = IndexType.NONE;
  ColumnType columnType;

  if (args.containsKey('index')) {
    indexType = IndexType.values[args['index'].getField('index').toIntValue()];
  }

  if (args.containsKey('type')) {
    columnType = new _ColumnType(args['type'].getField('name').toStringValue());
  }

  return new Column(
    nullable: cr.peek('nullable')?.boolValue,
    length: cr.peek('length')?.intValue,
    defaultValue: cr.peek('defaultValue')?.literalValue,
    type: columnType,
    index: indexType,
  );
}

ORM reviveOrm(ConstantReader cr) {
  return new ORM(cr.peek('tableName')?.stringValue);
}

Relationship reviveRelationship(DartObject relationshipAnnotation) {
  var cr = new ConstantReader(relationshipAnnotation);
  var r = cr.revive().namedArguments;
  int type = -1;

  if (cr.instanceOf(hasOneTypeChecker))
    type = RelationshipType.HAS_ONE;
  else if (cr.instanceOf(hasManyTypeChecker))
    type = RelationshipType.HAS_MANY;
  else if (cr.instanceOf(belongsToTypeChecker))
    type = RelationshipType.BELONGS_TO;
  else if (cr.instanceOf(belongsToManyTypeChecker))
    type = RelationshipType.BELONGS_TO_MANY;
  else
    throw new UnsupportedError(
        'Unsupported relationship type "${relationshipAnnotation.type.name}".');

  return new Relationship(type,
      localKey: r['localKey']?.toStringValue(),
      foreignKey: r['foreignKey']?.toStringValue(),
      foreignTable: r['foreignTable']?.toStringValue(),
      cascadeOnDelete: r['cascadeOnDelete']?.toBoolValue());
}

Future<PostgresBuildContext> buildContext(
    ClassElement clazz,
    ORM annotation,
    BuildStep buildStep,
    Resolver resolver,
    bool autoSnakeCaseNames,
    bool autoIdAndDateFields) async {
  var raw = await serialize.buildContext(clazz, null, buildStep, resolver,
      autoSnakeCaseNames != false, autoIdAndDateFields != false);
  var ctx = await PostgresBuildContext.create(
      clazz, raw, annotation, resolver, buildStep,
      tableName: (annotation.tableName?.isNotEmpty == true)
          ? annotation.tableName
          : pluralize(new ReCase(clazz.name).snakeCase),
      autoSnakeCaseNames: autoSnakeCaseNames != false,
      autoIdAndDateFields: autoIdAndDateFields != false);
  List<String> fieldNames = [];
  List<FieldElement> fields = [];

  for (var field in raw.fields) {
    fieldNames.add(field.name);

    // Check for joins.
    var canJoins = canJoinTypeChecker.annotationsOf(field);

    for (var ann in canJoins) {
      var cr = new ConstantReader(ann);
      ctx.joins[field.name] ??= [];
      ctx.joins[field.name].add(new JoinContext(
        resolveModelAncestor(cr.read('type').typeValue),
        cr.read('foreignKey').stringValue,
      ));
    }

    // Check for relationship. If so, skip.
    var relationshipAnnotation =
        relationshipTypeChecker.firstAnnotationOf(field);

    if (relationshipAnnotation != null) {
      ctx.relationshipFields.add(field);
      ctx.relationships[field.name] =
          reviveRelationship(relationshipAnnotation);
      continue;
    }

    // Check for column annotation...
    Column column;
    var columnAnnotation = columnTypeChecker.firstAnnotationOf(field);

    if (columnAnnotation != null) {
      column = reviveColumn(new ConstantReader(columnAnnotation));
    }

    if (column == null && field.name == 'id' && ctx.shimmed['id'] == true) {
      column = const Column(type: ColumnType.SERIAL);
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
        nullable: column.nullable,
        length: column.length,
        index: column.index,
        defaultValue: column.defaultValue,
        type: inferColumnType(field.type),
      );
    }

    if (column?.type == null)
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
      ctx.fields.removeWhere((f) => f.name == rc.camelCase);
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

class _ColumnType implements ColumnType {
  @override
  final String name;

  _ColumnType(this.name);
}
