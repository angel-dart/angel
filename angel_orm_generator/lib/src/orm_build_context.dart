import 'dart:async';

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:angel_orm/angel_orm.dart';
import 'package:angel_serialize/angel_serialize.dart';
import 'package:angel_serialize_generator/angel_serialize_generator.dart';
import 'package:angel_serialize_generator/build_context.dart';
import 'package:angel_serialize_generator/context.dart';
import 'package:build/build.dart';
import 'package:inflection/inflection.dart';
import 'package:recase/recase.dart';
import 'package:source_gen/source_gen.dart';

import 'readers.dart';

bool isHasRelation(Relationship r) =>
    r.type == RelationshipType.hasOne || r.type == RelationshipType.hasMany;

bool isBelongsRelation(Relationship r) =>
    r.type == RelationshipType.belongsTo ||
    r.type == RelationshipType.belongsToMany;

final Map<Uri, OrmBuildContext> _cache = {};

Future<OrmBuildContext> buildOrmContext(
    ClassElement clazz,
    ConstantReader annotation,
    BuildStep buildStep,
    Resolver resolver,
    bool autoSnakeCaseNames,
    bool autoIdAndDateFields,
    {bool heedExclude: true}) async {
  // Check for @generatedSerializable
  // ignore: unused_local_variable
  DartObject generatedSerializable;

  while ((generatedSerializable =
          const TypeChecker.fromRuntime(GeneratedSerializable)
              .firstAnnotationOf(clazz)) !=
      null) {
    clazz = clazz.supertype.element;
  }

  var uri = clazz.source.uri;
  if (_cache.containsKey(uri)) {
    return _cache[uri];
  }
  var buildCtx = await buildContext(clazz, annotation, buildStep, resolver,
      autoSnakeCaseNames, autoIdAndDateFields,
      heedExclude: heedExclude);
  var ormAnnotation = reviveORMAnnotation(annotation);
  var ctx = new OrmBuildContext(
      buildCtx,
      ormAnnotation,
      (ormAnnotation.tableName?.isNotEmpty == true)
          ? ormAnnotation.tableName
          : pluralize(new ReCase(clazz.name).snakeCase));
  _cache[uri] = ctx;

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

    // Try to find a relationship
    var ann = relationshipTypeChecker.firstAnnotationOf(field);

    if (ann != null) {
      var cr = new ConstantReader(ann);
      var rc = ctx.buildContext.modelClassNameRecase;
      var type = cr.read('type').intValue;
      var localKey = cr.peek('localKey')?.stringValue;
      var foreignKey = cr.peek('foreignKey')?.stringValue;
      var foreignTable = cr.peek('foreignTable')?.stringValue;
      var cascadeOnDelete = cr.peek('cascadeOnDelete')?.boolValue == true;
      OrmBuildContext foreign;

      if (foreignTable == null) {
        if (!isModelClass(field.type)) {
          throw new UnsupportedError(
              'Cannot apply relationship to field "${field.name}" - ${field.type.name} is not assignable to Model.');
        } else {
          try {
            foreign = await buildOrmContext(
                field.type.element as ClassElement,
                new ConstantReader(const TypeChecker.fromRuntime(Serializable)
                    .firstAnnotationOf(field.type.element)),
                buildStep,
                resolver,
                autoSnakeCaseNames,
                autoIdAndDateFields);
            var ormAnn = const TypeChecker.fromRuntime(Orm)
                .firstAnnotationOf(field.type.element);

            if (ormAnn != null) {
              foreignTable =
                  new ConstantReader(ormAnn).peek('tableName')?.stringValue;
            }

            foreignTable ??=
                pluralize(foreign.buildContext.modelClassNameRecase.snakeCase);
          } on StackOverflowError {
            throw new UnsupportedError(
                'There is an infinite cycle between ${clazz.name} and ${field.type.name}. This triggered a stack overflow.');
          }
        }
      }

      // Fill in missing keys
      var rcc = new ReCase(field.name);
      if (type == RelationshipType.hasOne || type == RelationshipType.hasMany) {
        localKey ??= 'id';
        foreignKey ??= '${rc.snakeCase}_id';
      } else if (type == RelationshipType.belongsTo ||
          type == RelationshipType.belongsToMany) {
        localKey ??= '${rcc.snakeCase}_id';
        foreignKey ??= 'id';
      }

      var relation = new Relationship(
        type,
        localKey: localKey,
        foreignKey: foreignKey,
        foreignTable: foreignTable,
        cascadeOnDelete: cascadeOnDelete,
      );

      if (isBelongsRelation(relation)) {
        var name = new ReCase(relation.localKey).camelCase;
        ctx.buildContext.aliases[name] = relation.localKey;
        ctx.effectiveFields.add(new RelationFieldImpl(
            name, field.type.element.context.typeProvider.intType, field.name));
      }

      ctx.relations[field.name] = relation;
      ctx.relationTypes[relation] = foreign;
    } else {
      if (column?.type == null)
        throw 'Cannot infer SQL column type for field "${field.name}" with type "${field.type.name}".';
      ctx.columns[field.name] = column;
      ctx.effectiveFields.add(field);
    }
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

const TypeChecker relationshipTypeChecker =
    const TypeChecker.fromRuntime(Relationship);

class OrmBuildContext {
  final BuildContext buildContext;
  final Orm ormAnnotation;
  final String tableName;

  final Map<String, Column> columns = {};
  final List<FieldElement> effectiveFields = [];
  final Map<String, Relationship> relations = {};
  final Map<Relationship, OrmBuildContext> relationTypes = {};

  OrmBuildContext(this.buildContext, this.ormAnnotation, this.tableName);
}

class _ColumnType implements ColumnType {
  @override
  final String name;

  _ColumnType(this.name);
}

class RelationFieldImpl extends ShimFieldImpl {
  final String originalFieldName;
  RelationFieldImpl(String name, DartType type, this.originalFieldName)
      : super(name, type);
}
