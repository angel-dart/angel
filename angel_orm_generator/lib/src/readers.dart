import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:angel_orm/angel_orm.dart';
import 'package:source_gen/source_gen.dart';
import 'orm_build_context.dart';

const TypeChecker columnTypeChecker = const TypeChecker.fromRuntime(Column);

Orm reviveORMAnnotation(ConstantReader reader) {
  return Orm(tableName: reader.peek('tableName')?.stringValue);
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

  const RelationshipReader(this.type,
      {this.localKey,
      this.foreignKey,
      this.foreignTable,
      this.cascadeOnDelete,
      this.through,
      this.foreign,
      this.throughContext});

  bool get isManyToMany =>
      type == RelationshipType.hasMany && throughContext != null;
}
