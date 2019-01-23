import 'dart:async';

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:angel_model/angel_model.dart';
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

final Map<String, OrmBuildContext> _cache = {};

Future<OrmBuildContext> buildOrmContext(
    ClassElement clazz,
    ConstantReader annotation,
    BuildStep buildStep,
    Resolver resolver,
    bool autoSnakeCaseNames,
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

  var id = clazz.location.components.join('-');
  if (_cache.containsKey(id)) {
    return _cache[id];
  }
  var buildCtx = await buildContext(
      clazz, annotation, buildStep, resolver, autoSnakeCaseNames,
      heedExclude: heedExclude);
  var ormAnnotation = reviveORMAnnotation(annotation);
  var ctx = new OrmBuildContext(
      buildCtx,
      ormAnnotation,
      (ormAnnotation.tableName?.isNotEmpty == true)
          ? ormAnnotation.tableName
          : pluralize(new ReCase(clazz.name).snakeCase));
  _cache[id] = ctx;

  // Read all fields
  for (var field in buildCtx.fields) {
    // Check for column annotation...
    Column column;
    var columnAnnotation = columnTypeChecker.firstAnnotationOf(field);

    if (columnAnnotation != null) {
      column = reviveColumn(new ConstantReader(columnAnnotation));
    }

    if (column == null &&
        field.name == 'id' &&
        const TypeChecker.fromRuntime(Model)
            .isAssignableFromType(buildCtx.clazz.type)) {
      // This is only for PostgreSQL, so implementations without a `serial` type
      // must handle it accordingly, of course.
      column = const Column(type: ColumnType.serial);
    }

    if (column == null) {
      // Guess what kind of column this is...
      column = new Column(
        type: inferColumnType(
          buildCtx.resolveSerializedFieldType(field.name),
        ),
      );
    }

    if (column != null && column.type == null) {
      column = new Column(
        isNullable: column.isNullable,
        length: column.length,
        indexType: column.indexType,
        type: inferColumnType(field.type),
      );
    }

    // Try to find a relationship
    var el = field.setter == null ? field.getter : field;
    el ??= field;
    var ann = relationshipTypeChecker.firstAnnotationOf(el);

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
        // if (!isModelClass(field.type) &&
        //     !(field.type is InterfaceType &&
        //         isListOfModelType(field.type as InterfaceType))) {
        if (!(field.type is InterfaceType &&
                isListOfModelType(field.type as InterfaceType)) &&
            !isModelClass(field.type)) {
          throw new UnsupportedError(
              'Cannot apply relationship to field "${field.name}" - ${field.type} is not assignable to Model.');
        } else {
          try {
            var refType = field.type;

            if (refType is InterfaceType &&
                const TypeChecker.fromRuntime(List)
                    .isAssignableFromType(refType) &&
                refType.typeArguments.length == 1) {
              refType = (refType as InterfaceType).typeArguments[0];
            }

            var modelType = firstModelAncestor(refType) ?? refType;

            foreign = await buildOrmContext(
                modelType.element as ClassElement,
                new ConstantReader(const TypeChecker.fromRuntime(Serializable)
                    .firstAnnotationOf(modelType.element)),
                buildStep,
                resolver,
                autoSnakeCaseNames);

            var ormAnn = const TypeChecker.fromRuntime(Orm)
                .firstAnnotationOf(modelType.element);

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
      } else if (type == RelationshipType.belongsTo) {
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

      if (relation.type == RelationshipType.belongsTo) {
        var name = new ReCase(relation.localKey).camelCase;
        ctx.buildContext.aliases[name] = relation.localKey;

        if (!ctx.effectiveFields.any((f) => f.name == field.name)) {
          if (field.name != 'id' ||
              !const TypeChecker.fromRuntime(Model)
                  .isAssignableFromType(ctx.buildContext.clazz.type)) {
            var rf = new RelationFieldImpl(name,
                field.type.element.context.typeProvider.intType, field.name);
            ctx.effectiveFields.add(rf);
          }
        }
      }

      ctx.relations[field.name] = relation;
      ctx.relationTypes[relation] = foreign;
    } else {
      if (column?.type == null)
        throw 'Cannot infer SQL column type for field "${ctx.buildContext.originalClassName}.${field.name}" with type "${field.type.displayName}".';
      ctx.columns[field.name] = column;

      if (!ctx.effectiveFields.any((f) => f.name == field.name))
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
  if (const TypeChecker.fromRuntime(Map).isAssignableFromType(type))
    return ColumnType.jsonb;
  if (type is InterfaceType && type.element.isEnum) return ColumnType.int;
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

InterfaceType firstModelAncestor(DartType type) {
  if (type is InterfaceType) {
    if (type.superclass != null &&
        const TypeChecker.fromRuntime(Model).isExactlyType(type.superclass)) {
      return type;
    } else {
      return type.superclass == null
          ? null
          : firstModelAncestor(type.superclass);
    }
  } else {
    return null;
  }
}
