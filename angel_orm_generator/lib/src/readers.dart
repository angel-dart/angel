import 'package:analyzer/dart/constant/value.dart';
import 'package:angel_orm/angel_orm.dart';
import 'package:source_gen/source_gen.dart';

const TypeChecker columnTypeChecker = const TypeChecker.fromRuntime(Column);

Orm reviveORMAnnotation(ConstantReader reader) {
  return Orm(reader.peek('tableName')?.stringValue);
}

class ColumnReader {
  final ConstantReader reader;

  ColumnReader(this.reader);

  bool get isNullable => reader.peek('isNullable')?.boolValue ?? true;

  int get length => reader.peek('length')?.intValue;

  DartObject get defaultValue => reader.peek('defaultValue')?.objectValue;
}
