import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:angel_orm/angel_orm.dart';
import 'package:source_gen/source_gen.dart';
import 'orm_build_context.dart';

const TypeChecker columnTypeChecker = TypeChecker.fromRuntime(Column);

Orm reviveORMAnnotation(ConstantReader reader) {
  return Orm(
      tableName: reader.peek('tableName')?.stringValue,
      generateMigrations: reader.peek('generateMigrations')?.boolValue ?? true);
}

class ColumnReader {
  final ConstantReader reader;

  ColumnReader(this.reader);

  bool get isNullable => reader.peek('isNullable')?.boolValue ?? true;

  int get length => reader.peek('length')?.intValue;

  DartObject get defaultValue => reader.peek('defaultValue')?.objectValue;
}

class RelationshipReader {
  final int type;
  final String localKey;
  final String foreignKey;
  final String foreignTable;
  final bool cascadeOnDelete;
  final DartType through;
  final OrmBuildContext foreign;
  final OrmBuildContext throughContext;
  final JoinType joinType;

  const RelationshipReader(this.type,
      {this.localKey,
      this.foreignKey,
      this.foreignTable,
      this.cascadeOnDelete,
      this.through,
      this.foreign,
      this.throughContext,
      this.joinType});

  bool get isManyToMany =>
      type == RelationshipType.hasMany && throughContext != null;

  String get joinTypeString {
    switch (joinType ?? JoinType.left) {
      case JoinType.inner:
        return 'join';
      case JoinType.left:
        return 'leftJoin';
      case JoinType.right:
        return 'rightJoin';
      case JoinType.full:
        return 'fullOuterJoin';
      case JoinType.self:
        return 'selfJoin';
      default:
        return 'join';
    }
  }

  FieldElement findLocalField(OrmBuildContext ctx) {
    return ctx.effectiveFields.firstWhere(
        (f) => ctx.buildContext.resolveFieldName(f.name) == localKey,
        orElse: () {
      throw '${ctx.buildContext.clazz.name} has no field that maps to the name "$localKey", '
          'but it has a @HasMany() relation that expects such a field.';
    });
  }

  FieldElement findForeignField(OrmBuildContext ctx) {
    var foreign = throughContext ?? this.foreign;
    return foreign.effectiveFields.firstWhere(
        (f) => foreign.buildContext.resolveFieldName(f.name) == foreignKey,
        orElse: () {
      throw '${foreign.buildContext.clazz.name} has no field that maps to the name "$foreignKey", '
          'but ${ctx.buildContext.clazz.name} has a @HasMany() relation that expects such a field.';
    });
  }
}
