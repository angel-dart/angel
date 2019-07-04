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
import 'package:inflection2/inflection2.dart';
import 'package:recase/recase.dart';
import 'package:source_gen/source_gen.dart';

import 'readers.dart';

bool isHasRelation(Relationship r) =>
    r.type == RelationshipType.hasOne || r.type == RelationshipType.hasMany;

bool isSpecialId(OrmBuildContext ctx, FieldElement field) {
  return
      // field is ShimFieldImpl &&
      field is! RelationFieldImpl &&
          (field.name == 'id' &&
              const TypeChecker.fromRuntime(Model)
                  .isAssignableFromType(ctx.buildContext.clazz.type));
}

Element _findElement(FieldElement field) {
  return (field.setter == null ? field.getter : field) ?? field;
}

FieldElement findPrimaryFieldInList(
    OrmBuildContext ctx, Iterable<FieldElement> fields) {
  for (var field_ in fields) {
    var field = field_ is RelationFieldImpl ? field_.originalField : field_;
    var element = _findElement(field);
    // print(
    //     'Searching in ${ctx.buildContext.originalClassName}=>${field?.name} (${field.runtimeType})');
    // Check for column annotation...
    var columnAnnotation = columnTypeChecker.firstAnnotationOf(element);

    if (columnAnnotation != null) {
      var column = reviveColumn(new ConstantReader(columnAnnotation));
      // print(
      //     '  * Found column on ${field.name} with indexType = ${column.indexType}');
      // print(element.metadata);
      if (column.indexType == IndexType.primaryKey) return field;
    }
  }

  var specialId =
      fields.firstWhere((f) => isSpecialId(ctx, f), orElse: () => null);
  // print(
  //     'Special ID on ${ctx.buildContext.originalClassName} => ${specialId?.name}');
  return specialId;
}

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
  // print(
  //     'tableName (${annotation.objectValue.type.name}) => ${ormAnnotation.tableName} from ${clazz.name} (${annotation.revive().namedArguments})');
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
    var element = _findElement(field);
    var columnAnnotation = columnTypeChecker.firstAnnotationOf(element);
    // print('${element.name} => $columnAnnotation');

    if (columnAnnotation != null) {
      column = reviveColumn(new ConstantReader(columnAnnotation));
    }

    if (column == null && isSpecialId(ctx, field)) {
      // This is only for PostgreSQL, so implementations without a `serial` type
      // must handle it accordingly, of course.
      column = const Column(
          type: ColumnType.serial, indexType: IndexType.primaryKey);
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
    var el = _findElement(field);
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
      var through = cr.peek('through')?.typeValue;
      OrmBuildContext foreign, throughContext;

      if (foreignTable == null) {
        // if (!isModelClass(field.type) &&
        //     !(field.type is InterfaceType &&
        //         isListOfModelType(field.type as InterfaceType))) {
        var canUse = (field.type is InterfaceType &&
                isListOfModelType(field.type as InterfaceType)) ||
            isModelClass(field.type);
        if (!canUse) {
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
                new ConstantReader(const TypeChecker.fromRuntime(Orm)
                    .firstAnnotationOf(modelType.element)),
                buildStep,
                resolver,
                autoSnakeCaseNames);

            // Resolve throughType as well
            if (through != null && through is InterfaceType) {
              throughContext = await buildOrmContext(
                  through.element,
                  new ConstantReader(const TypeChecker.fromRuntime(Serializable)
                      .firstAnnotationOf(modelType.element)),
                  buildStep,
                  resolver,
                  autoSnakeCaseNames);
            }

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

      String keyName(OrmBuildContext ctx, String missing) {
        var _keyName =
            findPrimaryFieldInList(ctx, ctx.buildContext.fields)?.name;
        // print(
        //     'Keyname for ${buildCtx.originalClassName}.${field.name} maybe = $_keyName??');
        if (_keyName == null) {
          throw '${ctx.buildContext.originalClassName} has no defined primary key, '
              'so the relation on field ${buildCtx.originalClassName}.${field.name} must define a $missing.';
        } else {
          return _keyName;
        }
      }

      if (type == RelationshipType.hasOne || type == RelationshipType.hasMany) {
        localKey ??=
            ctx.buildContext.resolveFieldName(keyName(ctx, 'local key'));
        // print(
        //     'Local key on ${buildCtx.originalClassName}.${field.name} defaulted to $localKey');
        foreignKey ??= '${rc.snakeCase}_$localKey';
      } else if (type == RelationshipType.belongsTo) {
        foreignKey ??=
            ctx.buildContext.resolveFieldName(keyName(foreign, 'foreign key'));
        localKey ??= '${rcc.snakeCase}_$foreignKey';
      }

      var relation = new RelationshipReader(
        type,
        localKey: localKey,
        foreignKey: foreignKey,
        foreignTable: foreignTable,
        cascadeOnDelete: cascadeOnDelete,
        through: through,
        foreign: foreign,
        throughContext: throughContext,
      );

      // print('Relation on ${buildCtx.originalClassName}.${field.name} => '
      //     'foreignKey=$foreignKey, localKey=$localKey');

      if (relation.type == RelationshipType.belongsTo) {
        var name = new ReCase(relation.localKey).camelCase;
        ctx.buildContext.aliases[name] = relation.localKey;

        if (!ctx.effectiveFields.any((f) => f.name == field.name)) {
          var foreignField = relation.findForeignField(ctx);
          var foreign = relation.throughContext ?? relation.foreign;
          var type = foreignField.type;
          if (isSpecialId(foreign, foreignField))
            type = field.type.element.context.typeProvider.intType;
          var rf = new RelationFieldImpl(name, relation, type, field);
          ctx.effectiveFields.add(rf);
        }
      }

      ctx.relations[field.name] = relation;
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
  if (const TypeChecker.fromRuntime(List).isAssignableFromType(type))
    return ColumnType.jsonb;
  if (type is InterfaceType && type.element.isEnum) return ColumnType.int;
  return null;
}

Column reviveColumn(ConstantReader cr) {
  ColumnType columnType;

  var indexTypeObj = cr.peek('indexType')?.objectValue;
  indexTypeObj ??= cr.revive().namedArguments['indexType'];

  var columnObj =
      cr.peek('type')?.objectValue?.getField('name')?.toStringValue();
  var indexType = IndexType.values[
      indexTypeObj?.getField('index')?.toIntValue() ?? IndexType.none.index];

  if (const TypeChecker.fromRuntime(PrimaryKey)
      .isAssignableFromType(cr.objectValue.type)) {
    indexType = IndexType.primaryKey;
  }

  if (columnObj != null) {
    columnType = new _ColumnType(columnObj);
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
  final Map<String, RelationshipReader> relations = {};

  OrmBuildContext(this.buildContext, this.ormAnnotation, this.tableName);
}

class _ColumnType implements ColumnType {
  @override
  final String name;

  _ColumnType(this.name);
}

class RelationFieldImpl extends ShimFieldImpl {
  final FieldElement originalField;
  final RelationshipReader relationship;
  RelationFieldImpl(
      String name, this.relationship, DartType type, this.originalField)
      : super(name, type);

  String get originalFieldName => originalField.name;

  PropertyAccessorElement get getter => originalField.getter;
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
